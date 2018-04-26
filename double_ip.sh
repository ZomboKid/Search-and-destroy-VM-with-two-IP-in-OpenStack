#!/bin/bash
#-----function check_ip returns: 1 if only first ip response; 2 if only second ip response; 3 if both ip response; 4 if both ip not response--
check_ip () {
    local result=0
    local first_ip
    local second_ip
    local command_shell_first_ip
    local command_shell_second_ip
    local err_first_ip
    local err_second_ip

    first_ip=$(awk -F", " '{print $1}' <<< $1)
    second_ip=$(awk -F", " '{print $2}' <<< $1)

    command_shell_first_ip="ping -c 1 $first_ip 2>&1 >/dev/null"
    command_shell_second_ip="ping -c 1 $second_ip 2>&1 >/dev/null"
#---------------------------------------------------

#----ping returns 0 it means host reachable; 1 it means unreachable---------------

    eval "$command_shell_first_ip"
    err_first_ip=$?
    eval "$command_shell_second_ip"
    err_second_ip=$?

#---------------------------------------------------

    if [[ $err_first_ip == 0 && $err_second_ip == 0 ]]; then return $((3))
    elif [[ $err_first_ip == 0 && $err_second_ip == 1 ]]; then return $((1))
    elif [[ $err_first_ip == 1 && $err_second_ip == 0 ]]; then return $((2))
    elif [[ $err_first_ip == 1 && $err_second_ip == 1 ]]; then return $((4))
    fi
}
#----------------------------------------------------------

get_neutron_id () {
    neutron_command="neutron port-list --fixed-ips ip_address=$1"
    neutron_result=($(eval "$neutron_command"))
    neutron_id=($(echo "${neutron_result[*]}" | grep "ip_address" | awk -F "| " '{print $2}'))
    eval "$2=$neutron_id"
}
#----------------------------------------------------------

key=0

PROJECTS=""
VLAN=""
while getopts "dp:v:" opt;
      do
      case "$opt"
      in
      p) PROJECTS=$OPTARG;;
      v) VLAN=$OPTARG;;
      d) key=1;;
      esac
done


IFS=$'\n'

if [[ $PROJECTS != "" && $VLAN == "" ]]; then
    if [[ $PROJECTS == "all" ]]; then raw_array_command="openstack server list --all-projects"
       else raw_array_command="openstack server list --project $PROJECTS"
    fi
    elif [[ $PROJECTS != "" && $VLAN != "" ]]; then
        echo "project OR vlan !!!"
        exit 1
    elif [[ $PROJECTS == "" && $VLAN != "" ]]; then raw_array_command="openstack server list --all-projects | grep vlan$VLAN"
fi

raw_array=($(eval "$raw_array_command"))

array_ip=($(echo "${raw_array[*]}" | awk -F "|" '{print $5}' | grep ", 1" | awk -F "=" '{print $2}'))
array_hosts=($(echo "${raw_array[*]}" | awk -F "|" '{print $3,$5}' | grep ", 1" | awk '{print $1}'))

for (( j = 0 ; j < ${#array_ip[@]} ; j=$j+1 ));
do
        host_element=${array_hosts[${j}]}
        ip_element=${array_ip[${j}]}
        echo "$host_element $ip_element" >> ./2ip_all_doubles.txt
        
done

size_of_array_hosts=${#array_hosts[@]}
size_of_array_ip=${#array_ip[@]}

rr=0
ip_element=""
host_element=""
for (( j = 0 ; j < ${#array_ip[@]} ; j=$j+1 ));
do
    host_element=${array_hosts[${j}]}

    ip_element=${array_ip[${j}]}

    check_ip $ip_element
    rr=$?

    if [[ $rr == "1" ]]; then
        ip_addr=$(awk -F", " '{print $2}' <<< $ip_element)
        get_neutron_id $ip_addr neutron_id

        if [[ $key == 1 ]]; then
            neutron port-delete $neutron_id

            echo "deleting $ip_addr from $neutron_id" >> ./double_ip.log
        fi    


    elif [[ $rr == "2" ]]; then    
        ip_addr=$(awk -F", " '{print $1}' <<< $ip_element)
        get_neutron_id $ip_addr neutron_id

        if [[ $key == 1 ]]; then
            neutron port-delete $neutron_id

            echo "deleting $ip_addr from $neutron_id" >> ./double_ip.log
        fi


    elif [[ $rr == "3" ]]; then
       echo "$host_element $ip_element" >> ./2ip_both_response.txt
    elif [[ $rr == "4" ]]; then
       echo "$host_element $ip_element" >> ./2ip_both_NOT_response.txt
    fi
  
done

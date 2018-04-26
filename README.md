# Search-and-destroy-VM-with-two-IP-in-OpenStack
Search ans delete VM in OpenStack who have two IP<br/>

CLI options is:<br/>
-d - delete VM who have two IP<br/>
-p \<project name\> - search only in selected OpenStack project<br/>
-v \<vlan\> - search only in selected OpenStack VLAN<br/>

Script writes log:<br/>
./double_ip.log - if CLI options is "-d" then write deleted IP to this log<br/>
./2ip_all_doubles.txt - writes all double IP<br/>
./2ip_both_response.txt - writes if two IP responds to ping<br/>
./2ip_both_NOT_response.txt - writes if two IP not responds to ping<br/>

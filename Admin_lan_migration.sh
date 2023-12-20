#!/bin/bash

#e.g
#OLD_IP="6.97.38.40"
#OLD_GW="6.97.38.33"
#NEW_IP="6.97.142.68"
#NEW_GW="6.97.142.65"
#NEW_SUB="27"

#Details for admin lan migration
OLD_IP="6.97.142.162"
OLD_GW="6.97.46.129"
NEW_IP="6.97.142.162"
NEW_GW="6.97.142.129"
NEW_SUB="25"

#source the config file
#source_config.ini



#check if variables are not empty
for i in "$OLD_IP" "$OLD_GW" "$NEW_IP" "$NEW_GW" "$NEW_SUB"
do
   if [[ -z "$i" ]]; then
      echo "Variable $i is empty ... It can't be empty so exitting"
          exit 1
   fi
done


#Get the NIC card details for old interface.
admin_nic=$(ip addr sh|grep -w $OLD_IP|awk '{print $NF}')
if [[ -z ${admin_nic} ]]; then
    echo "${admin_nic} is empty ..kindly do the changes manually"
        exit 1
else
   echo "NIC Card which have the admin LAN IP is ${admin_nic}...Proceeding ahead"
fi


#Check the OS and set the network path
if [[ -f /etc/os-release ]]; then
    if [[ $(grep -i suse /etc/os-release) ]]; then
            network_path="/etc/sysconfig/network/"
                echo "OS detected is SUSE so setting the network path as: $network_path"
        elif [[ $(grep -i oracle /etc/os-release) ]]; then
            network_path="/etc/sysconfig/network-scripts/"
                echo "OS detected is oracle  so setting the network path as: $network_path"
        elif [[ $(grep -i redhat /etc/os-release) ]]; then
            network_path="/etc/sysconfig/network-scripts/"
                echo "OS detected is redhat  so setting the network path as: $network_path"
        elif [[ $(grep -i ubuntu /etc/os-release) ]]; then
            network_path="/etc/network/"
                echo "OS detected is Ubuntu so setting the network path as: $network_path"

    fi
elif [[ -f /etc/redhat-release ]]; then
      network_path="/etc/sysconfig/network-scripts/"
          echo "OS detected is Redhat so setting the network path as: $network_path"
fi

#Variable for network path
config_file=${network_path}ifcfg-${admin_nic}

#To add the gateway at end of network file
gateway_add () {
cd $network_path
if [[ $(grep -i gateway $config_file) ]]; then
echo "Gateway field is present and is updated with new gateway"
else
echo "Adding the gateway:$NEW_GW to $config_file"
echo "GATEWAY="$NEW_GW"" >> $config_file
fi
}

#Checking the old IP in /etc/hosts file
old_ip_check_hostfile () {
if [[ $(grep -i $OLD_IP /etc/hosts) ]]; then
echo "$OLD_IP is present in /etc/hosts file replacing it with  $NEW_IP"
sed -i 's/'$OLD_IP'/'$NEW_IP'/g' /etc/hosts
else
echo "Old IP:$OLD_IP doesnt exists in /etc/hosts file"
fi
}

#Performing post checks
post_checks () {
cd $network_path
echo "Performing Post checks...."
if [[ $(grep -Ril $OLD_IP *) ]]; then
echo "Old IP:$OLD_IP still exists in below configuration file, Please check again manually  :"
grep -Ril $OLD_IP *
else
echo "OLD_IP:$OLD_IP is been successfully changed to New IP:$NEW_IP"
fi
if [[ $(grep -Ril $OLD_GW *) ]]; then
echo "Old GW:$OLD_GW still exists in below configuration file, Please check again manually :"
grep -Ril $OLD_GW *
else
echo "OLD GW:$OLD_GW is been successfully changed to New GW:$NEW_GW"
fi
}


#Backing up the existing files
cd $network_path
mkdir -p /tmp/CHGXX/IP/
for i in $(grep -Ril $OLD_IP $network_path)
do
  echo "Backing up file:$i to /tmp/CHGXX/IP/"
  cp -p $i /tmp/CHGXX/IP/
done
mkdir -p /tmp/CHGXX/routes
for i in $(grep -Ril $OLD_GW $network_path)
do
  echo "Backing up file:$i to /tmp/CHGXX/routes/"
  cp -p $i /tmp/CHGXX/routes/
done


#Code block to make the changes for IP and GW depending on OS
if [[ $network_path == "/etc/sysconfig/network/" ]]; then
old_mask="$(grep -i $OLD_IP  $config_file|cut -d / -f2|cut -d \' -f1)"
#Change the IP
echo "Changing the Old IP:$OLD_IP to New IP:$NEW_IP in file $config_file"
sed -i 's/'$OLD_IP'/'$NEW_IP'/g' $config_file
#change the subnet mask
echo "Changing the Old netmask:$old_mask to New netmask:$NEW_SUB in file $config_file"
sed -i 's/\/'$old_mask'/\/'$NEW_SUB'/g' $config_file
#change the gw
for i in $(grep -Ril $OLD_GW $network_path)
do
   echo "Changing the Old Gateway:$OLD_GW to New Gateway:$NEW_GW in file $i"
   sed -i 's/'$OLD_GW'/'$NEW_GW'/g' $i
done
gateway_add

elif [[ $network_path == "/etc/sysconfig/network-scripts/" ]]; then
#Redhat OS
if [[ $(grep -i red /etc/redhat-release) ]];then
#Remove the existing netmask field
if [[ $(grep -i netmask $config_file) ]]; then
sed -i '/NETMASK/d' $config_file
fi

#Remove the existing prefix field
if [[ $(grep -i prefix $config_file) ]]; then
    sed -i '/PREFIX/d' $config_file
        echo "Changing the Old prefix to New Prefix:$NEW_SUB"
    echo "PREFIX="$NEW_SUB"" >> $config_file
fi

#Replace the NEWIP with subnet
echo "Changing the Old IP:$OLD_IP to New IP:$NEW_IP in file $config_file"
sed -i 's/'$OLD_IP'/'$NEW_IP'/g' $config_file

#Oracle OS
elif [[ $(grep -i oracle /etc/os-release) ]]; then
echo "Changing the Old IP:$OLD_IP to New IP:$NEW_IP in file $config_file"
sed -i 's/'$OLD_IP'/'$NEW_IP'/g' $config_file
if [[ $(grep -i prefix $config_file) ]]; then
    sed -i '/PREFIX/d' $config_file
    echo "Changing the Old prefix to New Prefix:$NEW_SUB"
    echo "PREFIX="$NEW_SUB"" >> $config_file
fi
fi

#change the gw
for i in $(grep -Ril $OLD_GW $network_path)
do
   echo "Changing the Old Gateway:$OLD_GW to New Gateway:$NEW_GW in file $i"
   sed -i 's/'$OLD_GW'/'$NEW_GW'/g' $i
done

#Adding the Gateway=x.x.x.x in config file
gateway_add

#Ubuntu OS
elif [[ $network_path == "/etc/network/" ]]; then
config_file="$network_path/interfaces"
cp -p $config_file /tmp/
#change the ip
echo "Changing the Old IP:$OLD_IP to New IP:$NEW_IP in file $config_file"
sed -i 's/'$OLD_IP'/'$NEW_IP'/g' $config_file
echo "Changing the Old Gateway:$OLD_GW to New Gateway:$NEW_GW in file $config_file"
sed -i 's/'$OLD_GW'/'$NEW_GW'/g' $config_file
fi

old_ip_check_hostfile
post_checks
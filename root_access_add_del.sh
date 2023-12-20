#!/bin/bash

#These script takes the user input and provide the root rights for user diconium in funke

if [[ $# -ne 1 ]]; then
  echo "Usage ./scriptname.sh add ----- To add the root access for diconium user "
  echo "Usage ./scriptname.sh delete ----- To delete the root access for diconium user"
  exit 1
fi

#Variables
action=$(echo "$1" |tr '[:upper:]' '[:lower:]')
file="/etc/sudoers"
user="diconium"

#Funtions

#Backup the suoders file
backup_sudoers() {
cp -p ${file} ${file}_$(date +%d-%m-%y)
}



 
if [[ ${action} == "add" ]]; then
    grep -w diconium ${file}|grep -i ^# 2>&1 > /dev/null
      if [[ $? -eq 0 ]]; then
         echo "Granting root access to user diconium"
         backup_sudoers
         sed -i '/^diconium\s.*$/s/^#//' "${file}"
         echo "========Output==========="
         grep -w diconium ${file}
         echo "Root access granted to user diconium on $(date)"
      else
         echo "Root access is already granted state for user diconium"
         echo "========Output==========="
         grep -w diconium ${file}
      fi

elif [[ ${action} == "delete"  ]]; then
    grep -w diconium ${file}|grep -i ^# 2>&1 > /dev/null
      if [[ $? -eq 0 ]]; then
         echo "Root access to diconium is already in removed state"
         echo "========Output==========="
         grep -w diconium ${file}
         else
         echo "Removing the root access for user diconium"
         sed -i '/diconium/s/^/#/' "${file}"
         echo "========Output==========="
         grep -w diconium ${file}
         echo "Root access removed for user diconium on $(date)"
      fi

else
         echo "Wrong script parameter provided other than add/delete, Provided value:${action}.....Exiting now"
             exit 1
fi
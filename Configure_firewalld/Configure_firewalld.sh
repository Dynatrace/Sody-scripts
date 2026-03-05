#!/bin/bash

###
# Copyright 2026 Erik Soderquist
# Copyright 2026 Dynatrace LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

###
# THIS SCRIPT IS NOT OFFICIALLY SUPPORTED BY DYNATRACE
# If you have an issue with this script, please open an issue on github for it
###

###
# script to configure firewalld for Dynatrace Managed clusters when
# dynatrace-firewall must be disabled due to customer internal policies
###
# all firewall-cmd commands here are safe to repeat (multiple times if needed
# for future updates), firewall-cmd will simply issue a warning for definitions
# that already exist
###
# current assumptions:
# - all hosts in the cluster have only a single IP address each
###

###
# manually added configuration
# - manual_ip_list is a comma separate list of IP addresses to include in the DT-Managed-Nodes zone
# it is safe to include existing and new nodes in the IP list; the script will deduplicate
# example: export manual_ip_list=172.24.69.72,172.24.69.74,172.24.69.75
export manual_ip_list=

###
# nothing below here should require changes unless specs change, enhancements are created, or a flaw is discovered
###

###
# check if we have appropriate permission
###
if [ $(id -u) -gt 0 ]
  then
    echo this script requires root/sudo to execute properly >&2
    echo aborting >&2
    exit 13
  fi

###
# check if the IP list was actually set
###
if [ -z "${manual_ip_list}" ]
  then
    echo IP address list not configured >&2
    echo aborting >&2
    exit 22
  fi

###
# start with detecting if DT-Managed is already installed, and if so, pull some data
###

if [ -e /etc/dynatrace.conf ]
  then
    export DT_installed=true
  else
    export DT_installed=false
  fi

if [ ${DT_installed} == true ]
  then
    echo existing Dynatrace Managed install detected, importing and merging existing cluster nodes
    export $(grep "PRODUCT_PATH =" /etc/dynatrace.conf | sed 's/ //g')
    export detected_ip_list=($(grep "CLUSTER_NODES=" ${PRODUCT_PATH}/firewall/services/firewall.conf | awk -F = '{print $2}' | sed s'/,/ /g'))
  else
    echo existing Dynatrace Managed installation not detected on this host.
  fi
    
###
# merge the configured list and the detected (if any) list
###
export ip_list=($(echo ${detected_ip_list[@]} ${manual_ip_list} | sed 's/ \|,/\n/g' | sort -u ))

###
# sanity check, make sure the current host's IP address is in the list
###
if [ $(echo ${ip_list[@]} | grep -c $(hostname -I)) -eq 0 ]
  then
    echo "this host's IP address is not in the configured/detected IP address list" >&2
    echo please check the configured IP address list and confirm it is correct >&2
    echo aborting >&2
    exit 22
  fi

###
# dump the results of the merge and prompt for confirmation to continue
###
echo the current list of IP addresses to include as Managed Cluster nodes is:
echo ${ip_list[@]} | sed 's/ /\n/g'
echo "do you want to proceed? <ENTER> to contionue or ^C to abort "
read dummy

###
# create the additional service definitions
###

firewall-cmd --permanent --new-service=DT-Managed-Cluster-Private

firewall-cmd --permanent --service=DT-Managed-Cluster-Private --set-short="DT-Managed-Cluster-Private"

firewall-cmd --permanent --service=DT-Managed-Cluster-Private --set-description="Dynatrace Managed Cluster ports required for Cluster-Only communications"

firewall-cmd --permanent --new-service=DT-Managed-Cluster-Public

firewall-cmd --permanent --service=DT-Managed-Cluster-Public --set-short="DT-Managed-Cluster-Public"

firewall-cmd --permanent --service=DT-Managed-Cluster-Public --set-description="Dynatrace Managed Cluster ports required for public communications"

###
# add the internal ports (some will overlap)
###

for ports in 443 5701-5711 7000-7001 8019-8022 8443 9042 9200 9300 9998
  do
    firewall-cmd --permanent --service=DT-Managed-Cluster-Private --add-port=${ports}/tcp
  done

###
# add the public ports (some will overlap)
###

for ports in 443 8021-8022 8443
  do
    firewall-cmd --permanent --service=DT-Managed-Cluster-Public --add-port=${ports}/tcp
  done

###
# create the new zone for the Managed Cluster nodes
###

firewall-cmd --permanent --new-zone=DT-Managed-Nodes

firewall-cmd --permanent --zone=DT-Managed-Nodes --add-service=DT-Managed-Cluster-Private

###
# add the Managed Cluster node IP addresses to the zone
###

for IP in ${ip_list[@]}
  do
    firewall-cmd --permanent --zone=DT-Managed-Nodes --add-source=${IP}
  done

###
# get all zones and add the public service to them
# firewalld's handling is a little weird here, as it doesn't have a concept of "globally open"
###
for zone in $(firewall-cmd --get-zones)
  do
    firewall-cmd --permanent --zone=${zone} --add-service=DT-Managed-Cluster-Public
    firewall-cmd --permanent --zone=${zone} --add-forward-port=port=443:proto=tcp:toport=8022
  done

###
# apply the changes
###

firewall-cmd --reload


#!/bin/bash
###
# v0.14.1.2026-04-09.13.13.13
###

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
# script to protect Managed Cluster services from OOM harvesting.
# starting with Managed v1.332 this can also be added to /etc/dynatrace.conf to
# be preserved across upgrades.  Adding detection of version and updating to
# preserve across upgrades if the version is high enough, and posting a notice
# if the version is not yet high enough
###

###
# check permissions; requires root/sudo
###
if [ $(id -u) -gt 0 ]
  then
    echo this script require root/sudo to execute properly, aborting
    exit 13
  fi

###
# set vars
###
export updated_something=false
export $(grep ^PRODUCT_PATH /etc/dynatrace.conf | sed s'/ //g')
export $(grep ^PRODUCT_VERSION /etc/dynatrace.conf | sed 's/ //g')
export major=$(echo ${PRODUCT_VERSION} | awk -F . '{print $2}')
if [ ${major} -ge 332 ]
  then
    export preservable=true
  else
    export preservable=false
  fi


###
# check/configure the service definitions
###

for file in /etc/systemd/system/dynatrace-*
  do
    export g_result="$(grep ^OOMScoreAdjust ${file})"
    case ${g_result} in
      "" )
        echo no definition present in ${file}, adding
        sed -i 's/\[Service\]/[Service]\nOOMScoreAdjust=-1000/g' ${file}
        export updated_something=true
        ;;
      "OOMScoreAdjust=-1000" )
        echo correct definition already present in ${file}, skipping
        ;;
      * )
        echo definition present in ${file} but incorrect, fixing
        sed -i 's/OOMScoreAdjust=.*/OOMScoreAdjust=-1000/g' ${file}
        export updated_something=true
        ;;
    esac
  done

###
# if a change was made to the service definitions, apply it
###
if [ ${updated_something} == true ]
  then
    systemctl daemon-reload
  fi

###
# update the running processes
###

for pid in $(ps -ef | grep ${PRODUCT_PATH} | grep -v grep | awk '{print $2}') 
  do
    echo -1000 >/proc/${pid}/oom_score_adj 
  done

###
# if the Managed version is v1.332 or greater, set this to be preserved across
# upgrades; else post notice that preservation across upgrades is not yet
# possible
###

if [ ${preservable} == false ]
  then
    echo This cluster version is not new enough to preserve the setting across upgrade/reconfigure opertions.
    echo After each such operation, this will need to be reapplied.
  fi  

if [ ${preservable} == true ]
  then
    export $(grep ^SYSTEMD_PROP_2 /etc/dynatrace.conf | sed 's/ //g')
    if [ "${SYSTEMD_PROP_2}" == "OOMScoreAdjust=-1000" ]
      then
        echo preserved setting already present on this host
      else
        sed -i 's/SYSTEMD_PROP_2.*/SYSTEMD_PROP_2 = OOMScoreAdjust=-1000/g' /etc/dynatrace.conf
        echo preserved setting added to this host
      fi
  fi
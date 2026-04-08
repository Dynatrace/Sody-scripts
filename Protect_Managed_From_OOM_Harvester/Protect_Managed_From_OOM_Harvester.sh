#!/bin/bash
###
# v0.13.3.2026-04-08.13.13.13
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
# script to protect Managed Cluster services from OOM harvesting
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

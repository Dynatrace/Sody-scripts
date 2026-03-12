#!/bin/bash
###
# v0.5.2026-03-12.21.15
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
# exclude redundant minor version for each major version
###

###
# configure variables here
###
# "token" is the API token, "Service Provider API" is the required scope
###
# "cluster_name" is the name if the cluster from CMC --> Settings --> Public
# endpoints, without the protocol spec or the slashes.  Should be the same name
# in the URL bar when accessing CMC
###
# "ignore_bad_cert" will only be active if set "true"; all other values are considered "false"
# use "ignore_bad_cert" if curl rejects (and should reject) the certificate the cluster is using
###
# "debug" will only be active if set "true"; all other values are considered "false"
# if "debug" is "true", vars are dumped to stdout as they are built, and the
# API call to actually exclude packages is skipped, making no changes
###

export token=REDACTED
export cluster_name=rxg285.dynatrace-managed.com
export ignore_bad_cert=false
export debug=false

###
# nothing below here should require changes unless specs change or a bug is found
###


if [ ! -z "$1" ]
  then
    echo this script does not accept any parameters
    exit 22
  fi

export API_path=api/v1.0/onpremise/upgradeManagement/installationFiles
export h1="accept: application/json; charset=utf-8"
export h2="accept: */*"
export h3="Content-Type: application/json"
export out_file=/var/tmp/${cluster_name}.$(hostname -s).$(basename $0).txt

###
# define the curl command
###
if [ "${ignore_bad_cert}" == "true" ]
  then
    export curl_cmd="$(which curl) -k -s"
  else
    export curl_cmd="$(which curl) -s"
  fi

###
# test for a bad cert for sanity reasons.  if "ignore_bad_cert" is true, all certs will be "good"
###
export c_health="$(${curl_cmd} https://${cluster_name}/rest/health ; echo $?)"
export c_health_cleaned=$(echo ${c_health} | sed s'/"//g')
case "${c_health_cleaned}" in
  RUNNING0)
    #all good, proceed
    ;;
  60)
    echo -e "\n\n" >&2
    echo TLS certificate presented is not trusted, ABORTING INSECURE CONNECTIONS >&2
    echo if you want to accept untrusted certificates, please set ignore_bad_cert to true in the script configuration >&2
    exit 60
    ;;
  *)
    echo -e "\n\n" >&2
    echo unknown error occured, aborting >&2
    exit 22
    ;;
esac


###
# cleanup before running
###
for var in type type_list version version_list
  do
    unset ${var}
  done

###
# get the current list, excluding already excluded build units
###
${curl_cmd} -X "GET" "https://${cluster_name}/${API_path}" -H "${h1}" -H "Authorization: Api-Token ${token}" | sed s'/},{/}\n{/g' | sed 's/"\|:/ /g' | grep -v "EXCLUDED\|REMOVING\|MISSING" >"${out_file}"

###
# find build unit types
###
for type in $(cat "${out_file}" | awk '{print $3}' | sort -u)
  do
    export type_list="${type} ${type_list}"
    if [ "${debug}" == "true" ]
      then
        echo type_list is now ${type_list}
      fi
  done

###
# find the version list
###
for version in $(cat "${out_file}" | awk '{print $6}' | awk -F . '{print $1"\\."$2"\\."}'| sort -u | grep -v "^1\\\.1\\\.$")
  do
    export version_list="${version} ${version_list}"
    if [ "${debug}" == "true" ]
      then
        echo version_list is now ${version_list}
      fi
  done 

for type in ${type_list}
  do
    for version in ${version_list}
      do
        echo processing ${type} ${version//\\/}X
        unset v_count
        unset e_count
        unset e_version
        if [ $(grep " ${type} " "${out_file}" | grep -c "${version}") -gt 1 ]
          then
            export v_count=$(grep " ${type} " "${out_file}" | grep -c "${version}")
            if [ "${debug}" == "true" ]
              then
                echo v_count = ${v_count} based on
                grep " ${type} " "${out_file}" | grep "${version}" | sort -t . -k3 -n -r
              fi
            export e_count=$(($v_count - 1))
            for e_version in $(grep " ${type} " "${out_file}" | grep "${version}" | awk '{print $6}' | sort -t . -k3 -n -r | tail -${e_count})
              do
                echo removing type ${type} version ${e_version}
                if [ ! "${debug}" == "true" ]
                  then
                    ${curl_cmd} -X "DELETE" "https://${cluster_name}/${API_path}/${type}/${e_version}" -H "${h2}" -H "Authorization: Api-Token ${token}"
                  else
                    echo skipping the API call because debug mode is active
                  fi
              done
          fi
      done
  done

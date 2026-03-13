#!/bin/bash
###
# v0.1.2026-03-13.18.24
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
# Script created to connect to the Mission Control API, pull the current list
# of available packages, and minimumally reformat the output to something
# easily grep'able
###

###
# my cluster token
# Reference https://docs.dynatrace.com/docs/shortlink/api-authentication#token-format-components
# "my_token_public" is the "token identifier" in the doc
# "my_token_private" is the "secrect portion" in the doc
###

export my_token_public=
export my_token_private=

###
# get this session's bearer token
###

export bearer_token=$(curl -X POST "https://mcsvc.dynatrace.com/rest/public/v1.0/oauth/api-token" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"clientId\": \"${my_token_public}\", \"clientSecret\": \"${my_token_public}.${my_token_private}\", \"scope\": \"sso20-managed-cluster-offline-bundle\"}" 2>/dev/null | tee /tmp/x | sed -nr s'/.*"token":"([^"]*)".*/\1/p')

###
# get the list pf packages available for download with their download links
###

curl -X GET -s "https://mcsvc.dynatrace.com/rest/public/downloads/offline-bundle/published" -H "accept: application/json" -H "Authorization: Bearer ${bearer_token}" | sed s'/},{/}\n{/g'

###
# add a couple new lines because the curl result ends without a new line (doesn't matter if grep'ing for a specific pattern)
###

echo -e "\n\n"


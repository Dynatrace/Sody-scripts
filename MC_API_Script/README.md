Copyright 2026 Erik Soderquist
Copyright 2026 Dynatrace LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.



THIS SCRIPT IS NOT OFFICIALLY SUPPORTED BY DYNATRACE
If you have an issue with this script, please open an issue on github for it



Script created to connect to the Mission Control API, pull the current list of
available packages, and minimumally reformat the output to something easily
grep'able

Doc reference for the Mission Control API
https://docs.dynatrace.com/managed/shortlink/mission-control-api

This script assumes you have already completed step 1 and have your permanent
token from step 1.  This script starts at step 2.

The bundle types for reference are:
bundle=agent (OneAgent installer)
bundle=deploymentOrchestration 
bundle=dockerAgent (OneAgent image for containerized deployments)
bundle=js (JavaScript module for RUM)
bundle=odin (OpenTelementry components)
bundle=server (Managed Cluster install/upgrade package)
bundle=sg (ActiveGate (older name was "Security Gateway"))
bundle=synthetic (Synthetic module for ActiveGate)

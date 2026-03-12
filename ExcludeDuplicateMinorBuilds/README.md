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



Script created to automatically check for "duplicate" OneAgent/ActiveGate/etc
packages and exclude the dups

"Duplicate" here is defined as lower minor versions of the same major version

For example:
OneAgent 1.325.51 would be a duplicate of 1.325.64 and excluded

***WARNING***

This script does not have a concept of "in use" versions.  It will happily
remove packages you have configured Kubernetes/etc to pull if there is a high
minor version of the package
# blackduck-debuginfo
Utility script to retrieve debug information from a Black Duck instance and save to a file.  This can be useful for troubleshooting or to save the environment configuration such as environment variables for later reference.

Within the Black Duck user interface 'Admin' section there is a 'System Information' section with a wealth of information on the environment variables, memory, database, scan usage etc.  This utility calls these URLs and combines all of the information into a file of your choice.  This could be useful for troubleshooting or even as a record of your settings in case you need to replicate the environment for disaster recovery.

# Pre-requisites
This is a bash script and has dependencies on jq and curl being installed.

# To use

```
./blackduck_debug.sh -u https://myblackduck -a <api_token> -f <output_file.txt>
```
Example:
```
./blackduck_debug.sh -u https://myblackduck -a <api_token> -f debug.txt
```
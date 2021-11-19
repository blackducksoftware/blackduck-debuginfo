#!/bin/bash
#
#
# AUTHOR: David Nicholls - Synopsys Technical Architect
#
# Version 1.0
#
# Fetches the system information (debug) screens from Black Duck to help troubleshoot or document settings for safe keeping.  Has a dependency on curl and jq.
#
# Usage:
# ./blackduck_debug.sh -u https://<blackduck-url> -a <api_token> -f <output_file.txt>
#
#
# Example:
# ./blackduck_debug.sh -u https://myblackduck -a <api_token> -f debug.txt
#

# Globals for input
ACCESS_TOKEN=""
WEB_URL=""
OUTPUT_FILE=""
DEBUG_MODE=false

# The debug groups ui/debug?group=<group> from the UI.  
declare -a DEBUG_GROUPS=("db" "dbschema" "job" "jobhistory" "jobruntime" "jobscheduler" "jobstatistics" "manifest" "metrics" "prop" "redis-cache" "scan" "scanpurgejob" "system" "usage%3A%20project" "usage%3A%20rapid%20scan%20completion" "usage%3A%20scan%20completion")

TOTAL_OUTPUT=""

# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # Access token arg passed as space
        -a|--access-token)
            shift
            ACCESS_TOKEN="$1"
        ;;
        # HUB url arg passed as space
        -u|--hub-url)
            shift
            WEB_URL="$1"
        ;;
        # Output zip file
        -f|--output-file)
            shift
            OUTPUT_FILE="$1"
        ;;
        # Debug mode
        -d|--debug-mode)
            shift
            DEBUG_MODE="$1"
        ;;
        *)
            # Do whatever you want with extra options
            echo "Unknown option '$key'"
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

# Function to validate inputs
function validate_inputs()
{
    # Check all required inputs are provided
    if [[ -z "${ACCESS_TOKEN}"  || -z "${WEB_URL}" || -z "${OUTPUT_FILE}" ]]
    then
        echo "Script inputs missing please use the following format: ./blackduck_debug.sh -u https://myblackduck -a <api_token> -f <output_file.txt>"
        exit 1
    else
        echo "Inputs validated..."
    fi
}

# validate script requirements
function validate_requirements()
{
    # Check if jq and curl are installed
    local jq=$(command -v jq)
    local curl=$(command -v curl)

    if [[ -z "${jq}" || -z "${curl}" ]]
    then
        echo "jq and curl are required for this script"
        echo "aborting..."
        exit 1
    else
        echo "Tool requirements verified"
    fi

    # Check if we can write to the given directory
    local writeDirectory=$(dirname $OUTPUT_FILE)
    if [ -w "$writeDirectory" ]
    then
        echo "Directory $writeDirectory is writeable"
    else
        echo "Warning: Directory $writeDirectory is not writeable !"
        echo "Will proceed..."
    fi
}

# Authenticate
function authenticate()
{
    local response=$(curl -s --insecure -X POST -H "Content-Type:application/json" -H "Authorization: token $ACCESS_TOKEN" "$WEB_URL/api/tokens/authenticate")
    bearer_token=$(echo "${response}" | jq --raw-output '.bearerToken')
    if [ -z ${bearer_token} ]
    then
        echo "Could not authenticate, aborting..."
        exit 1
    else
        echo "Authenticated successfully..."
    fi
}

# Retrieve debug data for group
function get_debug_data_for_group()
{
    local response=$(curl -s --insecure -X GET -H "Content-Type:application/json" -H "Authorization: bearer $bearer_token" "$WEB_URL/debug?${1}")
    if [ -z "${response}" ]
    then
        echo "Failed to load debug information for group ${1}"
    else
        TOTAL_OUTPUT=$TOTAL_OUTPUT+"
----------------------------------------------------------------------"
        echo "Loaded debug data for group ${1}"
        TOTAL_OUTPUT=$TOTAL_OUTPUT+"
Loaded debug data for group ${1}"
        TOTAL_OUTPUT=$TOTAL_OUTPUT+"
----------------------------------------------------------------------"
        #echo "${response}"
        TOTAL_OUTPUT=$TOTAL_OUTPUT+"
${response}"
    fi
}

function write_debug_data()
{
    if [ -z "${TOTAL_OUTPUT}" ]
    then
        echo "Error: Output looks empty will not write to file"
        return 1
    fi

    echo "Writing Output to $OUTPUT_FILE"
    echo "$TOTAL_OUTPUT" >> $OUTPUT_FILE
}

function run()
{
    echo "============================== Starting =============================="
    validate_inputs
    echo "----------------------------------------------------------------------"
    validate_requirements
    echo "----------------------------------------------------------------------"
    authenticate
    
    for i in "${DEBUG_GROUPS[@]}"
    do
        echo "----------------------------------------------------------------------"
        get_debug_data_for_group "$i"
    done
    echo "${TOTAL_OUTPUT}"
    echo "----------------------------------------------------------------------"
    write_debug_data
    echo "----------------------------------------------------------------------"
    echo "Debug data output complete."
    echo "----------------------------------------------------------------------"
    echo "======================================================================"
}

################################ MAIN ####################################
run
##########################################################################

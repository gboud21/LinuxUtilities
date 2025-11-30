#!/bin/bash

# Expected number of parameters for the script
EXPECTED_ARGUMENT_COUNT=3

# The Partion to expand
PARTITION_NAME=""

# The size to expand the partition to
PARTITION_SIZE=0

# --- Prints a spacer for terminal output
function printSpacer {
    echo "================================================================"
}

# --- Prints the formated data for a parameter
function printParameter {
    echo "    ${1}"
    echo "        ${2}"
}

# --- Prints the help text for the script
function printHelp {
    printSpacer
    echo "Script: expand_disk.sh"
    echo "Parameters:"
    printParameter "-h --help:"             "Prints the help Script"
    printParameter "-p --partition-name"    "The name of the partition to expand"
    printParameter "-s --size"              "The size to expand the partition to"
    printSpacer
}

###############################################################################
# Validates the input parameters are correct
function validate_parameters(){
    # Validate the Disk Name
    if lsblk -ndo TYPE "${PARTITION_NAME}" 2>/dev/null | grep -qF "part"; then
        return 0 # Valid partition
    else
        return 1 # Not a valid partition
    fi

    # Validate the value to extend it by
    if [ ${PARTITION_SIZE} -eq 0 ]; then
        echo "Error: New Partition Size not specified"
        exit -1
    fi
     
}

###############################################################################
# Verifies that the dependencies are installed
function is_growpart_installed(){
    # Check if the correct tool is installed
    which growpart > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: growpart not installed. Execute the following command:"
        echo "apt-get update && apt-get install cloud-guest-utils"
        exit -1
    fi
}

function process_parameters(){
    # --- Processes any script parameters
    if [ $# -gt 0 ]; then
        VALID_ARGS=$(getopt -o p:s:h --long partition-name:,size:,help -- "$@")

        if [[ $? -ne 0 ]]; then
            exitScript ${RETURN_ARGUMENT_INIT_ERROR}
        fi

        eval set -- "${VALID_ARGS}"

        while [ : ]; do
            case "${1}" in
            -p | --partition-name)
                PARTITION_NAME="${2}"
                shift 2
                ;;
            -s | --size)
                PARTITION_SIZE=${2}
                shift 2
                ;;
            -h | --help)
                printHelp
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Internal Error: Option processing failed at $1"
                exit 1
                ;;
            esac
        done
    else
        echo "Error: No arguments specified."
        exit -1
    fi
}

###############################################################################
# The main Sequence to be executed
function main(){
    is_growpart_installed
    process_parameters "$@"
    validate_parameters
}

# --- Execute the script
main "$@"


#!/bin/bash

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

function setup_infra {
    echo -e "Starting infra setup."
    bash setup.sh
    if [ $? -ne 0 ]
    then
        echo -e "Infra setup ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Infra setup ${GREEN}[OK]${NC}"
}

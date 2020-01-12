#!/bin/bash

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# Environments
LOG_FILE=/tmp/vagrant_up.$(date "+%Y.%m.%d-%H.%M.%S").log

function vagrant_executable {
    which vagrant 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Check vagrant executable ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Check vagrant executable ${GREEN}[OK]${NC}"
}

function vagrant_scp_plugin_install {
    vagrant plugin install vagrant-scp 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Vagrant scp plugin install ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Vagrant scp plugin install ${GREEN}[OK]${NC}"
}

function ansible_executable {
    which ansible 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Check ansible executable ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Check ansible executable ${GREEN}[OK]${NC}"
}

function docker_executable {
    which docker 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Check docker executable ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Check docker executable ${GREEN}[OK]${NC}"
}

function docker_usability {
    docker ps 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Check docker command usability ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Check docker command usability ${GREEN}[OK]${NC}"
}

function j2_usability {
    which j2 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Check j2 command usability ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Check j2 command usability ${GREEN}[OK]${NC}"
}

function prerequisites {
    vagrant_executable
    vagrant_scp_plugin_install
    ansible_executable
    docker_executable
    docker_usability
    j2_usability
}

function vagrant_up {
    vagrant up 2>&1 >> ${LOG_FILE}
    if [ $? -ne 0 ]
    then
        echo -e "Vagrant up ${RED}[ERROR]${NC}"
        echo -e "Please see the log file. Path: ${LOG_FILE}"
        exit 1
    fi
    vagrant scp k8s-master:/home/vagrant/.kube/config /tmp/kube_config 2>&1 >> ${LOG_FILE}
    echo -e "Vagrant up ${GREEN}[OK]${NC}"
}

function vagrant_destroy {
    vagrant destroy -f 2>&1 >> ${LOG_FILE}
    if [ $? -ne 0 ]
    then
        echo -e "Vagrant destroy ${RED}[ERROR]${NC}"
        echo -e "Please see the log file. Path: ${LOG_FILE}"
        exit 1
    fi
    echo -e "Vagrant destroy ${GREEN}[OK]${NC}"
}

function kubernetes_access_setup {
    # If user already has a kubernetes config, append to new one
    if [ -d ${HOME}/.kube ]
    then
        cat /tmp/kube_config >> ${HOME}/.kube/config
    else
        mkdir ${HOME}/.kube && cat /tmp/kube_config >> ${HOME}/.kube/config
    fi
    if [ $? -ne 0 ]
    then
        echo -e "Shipping kube config ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Shipping kube config ${GREEN}[OK]${NC}"
}

function setup {
    # Run prerequisites
    echo -e "Running checks before jump to the action."
    prerequisites

    echo -e "\nJumping to the action. The first step is running the vagrant up command. This could take a few minutes. You can follow all processes belongs to this step with a log file named  ${LOG_FILE}."
    # Run vagrant process
    vagrant_destroy
    vagrant_up
    kubernetes_access_setup
}

# Start setup
setup

#!/bin/bash
set -a

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# Environments
SETUP_PREFIX="kubernetes-setup-for"

function setup_infra {
    bash setup.sh
    if [ $? -ne 0 ]
    then
        echo -e "Infra setup ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Infra setup ${GREEN}[OK]${NC}"
}

function build_application {
    cd docker && \
        docker build -t ${APPLICATION_NAME}:latest . 2>&1 > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "Docker image build. ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Docker image build. ${GREEN}[OK]${NC}"

    if [ ${#REGISTRY} -ne 0 ]
    then
        docker build -t ${REGISTRY}/${APPLICATION_NAME}:latest . 2>&1 > /dev/null && \
            docker push ${REGISTRY}/${APPLICATION_NAME}:latest

        if [ $? -ne 0 ]
        then
            echo -e "Docker image build for registry. ${RED}[ERROR]${NC}"
            exit 1
        fi
        echo -e "Docker image build for registry. ${GREEN}[OK]${NC}"

        K8S_IMAGE=${REGISTRY}/${APPLICATION_NAME}:latest
    fi

    K8S_IMAGE=${APPLICATION_NAME}:latest
}

function k8s_setup {
    kubectl create ns ${K8S_NAMESPACE} 2>&1 > /dev/null
    if [[ ${#DATABASE} -ne 0 && -d kubernetes/${DATABASE} ]]
    then
        kubectl apply -n ${K8S_NAMESPACE} -f kubernetes/${DATABASE}/ 2>&1 > /dev/null

        if [ $? -ne 0 ]
        then
            echo -e "Database setup for ${DATABASE}. ${RED}[ERROR]${NC}"
            exit 1
        fi
        echo -e "Database setup for ${DATABASE}. ${GREEN}[OK]${NC}"
    fi

    mkdir ${SETUP_PREFIX}-${K8S_NAMESPACE} 2>&1 > /dev/null && \
        j2 kubernetes/application/service.yaml > ${SETUP_PREFIX}-${K8S_NAMESPACE}/services.yaml && \
        j2 kubernetes/application/deployment.yaml > ${SETUP_PREFIX}-${K8S_NAMESPACE}/deployment.yaml

    if [ $? -ne 0 ]
    then
        echo -e "Kubernetes setup completed for ${K8S_NAMESPACE}. ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Kubernetes setup completed for ${K8S_NAMESPACE}. ${GREEN}[OK]${NC}"
}

while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
        -o|--operation)  # infra-setup, build, k8s-setup, deploy, bundle-deploy
        OPERATION="$2"
        shift
        shift
        ;;
        --application-name)
        APPLICATION_NAME="$2"
        export APPLICATION_NAME="$2"
        shift
        shift
        ;;
        --docker-registry)
        REGISTRY="$2"
        export REGISTRY="$2"
        shift
        shift
        ;;
        --k8s-namespace)
        K8S_NAMESPACE="$2"
        export K8S_NAMESPACE="$2"
        shift
        shift
        ;;
        --k8s-services)
        K8S_SERVICES="$2"
        export K8S_SERVICES="$2"
        shift
        shift
        ;;
        --k8s-env-variables)
        K8S_ENV_VARIABLES="$2"
        export K8S_ENV_VARIABLES="$2"
        shift
        shift
        ;;
        --k8s-image)
        K8S_IMAGE="$2"
        export K8S_IMAGE="$2"
        shift
        shift
        ;;
        --db)  # mysql, postgres
        DATABASE="$2"
        shift
        shift
        ;;
        *)
        ;;
    esac
done

case ${OPERATION} in
    infra-setup)
    setup_infra
    ;;
    build)
    if [ ${#APPLICATION_NAME} -eq 0 ]
    then
        echo -e "${RED}[ERROR]${NC} You should give an application name with --application-name parameter."
        exit 1
    fi
    build_application
    ;;
    k8s-setup)
    if [[ ${#K8S_NAMESPACE} -eq 0 || ${#K8S_SERVICES} -eq 0 || ${#K8S_ENV_VARIABLES} -eq 0 || ${#K8S_IMAGE} -eq 0 || ${#APPLICATION_NAME} -eq 0 ]]
    then
        echo -e "${RED}[ERROR]${NC} You should give following parameters. --application-name, --k8s-namespace, --k8s-services, --k8s-env-variables, --k8s-image."
        exit 1
    fi
    k8s_setup
    ;;
    *)

    ;;
esac

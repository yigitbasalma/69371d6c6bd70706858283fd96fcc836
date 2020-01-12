#!/bin/bash
set -a

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# Environments
SETUP_PREFIX="kubernetes-setup-for"
read -r -d '' HELP <<- EOM
Help for ${0};
    --operation:    Operation name. [infra-setup, build, k8s-setup, deploy, bundle-deploy]
        for infra-setup
            Infrastructure setup for lab. Run vagrant up, create k8s cluster with 1 master 1 node, get k8s credential.
        for build
            Run docker build in docker folder. Your application code must be in docker/app folder.
            Parameters:
                --application-name:     Application name for docker image.
            Optional parameters:
                --docker-registry:      Docker registry address for docker pull command. You must be logged in to remote registry.
        for k8s-setup
            Prepare your application to deploy k8s. Your all yaml files belongs to your application prepare dynamically.
            Parameters:
                --application-name:     Application name for deployment.
                --k8s-namespace:        Namespace for your environment.
                --k8s-services:         Application services. Syntax: "protocol:port:target-port;..."
                --k8s-env-variables:    Environment variables for application container. Syntax: "key:value;..."
                --k8s-image:            Image name for your application container.
        for deploy
            Deploy prepared yaml files to the project namespace
            Parameters
                --application-name:     Application name for deployment.
                --k8s-namespace:        Namespace for your environment.
            Optional parameters:
                --db:                   Database software name for your application. [mysql]
        for bundle-deploy
            Apply all other options sequentially.
EOM

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
    docker build -t ${APPLICATION_NAME}:latest -f docker/Dockerfile docker/ 1> /dev/null &&
    if [ $? -ne 0 ]
    then
        echo -e "Docker image build. ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Docker image build. ${GREEN}[OK]${NC}"

    if [ ${#REGISTRY} -ne 0 ]
    then
        docker build -t ${REGISTRY}/${APPLICATION_NAME}:latest -f docker/Dockerfile docker/ 1> /dev/null && \
            docker push ${REGISTRY}/${APPLICATION_NAME}:latest

        if [ $? -ne 0 ]
        then
            echo -e "Docker image build for registry. ${RED}[ERROR]${NC}"
            exit 1
        fi
        echo -e "Docker image build for registry. ${GREEN}[OK]${NC}"

        K8S_IMAGE=${REGISTRY}/${APPLICATION_NAME}:latest
        return 0
    fi

    K8S_IMAGE=${APPLICATION_NAME}:latest
}

function k8s_setup {
    kubectl create ns ${K8S_NAMESPACE} 2>&1 > /dev/null || echo -e "Namespace already exists. ${GREEN}[OK]${NC}"

    if [[ ${#DATABASE} -ne 0 && -d kubernetes/${DATABASE} ]]
    then
        kubectl apply -n ${K8S_NAMESPACE} -f kubernetes/${DATABASE}/ 1> /dev/null && \
            export DB_CLUSTER_IP=`kubectl get service/db-service -o jsonpath='{.spec.clusterIP}' -n ${K8S_NAMESPACE}`

        if [ $? -ne 0 ]
        then
            echo -e "Database setup for ${DATABASE}. ${RED}[ERROR]${NC}"
            exit 1
        fi
        echo -e "Database setup for ${DATABASE}. ${GREEN}[OK]${NC}"
    fi

    if [ ${#K8S_ENV_VARIABLES} -eq 0 ]
    then
        export K8S_ENV_VARIABLES=""
    fi

    if [ ! -d ${SETUP_PREFIX}-${K8S_NAMESPACE} ];then mkdir ${SETUP_PREFIX}-${K8S_NAMESPACE}; fi

    j2 kubernetes/application/service.yaml > ${SETUP_PREFIX}-${K8S_NAMESPACE}/services.yaml && \
        j2 kubernetes/application/deployment.yaml > ${SETUP_PREFIX}-${K8S_NAMESPACE}/deployment.yaml

    if [ $? -ne 0 ]
    then
        echo -e "Kubernetes setup completed for ${K8S_NAMESPACE}. ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Kubernetes setup completed for ${K8S_NAMESPACE}. ${GREEN}[OK]${NC}"
}

function deploy {
    POD_NAME=`kubectl get po -n ${K8S_NAMESPACE} | grep ${APPLICATION_NAME} | awk '{print$1}'`
    if [ ${#POD_NAME} -eq 0 ]
    then
        kubectl apply -n ${K8S_NAMESPACE} -f ${SETUP_PREFIX}-${K8S_NAMESPACE}/ 1> /dev/null
    else
        kubectl delete po ${POD_NAME} -n ${K8S_NAMESPACE} 1> /dev/null
    fi

    if [ $? -ne 0 ]
    then
        echo -e "Application deployment for ${APPLICATION_NAME}. ${RED}[ERROR]${NC}"
        exit 1
    fi
    echo -e "Application deployment for ${APPLICATION_NAME}. ${GREEN}[OK]${NC}"
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
        export DATABASE="$2"
        shift
        shift
        ;;
        *)
        echo -e "${HELP}"
        exit 0
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
    if [[ ${#K8S_NAMESPACE} -eq 0 || ${#K8S_SERVICES} -eq 0 || ${#K8S_IMAGE} -eq 0 || ${#APPLICATION_NAME} -eq 0 ]]
    then
        echo -e "${RED}[ERROR]${NC} You should give following parameters. --application-name, --k8s-namespace, --k8s-services, --k8s-image."
        exit 1
    fi
    k8s_setup
    ;;
    deploy)
    if [ ${#K8S_NAMESPACE} -eq 0 ]
    then
        echo -e "${RED}[ERROR]${NC} You should give a namespace with --k8s-namespace parameter."
        exit 1
    fi
    if [[ ! -d ${SETUP_PREFIX}-${K8S_NAMESPACE} ]]
    then
        echo -e "${RED}[ERROR]${NC} You should run k8s-setup option before this."
        exit 1
    fi
    deploy
    ;;
    bundle-deploy)
    # infra-setup
    setup_infra

    # build
    if [ ${#APPLICATION_NAME} -eq 0 ]
    then
        echo -e "${RED}[ERROR]${NC} You should give an application name with --application-name parameter."
        exit 1
    fi
    build_application

    # k8s-setup
    if [[ ${#K8S_NAMESPACE} -eq 0 || ${#K8S_SERVICES} -eq 0 || ${#K8S_IMAGE} -eq 0 || ${#APPLICATION_NAME} -eq 0 ]]
    then
        echo -e "${RED}[ERROR]${NC} You should give following parameters. --application-name, --k8s-namespace, --k8s-services, --k8s-image."
        exit 1
    fi
    k8s_setup

    # deploy
    if [ ${#K8S_NAMESPACE} -eq 0 ]
    then
        echo -e "${RED}[ERROR]${NC} You should give a namespace with --k8s-namespace parameter."
        exit 1
    fi
    if [[ ! -d ${SETUP_PREFIX}-${K8S_NAMESPACE} ]]
    then
        echo -e "${RED}[ERROR]${NC} You should run k8s-setup option before this."
        exit 1
    fi
    deploy
    ;;
    *)
    echo -e "${HELP}"
    ;;
esac

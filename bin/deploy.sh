#!/bin/sh
# ---------------------------------------------------------------------
# Deploy hiraafood application in docker containers either locally
# or in aws EC2
# ---------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR=`cd $DIR/..;pwd`

APPNAME=hiraafood
HOSTNAME=anna
REMOTE=0
DOCKER_USER=ppoddar
PROD_USER=ec2-user

DOCKER_REPO=anna
IMAGE_NAME=anna_image
DOCKER_IMAGE=$DOCKER_USER/$DOCKER_REPO:$IMAGE_NAME

GIT_URL=git@github.com:ppoddar/anna.git 

LOCALHOST=`ipconfig getifaddr en0`

SRC=.
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m' 
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
PORT=8090

function warn {
    echo $COLOR_YELLOW***WARN:$1$COLOR_RESET
}
function error {
    echo $COLOR_RED***ERROR:$1$COLOR_RESET

}
function info {
    echo $COLOR_GREEN$1$COLOR_RESET
}


# check if uncommitted files are present
# remote deployment requires that no committed files are present
function check_uncommited {
    if [[ -z $(git status -s) ]]; then
        echo 
    else 
        if [[ $REMOTE -eq 1 ]]; then
            error 'can not deploy to production with uncommitted files'
            git status -s
            exit 1
        else
            warn 'there are uncommited files'
            UNCOMMITED=1
        fi
    fi
}

function create_docker_image {
    pushd $HOME_DIR > /dev/null
    info 'creating docker image '$DOCKER_IMAGE
    docker build $SRC -t $DOCKER_IMAGE
    popd > /dev/null
}

function push_docker_image {
    info 'pushing '$DOCKER_IMAGE
    docker login --username=$DOCKERHUB_USER; docker push $DOCKER_IMAGE
}


function populate_menu {
    echo 'populate menu'
    node $HOME_DIR/src/populate_objects.js -d $HOME_DIR/data/menu/
}
function get_latest_source {
    git pull
}

# -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in 
        -r)
            REMOTE=1
            shift
            ;;
        -h|--help|-?)
            HELP=1
            shift
        ;;
        *)
            echo unknown option $key
            usage
            shift
            exit
            ;;
    esac
done 


if [[ $REMOTE -eq 1 ]]; then
    REMOTE_HOST=hiraafood.com
    info 'deploying '$APPNAME' dockerized application to '$REMOTE_HOST
else
    info 'deploying '$APPNAME' dockerized application in stage'  
fi
check_uncommited
create_docker_image
push_docker_image
if [[ $REMOTE -eq 1 ]]; then
PEM=$DIR/anna.pem
ssh -tt  -i $PEM $PROD_USER@$REMOTE_HOST << EOSSH
    git clone https://github.com/ppoddar/anna.git
    cd anna
    docker build - anna .
    docker run -d -p $PORT:8080 --rm $DOCKER_IMAGE 
EOSSH
else
    info 'running dockerized application. access it as port '$PORT
    docker run -d -p $PORT:8080 --rm $DOCKER_IMAGE
fi


sleep 2
populate_menu




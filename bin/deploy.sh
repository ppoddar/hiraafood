#!/bin/sh
# ---------------------------------------------------------------------
# Deploy hiraafood application in docker containers either locally
# or in aws EC2
# ---------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR=`cd $DIR/..;pwd`

REMOTE=0
PROD_USER=ec2-user

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
        fi
    fi
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
if [[ $REMOTE -eq 1 ]]; then
PEM=$DIR/anna.pem
check_uncommited
ssh -tt  -i $PEM $PROD_USER@$REMOTE_HOST << EOSSH
    docker build --rm --tag hiraafood https://github.com/ppoddar/hiraafood.git
    docker run -P hiraafood
EOSSH
else
    info 'running dockerized application. access it as port '$PORT
    docker build --rm --tag hiraafood .
    docker run -d -P --rm hiraafood
fi



#sleep 2
#populate_menu




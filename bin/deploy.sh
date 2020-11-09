#!/bin/sh
# ---------------------------------------------------------------------
# Deploy hiraafood application in docker containers either locally
# or in aws EC2
# ---------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR=`cd $DIR/..;pwd`

APPNAME=hiraafood
REMOTE=0
PROTOCOL=http
HOST=localhost

COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m' 
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'


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
            warn 'deploying in production with uncommitted files'
            git status -s
        fi
    fi
}



# -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in 
        -r)
            REMOTE=1
            HOST=hiraafood.com
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
    info 'deploying '$APPNAME' dockerized application to '$HOST
    PEM=$DIR/anna.pem
    check_uncommited
    ssh -tt  -i $PEM ec2-user@$HOST << EOSSH
        docker build --rm --tag hiraafood https://github.com/ppoddar/hiraafood.git
        docker container ps -aq | xargs docker container stop
        docker run -d -p80:80 --rm hiraafood
        exit 0
EOSSH
else
    info 'deploying '$APPNAME' dockerized application in stage. http://localhost/' 
    docker build --rm --tag hiraafood .
    docker run -d -p80:80 --rm hiraafood 
fi

#!/bin/sh
# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR=`cd $DIR/..;pwd`
# default to stage enviroment
PROTOCOL=http
HOST=localhost
PORT=8080
DATA_DIR=$HOME_DIR/data/menu
# -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in 
        -r)
            PROTOCOL=http
            HOST=hiraafood.com
            PORT=80
            shift
            ;;
        --data)
           DATA_DIR=$1
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
data_files=`ls $DATA_DIR/*.json`
for data_file in $data_files
do
   curl -X POST $PROTOCOL://$HOST:$PORT/item \
    -H "Content-Type:application/json" \
    -d @$data_file
done




#!/bin/sh
echo 'stop and remove all dockerized containers' 
docker container ls -aq | xargs docker container stop
docker container ls -aq | xargs docker container rm
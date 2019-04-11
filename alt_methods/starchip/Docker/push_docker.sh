#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker push fusiontranscripts/starchip:${VERSION}
docker push fusiontranscripts/starchip:latest

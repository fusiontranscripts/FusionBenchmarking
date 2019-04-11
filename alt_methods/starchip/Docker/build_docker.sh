#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker build -t fusiontranscripts/starchip:${VERSION} .
docker build -t fusiontranscripts/starchip:latest .

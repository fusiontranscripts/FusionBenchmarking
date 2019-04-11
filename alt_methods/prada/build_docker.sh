#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker build -t fusiontranscripts/prada:${VERSION} .
docker build -t fusiontranscripts/prada:latest .

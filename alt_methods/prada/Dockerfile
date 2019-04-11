FROM ubuntu:16.04
MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python automake make \
                                       wget git curl libdb-dev \
                                       zlib1g-dev bzip2 libncurses5-dev \
                                       texlive-latex-base \
                                       default-jre \
                                       python-pip python-dev \
                                       gfortran \
                                       build-essential libghc-zlib-dev libncurses-dev libbz2-dev liblzma-dev libpcre3-dev libxml2-dev \
                                       libblas-dev gfortran git unzip ftp libzmq3-dev nano ftp fort77 libreadline-dev \
                                       libcurl4-openssl-dev libx11-dev libxt-dev \
                                       x11-common libcairo2-dev libpng12-dev libreadline6-dev libjpeg8-dev pkg-config libtbb-dev \
                   && apt-get clean


RUN sed -i -e 's/:\/\/(archive.ubuntu.com\|security.ubuntu.com)/old-releases.ubuntu.com/g' /etc/apt/sources.list


## install old java-7
RUN apt-get update && apt-get install -y python3-software-properties software-properties-common

RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update && apt-get install -y openjdk-7-jdk


RUN mv /usr/bin/java /usr/bin/java8 && \
    ln -s /usr/lib/jvm/java-7-openjdk-amd64/bin/java /usr/bin/java7 && \
    ln -s /usr/bin/java7 /usr/bin/java



## install prada

WORKDIR /usr/local/src
RUN wget https://downloads.sourceforge.net/project/prada/pyPRADA/pyPRADA_1.2.tar.gz  && \
    tar xvf pyPRADA_1.2.tar.gz


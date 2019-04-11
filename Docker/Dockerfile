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
                                       x11-common libcairo2-dev libpng12-dev libreadline6-dev libjpeg8-dev pkg-config \
                   && apt-get clean


ENV SRC /usr/local/src
ENV BIN /usr/local/bin

# perl helpers

RUN curl -L https://cpanmin.us | perl - App::cpanminus

RUN cpanm install DB_File
RUN cpanm install Set::IntervalTree



#####
# Install R

WORKDIR $SRC

ENV R_VERSION=R-3.3.2

RUN curl https://cran.r-project.org/src/base/R-3/$R_VERSION.tar.gz -o $R_VERSION.tar.gz && \
        tar xvf $R_VERSION.tar.gz && \
        cd $R_VERSION && \
        ./configure && make && make install


RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("ggplot2", dep = TRUE)'
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("Biobase", dep = TRUE)'
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("qvalue", dep = TRUE)'


#########
# Install FusionAnnotator

RUN git clone https://github.com/FusionAnnotator/FusionAnnotator.git && \
    cd FusionAnnotator && \
    git checkout 6e6c3b4 && \
    make

ENV FUSION_ANNOTATOR ${SRC}/FusionAnnotator

########
# Install Trinity (just for plotting utilities)

RUN git clone https://github.com/trinityrnaseq/trinityrnaseq.git && \
    cd trinityrnaseq && \
    git checkout 1603d80 

ENV TRINITY_HOME ${SRC}/trinityrnaseq

########
# Install benchmarking utilities

RUN git clone https://github.com/FusionSimulatorToolkit/FusionSimulatorToolkit.git && \
    cd FusionSimulatorToolkit && \
    git checkout 54985b9

ENV FUSION_SIMULATOR ${SRC}/FusionSimulatorToolkit

#######
# Install STAR-Fusion benchmark data

RUN git clone https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data.git && \
    cd STAR-Fusion_benchmarking_data && \
    git checkout fec9f09


ENV LC_ALL=C


COPY run_eval.sh /

CMD ["/run_eval.sh"]


FROM ubuntu:18.04
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
 x11-common libcairo2-dev libpng-dev libreadline-dev libjpeg-dev pkg-config libtbb-dev \
 && apt-get clean

RUN curl -L https://cpanmin.us | perl - App::cpanminus

RUN cpanm install DB_File
RUN cpanm install URI::Escape
RUN cpanm install JSON::XS


## set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin


#####
# Install R

WORKDIR $SRC

ENV R_VERSION=R-3.5.2

RUN curl https://cran.r-project.org/src/base/R-3/$R_VERSION.tar.gz -o $R_VERSION.tar.gz && \
 tar xvf $R_VERSION.tar.gz && \
 cd $R_VERSION && \
 ./configure && make && make install



RUN curl -L https://cpanmin.us | perl - App::cpanminus

RUN cpanm install DB_File
RUN cpanm install Set::IntervalTree



RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("ggplot2", dep = TRUE)'
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("Biobase", dep = TRUE)'
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("qvalue", dep = TRUE)'


#########
# Install FusionAnnotator

WORKDIR $SRC
RUN git clone https://github.com/FusionAnnotator/FusionAnnotator.git && \
 cd FusionAnnotator && \
 git checkout 0dc2edc25f7881fd552236c5e12b302cef6eea7a 

ENV FUSION_ANNOTATOR ${SRC}/FusionAnnotator


########
# Install Trinity (just for plotting utilities)
WORKDIR $SRC
RUN git clone https://github.com/trinityrnaseq/trinityrnaseq.git && \
 cd trinityrnaseq && \
 git checkout 514756d12c614046a4ad50fd63b34e59cdec4c9a

ENV TRINITY_HOME ${SRC}/trinityrnaseq

##############
# Install fusion benchmarking
WORKDIR $SRC
RUN git clone https://github.com/fusiontranscripts/FusionBenchmarking.git && \
 cd FusionBenchmarking && \
 git checkout d45ef8b



ENV LC_ALL=C


RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("fastcluster", dep = TRUE)'
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("tidyr", dep = TRUE)'

RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("devtools", dep = TRUE)'

## get my hacked version of upsetR
WORKDIR $SRC
RUN git clone https://github.com/brianjohnhaas/UpSetR.git && \
   cd UpSetR && \
   git checkout d72b0b5 && \
   Rscript -e 'install.packages("./", repos=NULL, type="source", INSTALL_opts = "--with-keep.source")'


## mini ctat genome lib used by fusion annotator:
COPY ctat_genome_lib_dir $SRC/ctat_genome_lib_dir/

ENV CTAT_GENOME_LIB $SRC/ctat_genome_lib_dir

COPY run_eval.sh /

CMD ["/run_eval.sh"]


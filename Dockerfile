FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y
RUN apt-get install -y git unzip vim
WORKDIR /
RUN git clone https://github.com/aflgo/aflgo.git && cd aflgo && bash ./build.sh
COPY . /work_dir
WORKDIR /work_dir
RUN git clone https://github.com/GNOME/libxml2.git
RUN git clone https://github.com/facebook/zstd.git
ENTRYPOINT ["/bin/bash"]

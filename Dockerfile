FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y
RUN apt-get install -y wget gawk pkg-config
WORKDIR /tmp
RUN wget https://raw.githubusercontent.com/aflgo/aflgo/master/scripts/build/aflgo-build.sh && bash ./aflgo-build.sh
RUN mv /root/build/llvm_tools/build-llvm/msan/aflgo /root/
WORKDIR /io
ENTRYPOINT ["/bin/bash"]

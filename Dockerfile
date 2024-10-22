FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y
RUN apt-get install -y git unzip vim
WORKDIR /
RUN git clone https://github.com/aflgo/aflgo.git && cd aflgo && bash ./build.sh
RUN pip3 install timeout_decorator tqdm 
ENTRYPOINT ["/bin/bash"]

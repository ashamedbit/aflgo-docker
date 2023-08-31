# AFLGo libxml2 Example

## General

This sets up a Docker environment to build AFLGo and run the libxml2 example. For more information see: https://github.com/aflgo/aflgo/tree/master

Just execute `./run.sh` to get going. Note that if you build everything for the first time it will take quite long ☕
If you want to fuzz another project with AFLGo and this setup just modify the `./setup_afl_and_fuzz.sh` file below the `project specific steps` comment.

## Docker Base Image

Currently the Docker base image is `ubuntu:20.04`.
`ubuntu:22.04` and `ubuntu:23.04` did *not* work out-of-the-box (compilation of LLVM 11 failed)

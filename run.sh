#!/usr/bin/env bash

# this will run on the host (not inside the container)

BUILDKIT_PROGRESS=plain docker build -t aflgo .
# we need --privileged to change /proc and /sys settings for AFLGo
docker run -it --rm --privileged -v $(pwd):/io:Z aflgo ./setup_afl_and_fuzz.sh

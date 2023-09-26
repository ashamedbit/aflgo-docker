#!/usr/bin/env bash

# this will run inside the Docker container

# general AFL setup
echo core > /proc/sys/kernel/core_pattern
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# project specific steps
wget https://raw.githubusercontent.com/aflgo/aflgo/master/examples/libxml2-ef709ce2.sh
chmod +x ./libxml2-ef709ce2.sh
AFLGO="/aflgo" ./libxml2-ef709ce2.sh

# AFLGo libxml2 Example

## General

This sets up a Docker environment to build AFLGo and run the bug injected versions of libxml2, zstd and PROJ examples.
Execute the below commands to setup docker environment for setting up AFLGo. Note that if you build everything for the first time it will take quite long (since AFLGo is built from source) ☕

```bash
git clone https://github.com/ashamedbit/aflgo-docker.git
cd aflgo-docker
docker build -t aflgo .
docker run -it aflgo
```

After running above commands you should be in docker environment. Now run the following commands to run AFLGo on each project
1. zstd: `bash setup_afl_and_fuzz_zstd.sh`
2. libxml2: `bash setup_afl_and_fuzz_libxml2.sh`
3. PROJ: `bash setup_afl_and_fuzz_PROJ.sh`

Running each of above should get AFLGo running on the bug injected version of each project. Use Ctl+C to exit AFLGo because it will indefinitely keep fuzzing once started!

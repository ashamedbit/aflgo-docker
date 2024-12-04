#!/bin/bash

set -euo pipefail
set -x
export AFLGO=/aflgo
git clone https://github.com/OSGeo/PROJ.git
cd PROJ; git checkout d00501750b210a73f9fb107ac97a683d4e3d8e7a; git apply ../PROJ-injection.patch;
mkdir obj-aflgo; mkdir obj-aflgo/temp
export SUBJECT=$PWD; export TMP_DIR=$PWD/obj-aflgo/temp
export CC=$AFLGO/instrument/aflgo-clang; export CXX=$AFLGO/instrument/aflgo-clang++
export LDFLAGS=-lpthread
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps -DFRCOV -ggdb -fsanitize=address"


cp ../BBtargets-PROJ.txt $TMP_DIR/BBtargets.txt
./autogen.sh;
cd obj-aflgo;  CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --prefix=`pwd`
make clean; make -k || true;

$CC $ADDITIONAL -DSTANDALONE -I ../src -c ../test/fuzzers/standard_fuzzer.c -o ../test/fuzzers/standard_fuzzer.o
$CC $ADDITIONAL -I ../src ../test/fuzzers/standard_fuzzer.o ./src/.libs/libproj.a -o ./standard_fuzzer -lpthread

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLGO/distance/gen_distance_orig.sh $SUBJECT/obj-aflgo $TMP_DIR standard_fuzzer

export ADDITIONAL="-distance=$TMP_DIR/distance.cfg.txt -DFRCOV -fsanitize=address"
CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --disable-shared --prefix=`pwd`
make clean; make -k || true

$CC $ADDITIONAL -DSTANDALONE -I ../src -c ../test/fuzzers/standard_fuzzer.c -o ../test/fuzzers/standard_fuzzer.o
$CC $ADDITIONAL -I ../src ../test/fuzzers/standard_fuzzer.o ./src/.libs/libproj.a -o ./standard_fuzzer -lpthread

set +e
mkdir in; echo "AAA" > in/a;
export FIXREVERTER=""
$AFLGO/afl-2.57b/afl-fuzz -m none -z exp -c 45m -i in -o out ./standard_fuzzer @@

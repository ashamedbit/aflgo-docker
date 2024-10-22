#!/bin/bash

set +e

export AFLGO=/aflgo
git clone https://github.com/facebook/zstd.git
cd zstd; git checkout 9ad7ea44ec9644c618c2e82be5960d868e48745d; git apply ../zstd-injection.patch
mkdir obj-aflgo; mkdir obj-aflgo/temp
export SUBJECT=$PWD; export TMP_DIR=$PWD/obj-aflgo/temp
export CC=$AFLGO/instrument/aflgo-clang; export CXX=$AFLGO/instrument/aflgo-clang++
export LDFLAGS=-lpthread
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps -DFRCOV -ggdb -fsanitize=address"


cp ../BBtargets-zstd.txt $TMP_DIR/BBtargets.txt
make distclean
# make clean; make CC="$CC $ADDITIONAL"
make clean; cd tests/fuzz; CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" python3 fuzz.py build stream_decompress
cd $SUBJECT

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLGO/distance/gen_distance_orig.sh $SUBJECT/tests/fuzz $TMP_DIR ./stream_decompress

export ADDITIONAL="-distance=$TMP_DIR/distance.cfg.txt -DFRCOV -fsanitize=address"
# make clean; make CC="$CC -distance=$TMP_DIR/distance.cfg.txt -DFRCOV" CXXFLAGS="-distance=$TMP_DIR/distance.cfg.txt -DFRCOV"

make clean; cd tests/fuzz; CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" python3 fuzz.py build stream_decompress; make corpora
cd $SUBJECT


cd obj-aflgo/temp
mkdir in; mv $SUBJECT/tests/fuzz/corpora/stream_decompress/* in/
export FIXREVERTER=""
$AFLGO/afl-2.57b/afl-fuzz -m none -z exp -c 45m -i $SUBJECT/obj-aflgo/temp/in -o $SUBJECT/obj-aflgo/temp/out -- $SUBJECT/tests/fuzz/stream_decompress @@

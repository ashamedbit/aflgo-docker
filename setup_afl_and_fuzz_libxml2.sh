#!/bin/bash

set -euo pipefail

export AFLGO=/aflgo
git clone https://gitlab.gnome.org/GNOME/libxml2.git
cd libxml2; git checkout 99a864a1f7a9cb59865f803770d7d62fb47cad69; git apply ../libxml-injection.patch; cp ../libxml2_xml_reader_for_file_fuzzer.cc . ; cp ../fuzzer_temp_file.h .
mkdir obj-aflgo; mkdir obj-aflgo/temp
export SUBJECT=$PWD; export TMP_DIR=$PWD/obj-aflgo/temp
export CC=$AFLGO/instrument/aflgo-clang; export CXX=$AFLGO/instrument/aflgo-clang++
export LDFLAGS=-lpthread
export ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps -DFRCOV -ggdb -fsanitize=address"

# git diff -U0 HEAD^ HEAD > $TMP_DIR/commit.diff
# wget https://raw.githubusercontent.com/jay/showlinenum/develop/showlinenum.awk
# chmod +x showlinenum.awk
# mv showlinenum.awk $TMP_DIR
# cat $TMP_DIR/commit.diff |  $TMP_DIR/showlinenum.awk show_header=0 path=1 | grep -e "\.[ch]:[0-9]*:+" -e "\.cpp:[0-9]*:+" -e "\.cc:[0-9]*:+" | cut -d+ -f1 | rev | cut -c2- | rev > $TMP_DIR/BBtargets.txt


cp ../BBtargets-libxml.txt $TMP_DIR/BBtargets.txt
./autogen.sh; make distclean
cd obj-aflgo;  CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --disable-shared --prefix=`pwd`
make clean; make V=1 CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL"

$CXX $ADDITIONAL -I./include/ -I../include/  \
     -c ../libxml2_xml_reader_for_file_fuzzer.cc  -o libxml2_xml_reader_for_file_fuzzer.o
$CXX $ADDITIONAL  .libs/libxml2.a libxml2_xml_reader_for_file_fuzzer.o SAX.o entities.o encoding.o error.o parserInternals.o parser.o tree.o hash.o list.o xmlIO.o xmlmemory.o uri.o valid.o xlink.o HTMLparser.o HTMLtree.o debugXML.o xpath.o xpointer.o xinclude.o nanohttp.o nanoftp.o catalog.o globals.o threads.o c14n.o xmlstring.o buf.o xmlregexp.o xmlschemas.o xmlschemastypes.o xmlunicode.o xmlreader.o relaxng.o dict.o SAX2.o xmlwriter.o legacy.o chvalid.o pattern.o xmlsave.o xmlmodule.o schematron.o xzlib.o  -ldl -lpthread -lz -lm -o libxml2_xml_reader_for_file_fuzzer

cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
$AFLGO/distance/gen_distance_orig.sh $SUBJECT/obj-aflgo $TMP_DIR libxml2_xml_reader_for_file_fuzzer

export ADDITIONAL="-distance=$TMP_DIR/distance.cfg.txt -DFRCOV -fsanitize=address"
CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --disable-shared --prefix=`pwd`
make clean; make V=1 CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL"
$CXX  $ADDITIONAL -I./include/ -I../include/  \
     -c ../libxml2_xml_reader_for_file_fuzzer.cc  -o libxml2_xml_reader_for_file_fuzzer.o
$CXX  $ADDITIONAL .libs/libxml2.a libxml2_xml_reader_for_file_fuzzer.o SAX.o entities.o encoding.o error.o parserInternals.o parser.o tree.o hash.o list.o xmlIO.o xmlmemory.o uri.o valid.o xlink.o HTMLparser.o HTMLtree.o debugXML.o xpath.o xpointer.o xinclude.o nanohttp.o nanoftp.o catalog.o globals.o threads.o c14n.o xmlstring.o buf.o xmlregexp.o xmlschemas.o xmlschemastypes.o xmlunicode.o xmlreader.o relaxng.o dict.o SAX2.o xmlwriter.o legacy.o chvalid.o pattern.o xmlsave.o xmlmodule.o schematron.o xzlib.o  -ldl -lpthread -lz -lm -o libxml2_xml_reader_for_file_fuzzer

set +e
mkdir in; cp $SUBJECT/test/dtd* in; cp $SUBJECT/test/dtds/* in
$AFLGO/afl-2.57b/afl-fuzz -m none -z exp -c 45m -i in -o out ./libxml2_xml_reader_for_file_fuzzer @@

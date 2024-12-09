rm -rf test
mkdir test
cd test

current_dir=$(pwd)

####################
cd $current_dir

git clone https://gitlab.gnome.org/GNOME/libxml2.git
cd libxml2; git checkout 99a864a1f7a9cb59865f803770d7d62fb47cad69; git apply ../../libxml-injection.patch; cp ../../libxml2_xml_reader_for_file_fuzzer.cc . ; cp ../../fuzzer_temp_file.h .

cd $current_dir

git clone https://github.com/OSGeo/PROJ.git
cd PROJ; git checkout d00501750b210a73f9fb107ac97a683d4e3d8e7a; git apply ../../PROJ-injection.patch;

cd $current_dir

git clone https://github.com/facebook/zstd.git
cd zstd; git checkout 9ad7ea44ec9644c618c2e82be5960d868e48745d; git apply ../../zstd-injection.patch;

cd $current_dir

####################
cd ..
python3 print_statements.py

export CC=clang; export CXX=clang++
export ADDITIONAL="-DFRCOV -ggdb -fsanitize=address"
export LDFLAGS=-lpthread

cd $current_dir

cd libxml2; 
./autogen.sh; make distclean; mkdir obj-aflgo
cd obj-aflgo;  CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --disable-shared --prefix=`pwd`
make clean; make V=1 CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL"
$CXX $ADDITIONAL -I./include/ -I../include/  \
     -c ../libxml2_xml_reader_for_file_fuzzer.cc  -o libxml2_xml_reader_for_file_fuzzer.o
$CXX $ADDITIONAL  .libs/libxml2.a libxml2_xml_reader_for_file_fuzzer.o SAX.o entities.o encoding.o error.o parserInternals.o parser.o tree.o hash.o list.o xmlIO.o xmlmemory.o uri.o valid.o xlink.o HTMLparser.o HTMLtree.o debugXML.o xpath.o xpointer.o xinclude.o nanohttp.o nanoftp.o catalog.o globals.o threads.o c14n.o xmlstring.o buf.o xmlregexp.o xmlschemas.o xmlschemastypes.o xmlunicode.o xmlreader.o relaxng.o dict.o SAX2.o xmlwriter.o legacy.o chvalid.o pattern.o xmlsave.o xmlmodule.o schematron.o xzlib.o  -ldl -lpthread -lz -lm -o libxml2_xml_reader_for_file_fuzzer


cd $current_dir
cd PROJ;
./autogen.sh; mkdir obj-aflgo
cd obj-aflgo;  CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" ../configure --prefix=`pwd`
make clean; make -k || true;
$CC $ADDITIONAL -DSTANDALONE -I ../src -c ../test/fuzzers/standard_fuzzer.c -o ../test/fuzzers/standard_fuzzer.o
$CC $ADDITIONAL -I ../src ../test/fuzzers/standard_fuzzer.o ./src/.libs/libproj.a -o ./standard_fuzzer -lpthread


cd $current_dir
cd zstd;
make distclean
make clean; cd tests/fuzz; LDFLAGS=-lpthread CC="$CC $ADDITIONAL" CXX="$CXX $ADDITIONAL" python3 fuzz.py build stream_decompress

cd $current_dir

cd ..

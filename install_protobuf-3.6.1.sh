#!/bin/bash

set -e

folder=${HOME}/src
mkdir -p $folder

echo "** Download protobuf-3.6.1 sources"
cd $folder
if [ ! -f protobuf-python-3.6.1.zip ]; then
  wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protobuf-python-3.6.1.zip
fi
if [ ! -f protoc-3.6.1-linux-aarch_64.zip ]; then
  wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protoc-3.6.1-linux-aarch_64.zip
fi

echo "** Install protoc"
unzip protobuf-python-3.6.1.zip
unzip protoc-3.6.1-linux-aarch_64.zip -d protoc-3.6.1
sudo cp protoc-3.6.1/bin/protoc /usr/local/bin/protoc

echo "** Build and install protobuf-3.6.1 libraries"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
cd protobuf-3.6.1/
./autogen.sh
./configure --prefix=/usr/local
make
make check
sudo make install
sudo ldconfig

echo "** Update python3 protobuf module"
# remove previous installation of python3 protobuf module
sudo pip3 uninstall -y protobuf
sudo pip3 install Cython
cd python/
# force compilation with c++11 standard
sed -i '205s/if v:/if True:/' setup.py
python3 setup.py build --cpp_implementation
python3 setup.py test --cpp_implementation
sudo python3 setup.py install --cpp_implementation

echo "** Build protobuf-3.6.1 successfully"

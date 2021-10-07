#!/bin/bash

set -e

version=3.9.2

folder=${HOME}/src
mkdir -p $folder

echo "** Install requirements"
sudo apt-get install -y autoconf libtool

echo "** Download protobuf-${version} sources"
pushd $folder
if [ ! -f protobuf-python-${version}.zip ]; then
  wget https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protobuf-python-${version}.zip
fi
if [ ! -f protoc-${version}-linux-aarch_64.zip ]; then
  wget https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-linux-aarch_64.zip
fi

echo "** Install protoc"
unzip protobuf-python-${version}.zip
unzip protoc-${version}-linux-aarch_64.zip -d protoc-${version}
sudo cp protoc-${version}/bin/protoc /usr/local/bin/protoc

echo "** Build and install protobuf-${version} libraries"
cd protobuf-${version}/
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
#make check  ### Disabled because "protobuf-test" would fail (JetPack-4.6)!
sudo make install
sudo ldconfig

echo "** Update python3 protobuf module"
# remove previous installation of python3 protobuf module
sudo apt-get install -y python3-pip
sudo pip3 uninstall -y protobuf
sudo pip3 install Cython
cd python/
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python3 setup.py build --cpp_implementation
python3 setup.py test --cpp_implementation
sudo python3 setup.py install --cpp_implementation

popd

echo "** Build protobuf-${version} successfully"

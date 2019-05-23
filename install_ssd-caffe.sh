#!/bin/bash

set -e

config_file=`pwd`/caffe/Makefile.config.nano
project_folder=${HOME}/project
mkdir -p $project_folder 

echo "** Install requirements"
sudo apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-dev libhdf5-serial-dev protobuf-compiler
sudo apt-get install -y --no-install-recommends libboost-all-dev
sudo apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
sudo apt-get install -y libatlas-base-dev libopenblas-dev

echo "** Download SSD caffe"
cd $project_folder 
git clone https://github.com/weiliu89/caffe.git ssd-caffe
cd ssd-caffe
git checkout ssd

echo "** Install python3 requirements"
# build python3 leveldb from source
pushd /tmp
wget https://pypi.python.org/packages/03/98/1521e7274cfbcc678e9640e242a62cbcd18743f9c5761179da165c940eac/leveldb-0.20.tar.gz
tar xzvf leveldb-0.20.tar.gz
cd leveldb-0.20
python3 setup.py build
sudo python3 setup.py install
popd
pkgs=`sed 's/[>=<].*$//' python/requirements.txt | grep -v leveldb | grep -v pyyaml`
for pkg in $pkgs; do sudo pip3 install $pkg; done

echo "** Building caffe..."
cp $config_file Makefile.config
make -j3 all test pycaffe

# NOTE: runtest fails on Jetson Nano due to out of memory
# make runtest

./build/tools/caffe time --gpu 0 --model ./models/bvlc_alexnet/deploy.prototxt

PYTHONPATH=`pwd`/python python3 -c "import caffe; print('caffe version: %s' % caffe.__version__)"

echo "** Build and test SSD caffe successfully"

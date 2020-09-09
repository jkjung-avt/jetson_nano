#!/bin/bash
#
# Reference: https://docs.bazel.build/versions/master/install-ubuntu.html#install-with-installer-ubuntu

set -e

folder=${HOME}/src
mkdir -p $folder

echo "** Install requirements"
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip
sudo apt-get install -y openjdk-8-jdk

echo "** Download bazel-3.1.0 sources"
pushd $folder
if [ ! -f bazel-3.1.0-dist.zip ]; then
  wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-dist.zip
fi

echo "** Build and install bazel-3.1.0"
unzip bazel-3.1.0-dist.zip -d bazel-3.1.0-dist
cd bazel-3.1.0-dist
EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

mkdir -p ${HOME}/bin
cp output/bazel ${HOME}/bin
if [[ ${PATH} != *${HOME}/bin* ]]; then
  export PATH=${HOME}/bin:${PATH}
fi
bazel help

popd

echo "** Build bazel-3.1.0 successfully"

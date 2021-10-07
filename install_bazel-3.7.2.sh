#!/bin/bash
#
# Reference: https://docs.bazel.build/versions/master/install-ubuntu.html#install-with-installer-ubuntu

set -e

version=3.7.2

folder=${HOME}/src
mkdir -p $folder

echo "** Install requirements"
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip
sudo apt-get install -y openjdk-8-jdk

echo "** Download bazel-${version} sources"
pushd $folder
if [ ! -f bazel-${version}-dist.zip ]; then
  wget https://github.com/bazelbuild/bazel/releases/download/${version}/bazel-${version}-dist.zip
fi

echo "** Build and install bazel-${version}"
unzip bazel-${version}-dist.zip -d bazel-${version}-dist
cd bazel-${version}-dist
EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

mkdir -p ${HOME}/bin
cp output/bazel ${HOME}/bin
if [[ ${PATH} != *${HOME}/bin* ]]; then
  export PATH=${HOME}/bin:${PATH}
fi
bazel help

popd

echo "** Build bazel-${version} successfully"

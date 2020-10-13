#!/bin/bash

set -e

if [[ $(head -1 /etc/nv_tegra_release) != *"R32 (release), REVISION: 4.3"* ]] ; then
  echo "ERROR: not JetPack-4.4"
  exit 1
fi

case $(cat /sys/module/tegra_fuse/parameters/tegra_chip_id) in
  "33" )  # Nano and TX1
    cuda_compute=5.3
    ;;
  "24" )  # TX2
    cuda_compute=6.2
    ;;
  "25" )  # Xavier NX and AGX Xavier
    cuda_compute=7.2
    ;;
  * )     # default
    cuda_compute=5.3,6.2,7.2
    ;;
esac

script_path=$(realpath $0)
patch_path=$(dirname $script_path)/tensorflow/tensorflow-2.3.0.patch
trt_version=$(echo /usr/lib/aarch64-linux-gnu/libnvinfer.so.? | cut -d '.' -f 3)

src_folder=${HOME}/src
mkdir -p $src_folder

if pip3 list | grep tensorflow > /dev/null; then
  echo "ERROR: tensorflow is installed already"
  exit 1
fi

if ! which bazel > /dev/null; then
  echo "ERROR: bazel has not been installled"
  exit 1
fi

echo "** Install requirements"
sudo apt-get install -y libhdf5-serial-dev hdf5-tools
sudo pip3 install -U pip six 'numpy<1.19.0' wheel setuptools mock 'future>=0.17.1' 'gast==0.3.3' typing_extensions h5py
sudo pip3 install -U keras_applications --no-deps
sudo pip3 install -U keras_preprocessing --no-deps

export LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

echo "** Download and patch tensorflow-2.3.0"
pushd $src_folder
if [ ! -f tensorflow-2.3.0.tar.gz ]; then
  wget https://github.com/tensorflow/tensorflow/archive/v2.3.0.tar.gz -O tensorflow-2.3.0.tar.gz
fi
tar xzvf tensorflow-2.3.0.tar.gz
cd tensorflow-2.3.0

patch -N -p1 < $patch_path && echo "tensorflow-2.3.0 source tree appears to be patched already.  Continue..."

echo "** Configure and build tensorflow-2.3.0"
export TMP=/tmp
PYTHON_BIN_PATH=$(which python3) \
PYTHON_LIB_PATH=$(python3 -c 'import site; print(site.getsitepackages()[0])') \
TF_CUDA_COMPUTE_CAPABILITIES=${cuda_compute} \
TF_CUDA_VERSION=10.2 \
TF_CUDA_CLANG=0 \
TF_CUDNN_VERSION=8 \
TF_TENSORRT_VERSION=${trt_version} \
CUDA_TOOLKIT_PATH=/usr/local/cuda \
CUDNN_INSTALL_PATH=/usr/lib/aarch64-linux-gnu \
TENSORRT_INSTALL_PATH=/usr/lib/aarch64-linux-gnu \
TF_NEED_IGNITE=0 \
TF_ENABLE_XLA=0 \
TF_NEED_OPENCL_SYCL=0 \
TF_NEED_COMPUTECPP=0 \
TF_NEED_ROCM=0 \
TF_NEED_CUDA=1 \
TF_NEED_TENSORRT=1 \
TF_NEED_OPENCL=0 \
TF_NEED_MPI=0 \
GCC_HOST_COMPILER_PATH=$(which gcc) \
CC_OPT_FLAGS="-march=native" \
TF_SET_ANDROID_WORKSPACE=0 \
    ./configure

bazel build --config=opt \
            --config=v2 \
            --config=cuda \
            --config=noaws \
            --local_cpu_resources=HOST_CPUS*0.25 \
            --local_ram_resources=HOST_RAM*0.5 \
            //tensorflow/tools/lib_package:libtensorflow

echo "** Build and install tensorflow-2.3.0 successfully"

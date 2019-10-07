#!/bin/bash

set -e

script_path=$(realpath $0)
patch_path=$(dirname $script_path)/tensorflow/tensorflow-2.0.0.patch

chip_id=$(cat /sys/module/tegra_fuse/parameters/tegra_chip_id)
case ${chip_id} in
  "33" )  # Nano and TX1
    cuda_compute=5.3
    ;;
  "24" )  # TX2
    cuda_compute=6.2
    ;;
  "25" )  # AGX Xavier
    cuda_compute=7.2
    ;;
  * )     # default
    cuda_compute=5.3,6.2,7.2
    ;;
esac

folder=${HOME}/src
mkdir -p $folder

if pip3 list | grep tensorflow > /dev/null; then
  echo "ERROR: tensorflow is installed already"
  exit
fi

if ! which bazel > /dev/null; then
  echo "ERROR: bazel has not been installled"
  exit
fi

echo "** Install requirements"
sudo apt-get install -y libhdf5-serial-dev hdf5-tools
sudo pip3 install -U pip six numpy wheel setuptools mock h5py
sudo pip3 install -U keras_applications
sudo pip3 install -U keras_preprocessing

export LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

echo "** Download and patch tensorflow-2.0.0"
pushd $folder
if [ ! -f tensorflow-2.0.0.tar.gz ]; then
  wget https://github.com/tensorflow/tensorflow/archive/v2.0.0.tar.gz -O tensorflow-2.0.0.tar.gz
fi
tar xzvf tensorflow-2.0.0.tar.gz
cd tensorflow-2.0.0

patch -N -p1 < $patch_path && echo "tensorflow-2.0.0 source tree appears to be patched already.  Continue..."

echo "** Configure and build tensorflow-2.0.0"
export TMP=/tmp
PYTHON_BIN_PATH=$(which python3) \
PYTHON_LIB_PATH=$(python3 -c 'import site; print(site.getsitepackages()[0])') \
TF_CUDA_COMPUTE_CAPABILITIES=${cuda_compute} \
TF_CUDA_VERSION=10.0 \
TF_CUDA_CLANG=0 \
TF_CUDNN_VERSION=7 \
TF_TENSORRT_VERSION=5.0.6 \
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
	    --config=cuda \
	    --local_resources=2048.0,1.0,1.0 \
            //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package wheel/tensorflow_pkg

echo "** Install tensorflow-2.0.0"
#sudo pip3 install wheel/tensorflow_pkg/tensorflow-2.0.0-cp36-cp36m-linux_aarch64.whl
sudo pip3 install wheel/tensorflow_pkg/tensorflow-2.0.0-*.whl

popd
TF_CPP_MIN_LOG_LEVEL=3 python3 -c "import tensorflow as tf; tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR); print('tensorflow version: %s' % tf.__version__); print('tensorflow.test.is_built_with_cuda(): %s' % tf.test.is_built_with_cuda()); print('tensorflow.test.is_gpu_available(): %s' % tf.test.is_gpu_available(cuda_only=False, min_cuda_compute_capability=None))"

echo "** Build and install tensorflow-2.0.0 successfully"

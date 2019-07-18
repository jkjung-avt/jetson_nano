#!/bin/bash
#
# Copyright (c) 2018, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
#

# The orginal script 'install_opencv4.0.0_Nano.sh' could be found here:
# https://github.com/AastaNV/JEP/blob/master/script/install_opencv4.0.0_Nano.sh
#
# I did some modification so that it installs opencv-3.4.6 instead.  Refer
# to my blog posts for more details.
#
# JK Jung, jkjung13@gmail.com

set -e

folder=${HOME}/src
mkdir -p $folder

echo "** Purge old opencv installation"
sudo apt-get purge -y libopencv*

echo "** Install requirements"
sudo apt-get update
sudo apt-get install -y build-essential make cmake cmake-curses-gui git g++ pkg-config curl
sudo apt-get install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libeigen3-dev libglew-dev libgtk2.0-dev
sudo apt-get install -y libtbb2 libtbb-dev libv4l-dev v4l-utils qv4l2 v4l2ucp
sudo apt-get install -y libdc1394-22-dev libxine2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
# sudo apt-get install -y libjasper-dev
sudo apt-get install -y libjpeg8-dev libjpeg-turbo8-dev libtiff-dev libpng-dev
sudo apt-get install -y libxvidcore-dev libx264-dev libgtk-3-dev
sudo apt-get install -y libatlas-base-dev libopenblas-dev liblapack-dev liblapacke-dev gfortran
sudo apt-get install -y qt5-default

sudo apt-get install -y python2.7-dev python3.6-dev python3-testresources
rm -f $folder/get-pip.py
wget https://bootstrap.pypa.io/get-pip.py -O $folder/get-pip.py
sudo python3 $folder/get-pip.py
sudo python2 $folder/get-pip.py
sudo pip3 install protobuf
sudo pip2 install protobuf
sudo pip3 install -U numpy matplotlib
sudo pip2 install -U numpy matplotlib

if [ ! -f /usr/local/cuda/include/cuda_gl_interop.h.bak ]; then
  sudo cp /usr/local/cuda/include/cuda_gl_interop.h /usr/local/cuda/include/cuda_gl_interop.h.bak
fi
sudo patch -N /usr/local/cuda/include/cuda_gl_interop.h < opencv/cuda_gl_interop.h.patch && echo "** '/usr/local/cuda/include/cuda_gl_interop.h' appears to be patched already.  Continue..."

echo "** Download opencv-3.4.6"
cd $folder
if [ ! -f opencv-3.4.6.zip ]; then
  wget https://github.com/opencv/opencv/archive/3.4.6.zip -O opencv-3.4.6.zip
fi
if [ -d opencv-3.4.6 ]; then
  echo "** ERROR: opencv-3.4.6 directory already exists"
  exit
fi
unzip opencv-3.4.6.zip 
cd opencv-3.4.6/

echo "** Building opencv..."
mkdir build
cd build/

cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=ON -D CUDA_ARCH_BIN="5.3" -D CUDA_ARCH_PTX="" -D WITH_CUBLAS=ON -D ENABLE_FAST_MATH=ON -D CUDA_FAST_MATH=ON -D ENABLE_NEON=ON -D WITH_GSTREAMER=ON -D WITH_LIBV4L=ON -D BUILD_opencv_python2=ON -D BUILD_opencv_python3=ON -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_EXAMPLES=OFF -D WITH_QT=ON -D WITH_OPENGL=ON ..
make -j3
sudo make install
sudo ldconfig

python3 -c 'import cv2; print("python3 cv2 version: %s" % cv2.__version__)'
python2 -c 'import cv2; print("python2 cv2 version: %s" % cv2.__version__)'

echo "** Install opencv-3.4.6 successfully"

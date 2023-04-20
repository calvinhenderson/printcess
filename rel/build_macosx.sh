#!/bin/bash

# Exit immediately on error
set -ueo pipefail

arch="x86_64"

# Support macOS Monterey and upwards
export MACOSX_DEPLOYMENT_TARGET=12.1
export CFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET -O2"
export CXXFLAGS="$CFLAGS"

# Parse command line arguments for Elixir and OTP versions
while getopts ":e:o:" opt; do
  case $opt in
    e)
      ELIXIR_VERSION="$OPTARG"
      ;;
    o)
      OTP_VERSION="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Set default versions if not provided via command line arguments
ELIXIR_VERSION=${ELIXIR_VERSION:-"1.14.3"}
OTP_VERSION=${OTP_VERSION:-"25.3"}

# Set build directory
BUILD_DIR=$(pwd)/_build

# Create build directory if it does not exist
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clone OpenSSL from GitHub and build static libs
openssl_rel_dir=$BUILD_DIR/openssl-rel-1.1.1-$arch
if [ ! -d $openssl_rel_dir ]; then
  if [ ! -d $BUILD_DIR/openssl_src ]; then
    echo " * pulling OpenSSL from GitHub."
    git clone --depth 1 --branch OpenSSL_1_1_1 https://github.com/openssl/openssl.git openssl_src
  else
    echo " * source exists for OpenSSL. skipping."
  fi
  echo " * building OpenSSL."

  cd openssl_src
  ./Configure darwin64-x86_64-cc --prefix=$openssl_rel_dir
  make -j 4
  make install_sw
  cd ..
else
  echo " * skipping OpenSSL. release already exists."
fi

wxwidgets_rel_dir=$BUILD_DIR/wxwidgets-rel-3_2_2-$arch
if [ ! -d $wxwidgets_rel_dir ] || [ ! -f $wxwidgets_rel_dir/bin/wx-config ]; then
  # Clone wxWidgets from GitHub with x86_64 architecture
  if [ ! -d $BUILD_DIR/wxwidgets_src ]; then
    echo " * pulling wxWidgets from GitHub."
    git clone --depth 1 --branch v3.2.2 https://github.com/wxWidgets/wxWidgets.git $BUILD_DIR/wxwidgets_src
    pushd wxwidgets_src/src
    git submodule update --init --recursive
    popd
  else
    echo " * source exists for wxWidgets. skipping."
  fi

  echo " * building wxWidgets."

  rm -rf $wxwidgets_rel_dir
  mkdir -p $wxwidgets_rel_dir

  cd wxwidgets_src

  mkdir -p build && cd build

  ../configure \
	  --prefix=$wxwidgets_rel_dir \
	  --with-osx_cocoa \
	  --with-macosx-version-min=$MACOSX_DEPLOYMENT_TARGET \
	  --with-macosx-sdk=/Library/Developer/CommandLineTools/SDKs/MacOSX12.1.sdk \
	  --with-libtiff=builtin \
	  --with-zlib=builtin \
	  --with-expat=builtin \
	  --disable-debug \
	  --disable-debug_flag \
	  --disable-monolithic \
	  --disable-shared \
	  --enable-unicode \
	  --enable-webview \
	  --enable-macosx-arch=x86_64

  make -j 4
  make install
  cd ..
else
  echo " * skipping wxWidgets. release already exists."
fi

echo " * putting wx-config in the shell path."
export PATH=$wxwidgets_rel_dir/bin:$PATH

BUILD_ELIXIR=0
# Clone Erlang OTP from GitHub and initialize submodules
erlang_release_dir="$BUILD_DIR/erlang-otp-$(echo "$OTP_VERSION" | tr '.' '_')-$arch"
if [ ! -d $erlang_release_dir ]; then
  if [ ! -d erlang_otp_src ]; then
    echo " * pulling Erlang/OTP from GitHub."
    git clone https://github.com/erlang/otp.git erlang_otp_src
  else
    echo " * source exists for Erlang/OTP. skipping."
  fi

  echo " * building Erlang/OTP $OTP_VERSION."

  cd erlang_otp_src
  # ./otp_build autoconf # no longer required.

  echo " * switching branches."
  git checkout tags/OTP-$OTP_VERSION

  echo " * updating git submodules."
  git submodule update --init --recursive

  # Configure and build Erlang OTP with static linking of OpenSSL and wxWidgets
  ./configure \
	  --without-javac \
	  --without-fop \
	  --with-ssl=$openssl_rel_dir \
	  --with-wx-config=$wxwidgets_rel_dir/bin/wx-config \
	  --disable-dynamic-ssl-lib \
	  --disable-jit \
	  --enable-static-libs \
	  --enable-wx \
	  --prefix=$erlang_release_dir \
	  --host=x86_64-apple-darwin

  make clean
  make -j 4
  make install

  cd ..
  export BUILD_ELIXIR=1
else
  echo " * skipping Erlang/OTP. release already exists."
fi

# Add Erlang OTP to PATH
export PATH=$erlang_release_dir/bin:$PATH

echo " * which erl: $(which erl)"
erl -s erlang halt

# Clone Elixir from GitHub and set the version
elixir_release_dir=elixir-rel-otp-$OTP_VERSION
if [ ! -d $elixir_release_dir ] || [ $BUILD_ELIXIR -ne 0 ]; then
  if [ ! -d elixir_src ]; then
    echo " * pulling Elixir from GitHub."
    git clone https://github.com/elixir-lang/elixir.git --depth 1 --branch v$ELIXIR_VERSION elixir_src
  else
    echo " * source exists for Elixir. skipping."
  fi

  cd elixir_src

  # Build Elixir
  make clean
  make PREFIX=$elixir_release_dir -j 4 install
else
  echo " * skipping Elixir. release already exists."
fi

# Set Elixir as a portable installation
export PATH=$(pwd)/bin:$PATH

# Verify Elixir and Erlang versions
echo " * built."
elixir --version

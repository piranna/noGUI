#!/usr/bin/env bash

if [[ -z $JOBS ]]; then
  JOBS=$((`getconf _NPROCESSORS_ONLN` + 1))
fi

MAKE="make --jobs=$JOBS"
QMAKE=`pwd`/build/qtbase/bin/qmake


# Clean object dir and return the input error
function err(){
  rm -rf $OUT_DIR
  rmdir -p --ignore-fail-on-non-empty `dirname $OUT_DIR`
  exit $1
}


# ICU

ICU_URL=http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.tgz
SRC_DIR=`pwd`/deps/icu
OUT_DIR=`pwd`/build/icu

if [[ ! -d $SRC_DIR ]]; then
  mkdir -p $SRC_DIR                                             &&
  curl -L $ICU_URL | tar xzf - -C $SRC_DIR --strip-components=1 || exit 1
fi

if [[ ! -d $OUT_DIR ]]; then
  rm -rf `pwd`/build/qtbase

  rm   -rf ${OUT_DIR}_obj &&
  mkdir -p ${OUT_DIR}_obj || exit 3

  (
    cd ${OUT_DIR}_obj || exit 4

    SRC_DIR=$SRC_DIR/source

    $SRC_DIR/configure    \
        --prefix=$OUT_DIR \
        --enable-static   \
        --disable-tests   \
        --disable-samples || exit 5
#        --disable-shared  \

#    $MAKE || exit 6
    $MAKE        &&
    make install || exit 6
  ) || err $?

  rm -rf ${OUT_DIR}_obj || exit 7
fi

ICU_LIB=$OUT_DIR/lib
ICU_INC=$OUT_DIR/include

export LD_LIBRARY_PATH=$ICU_LIB


# qtbase

SRC_DIR=`pwd`/deps/qtbase
OUT_DIR=`pwd`/build/qtbase

if [[ ! -d $SRC_DIR ]]; then
  git clone git://code.qt.io/qt/qtbase.git $SRC_DIR || exit 10
fi

if [[ ! -d $OUT_DIR ]]; then
  rm -rf `pwd`/build/qtwebkit

  mkdir -p $OUT_DIR || exit 11

  (
    cd $OUT_DIR || exit 12

    $SRC_DIR/configure   \
        -prefix $OUT_DIR \
        -opensource      \
        -confirm-license \
        -static          \
        -no-sql-sqlite   \
        -no-pkg-config   \
        -qt-zlib         \
        -qt-libpng       \
        -qt-libjpeg      \
        -qt-freetype     \
        -qt-pcre         \
        -nomake examples \
        -nomake tests    \
        -nomake tools    \
        -no-qml-debug    \
        -silent          \
        -no-fontconfig   \
        -no-dbus         \
        -icu -continue   \
        -L $ICU_LIB      \
        -I $ICU_INC      \
        -qt-xcb          \
        -linuxfb         || exit 13
#        -no-xcb          \

    $MAKE || exit 14
  ) || err $?
fi

export SQLITE3SRCDIR=$SRC_DIR/src/3rdparty/sqlite

export CMAKE_LIBRARY_PATH=$ICU_LIB
export CMAKE_INCLUDE_PATH=$ICU_INC


# qtwebkit

SRC_DIR=`pwd`/deps/qtwebkit
OUT_DIR=`pwd`/build/qtwebkit

if [[ ! -d $SRC_DIR ]]; then
  git clone git://code.qt.io/qt/qtwebkit.git $SRC_DIR || exit 20
fi

if [[ ! -d $OUT_DIR ]]; then
  rm -rf `pwd`/build/nogui

  mkdir -p $OUT_DIR || exit 21

  (
    cd $OUT_DIR || exit 22

    $QMAKE -config release $SRC_DIR || exit 23

    $MAKE || exit 24
  ) || err $?
fi


# noGUI

SRC_DIR=`pwd`
OUT_DIR=`pwd`/build/nogui

#if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR || exit 30

  (
    cd $OUT_DIR || exit 31

    $QMAKE -config release $SRC_DIR || exit 32

    $MAKE || exit 33
  ) || err $?
#fi

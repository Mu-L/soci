#!/usr/bin/env bash
# Builds SOCI "empty" backend in CI builds
#
# Copyright (c) 2013 Mateusz Loskot <mateusz@loskot.net>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

run_cmake_for_empty()
{
    cmake ${SOCI_DEFAULT_CMAKE_OPTIONS} \
        -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD:-11} \
        -DSOCI_EMPTY=ON \
        ..
}

build_example()
{
  cmake -S "../examples/$1" -B "$1"
  cmake --build "$1"
}

run_cmake_for_empty
run_make

if [[ "$BUILD_EXAMPLES" == "YES" ]]; then
  # This example simulates SOCI sources being embedded in the project dir
  build_example subdir-include

  # Install previously built SOCI library on the system
  sudo make install

  # This example simulates SOCI being installed on the target system
  build_example connect
fi

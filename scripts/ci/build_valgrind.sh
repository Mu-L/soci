#!/usr/bin/env bash
# Builds SOCI for use with Valgrind in CI builds
#
# Copyright (c) 2013 Mateusz Loskot <mateusz@loskot.net>
# Copyright (c) 2015 Sergei Nikulov <sergey.nikulov@gmail.com>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# Note that we don't use the default options here, as we don't want to turn
# off all the backends. We also have to disable the sanitizers which are
# enabled for all the other builds, as ASAN is incompatible with Valgrind and
# UBSAN is not useful when running under it.
cmake ${SOCI_COMMON_CMAKE_OPTIONS} \
    -DSOCI_ASAN=OFF \
    -DSOCI_UBSAN=OFF \
    -DSOCI_ODBC=OFF \
    ..

run_make

#!/usr/bin/env bash
# Builds SOCI ODBC backend for testing with MS SQL Server in CI builds
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# Disable ASAN -> see https://github.com/SOCI/soci/issues/1008
cmake ${SOCI_DEFAULT_CMAKE_OPTIONS} \
    -DSOCI_ASAN=OFF \
    -DSOCI_ODBC=ON \
    -DSOCI_ODBC_TEST_MSSQL_CONNSTR:STRING="$(mssql_connstr)" \
    ..

run_make

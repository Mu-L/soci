#!/usr/bin/env bash
# Tests SOCI ODBC backend with MS SQL Server in CI builds
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# Only the MS SQL test can be run here, the other ODBC tests are built but
# require the databases which are not available in this job.
LSAN_OPTIONS=suppressions=${SOCI_SOURCE_DIR}/scripts/suppressions/lsan-odbc run_test -R soci_odbc_test_mssql

#!/usr/bin/env bash
# Install the dependencies of all the backends built by build_all.sh
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# Note that we only need the client libraries here, and not the database
# servers themselves, as this build doesn't run any tests using them.
#
# Oracle is not installed because we'd need the server just to get the client
# headers and libraries.

# Remove buggy versions of the ODBC packages from Microsoft repositories as
# well as their dependencies, just as install_odbc.sh does.
run_apt remove \
    libodbc1 odbcinst1debian2 \
    unixodbc unixodbc-dev

run_apt install \
    firebird-dev \
    libmysqlclient-dev \
    libpq-dev \
    libsqlite3-dev \
    unixodbc-dev

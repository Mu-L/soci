#!/usr/bin/env bash
# Builds SOCI with all backends.
#
# Copyright (c) 2021 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# We don't use the default options here, as we don't want to turn off all the
# backends, but rather enable all of those for which install_all.sh installs
# the dependencies -- which doesn't include DB2 and Oracle, so these two are
# explicitly disabled.
#
# Note that the backends are enabled explicitly, and not left at their default
# "AUTO" value, in order to fail if any of them can't be built instead of just
# silently skipping it.
#
# Also note that ASAN has to be disabled because of the problems with it when
# using ODBC, see https://github.com/SOCI/soci/issues/1008.
#
# Finally, we don't run the tests for most of the backends here, as doing it
# would require setting up all the database servers, so we don't even build
# them, with the exception of the SQLite3 tests which don't need any server at
# all and so allow us to check that the library actually works.
run_cmake_for_all()
{
    cmake ${SOCI_COMMON_CMAKE_OPTIONS} \
        -DSOCI_ASAN=OFF \
        -DSOCI_DB2=OFF \
        -DSOCI_EMPTY=OFF \
        -DSOCI_FIREBIRD=ON \
        -DSOCI_FIREBIRD_SKIP_TESTS=ON \
        -DSOCI_MYSQL=ON \
        -DSOCI_MYSQL_SKIP_TESTS=ON \
        -DSOCI_ODBC=ON \
        -DSOCI_ODBC_SKIP_TESTS=ON \
        -DSOCI_ORACLE=OFF \
        -DSOCI_POSTGRESQL=ON \
        -DSOCI_POSTGRESQL_SKIP_TESTS=ON \
        -DSOCI_SQLITE3=ON \
        ..
}

run_cmake_for_all
run_make

# Test release branch packaging and building from the package
if [[ "$TEST_RELEASE_PACKAGE" == "YES" ]] && [[ "$SOCI_CI_BRANCH" =~ ^release/[3-9]\.[0-9]$ ]]; then
    ME=`basename "$0"`

    run_apt update
    run_apt install python3-venv

    SOCI_VERSION=$(cat "$SOCI_SOURCE_DIR/include/soci/version.h" | grep -Po "(.*#define\s+SOCI_LIB_VERSION\s+.+)\K([3-9]_[0-9]_[0-9])" | sed "s/_/\./g")
    if [[ ! "$SOCI_VERSION" =~ ^[4-9]\.[0-9]\.[0-9]$ ]]; then
        echo "${ME} ERROR: Invalid format of SOCI version '$SOCI_VERSION'. Aborting."
        exit 1
    else
        echo "${ME} INFO: Creating source package 'soci-${SOCI_VERSION}.tar.gz' from '$SOCI_CI_BRANCH' branch"
    fi

    cd $SOCI_SOURCE_DIR
    $SOCI_SOURCE_DIR/scripts/release.sh --use-local-branch $SOCI_CI_BRANCH

    if [[ ! -f "soci-${SOCI_VERSION}.tar.gz" ]]; then
        echo "${ME} ERROR: Archive file 'soci-${SOCI_VERSION}.tar.gz' not found. Aborting."
        exit 1
    fi

    echo "${ME} INFO: Unpacking source package 'soci-${SOCI_VERSION}.tar.gz'"
    tar -xzf soci-${SOCI_VERSION}.tar.gz

    echo "${ME} INFO: Building SOCI from source package 'soci-${SOCI_VERSION}.tar.gz'"
    cd soci-${SOCI_VERSION}
    mkdir _build
    echo $PWD

    run_cmake_for_all
    run_make
    run_test
fi

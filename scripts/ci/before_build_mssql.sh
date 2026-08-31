#!/usr/bin/env bash
# Sets up MS SQL Server database for SOCI in CI builds
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

echo "Creating the ${MSSQL_DB} database:"
echo "create database ${MSSQL_DB}" | mssql_sql master

echo 'Testing connection to the database:'
echo 'select @@version, db_name(), suser_name()' | mssql_sql

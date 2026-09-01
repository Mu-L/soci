# Definitions used by SOCI when testing MS SQL Server in CI builds
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
# Notice that this file is not executable, it is supposed to be sourced from
# the other files.

# Docker image used for the server, override it to test with another version.
: ${SOCI_MSSQL_IMAGE:=mcr.microsoft.com/mssql/server:2025-latest}

# This is arbitrary.
export MSSQL_CONTAINER=soci-mssql

# "sa" is the only account existing in a freshly created container and the
# password must satisfy the (not configurable) SQL Server password policy.
export MSSQL_USER=sa
export MSSQL_PASSWORD='Password12!'

# Database created by before_build_mssql.sh and used by the tests.
export MSSQL_DB=soci_test

# ODBC driver to use.
case "${SOCI_MSSQL_DRIVER}" in
    msodbcsql18)
        # This driver uses the "host,port" syntax and refuses to connect to the
        # server using the self-signed certificate unless explicitly told to.
        mssql_odbc_driver='ODBC Driver 18 for SQL Server'
        mssql_odbc_server='SERVER=127.0.0.1,1433;TrustServerCertificate=yes'
        ;;

    freetds)
        # This one uses a separate PORT. Specifying the protocol version is
        # not really required, as it defaults to "auto" since FreeTDS 1.0, but
        # pinning it avoids the round trips of the version negotiation.
        mssql_odbc_driver='FreeTDS'
        mssql_odbc_server='SERVER=127.0.0.1;PORT=1433;TDS_Version=7.4'
        ;;

    '')
        echo "SOCI_MSSQL_DRIVER must be set in the CI script." >&2
        exit 1
        ;;

    *)
        echo "Unknown MS SQL ODBC driver \"${SOCI_MSSQL_DRIVER}\"." >&2
        exit 1
esac

# Return the ODBC connection string for the database given as the argument or
# for the database used by the tests if it is not specified.
mssql_connstr()
{
    echo "DRIVER={${mssql_odbc_driver}};${mssql_odbc_server};DATABASE=${1:-${MSSQL_DB}};UID=${MSSQL_USER};PWD=${MSSQL_PASSWORD}"
}

# Execute the SQL statements given on stdin using the ODBC driver being tested,
# connecting to the database given as the argument (or the test one by default).
mssql_sql()
{
    # Note that isql exit code is 0 even if the SQL statements failed, so we
    # have to also examine its output to detect the errors.
    if ! mssql_sql_output=$(isql -b -v -k "$(mssql_connstr "$@")" 2>&1); then
        echo "${mssql_sql_output}"
        return 1
    fi

    echo "${mssql_sql_output}"

    case "${mssql_sql_output}" in
        *'[ISQL]ERROR'*)
            return 1
            ;;
    esac

    return 0
}

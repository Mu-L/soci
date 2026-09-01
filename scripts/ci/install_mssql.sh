#!/usr/bin/env bash
# Install MS SQL Server and the ODBC driver for it for SOCI in CI builds
#
# Copyright (c) 2026 Vadim Zeitlin <vz-soci@zeitlins.org>
#
source ${SOCI_SOURCE_DIR}/scripts/ci/common.sh

# Start the server first, as it takes a while to become available, and install
# the client side packages while it's starting up: we can't wait for it before
# doing it anyhow, as we use isql from unixODBC to check for its availability.
docker run --name ${MSSQL_CONTAINER} --detach --publish 1433:1433 \
    --env ACCEPT_EULA=Y --env MSSQL_SA_PASSWORD="${MSSQL_PASSWORD}" \
    ${SOCI_MSSQL_IMAGE}

# Remove buggy versions of the packages from Microsoft repositories as well as
# their dependencies (which include the MS ODBC driver, if it is preinstalled,
# but we reinstall it below if we need it).
run_apt remove \
    libodbc1 odbcinst1debian2 \
    unixodbc unixodbc-dev

packages_to_install="unixodbc unixodbc-dev"

if [ -z "$DEBUGINFOD_URLS" ]; then
    packages_to_install="$packages_to_install unixodbc-dbgsym"
fi

case "${SOCI_MSSQL_DRIVER}" in
    freetds)
        packages_to_install="$packages_to_install tdsodbc"
        ;;
esac

run_apt install ${packages_to_install}

case "${SOCI_MSSQL_DRIVER}" in
    msodbcsql18)
        # This driver is only available from the Microsoft repository, so add
        # it, but pin all the packages in it to a lower than default priority
        # to ensure that we keep using the distribution versions of unixODBC
        # packages removed above.
        sudo mkdir -p /etc/apt/keyrings
        wget -q -O - https://packages.microsoft.com/keys/microsoft.asc | \
            sudo tee /etc/apt/keyrings/microsoft.asc > /dev/null

        ubuntu_release=$(lsb_release --release --short)
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/ubuntu/${ubuntu_release}/prod $(lsb_release --codename --short) main" | \
            sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

        printf 'Package: *\nPin: origin packages.microsoft.com\nPin-Priority: 400\n' | \
            sudo tee /etc/apt/preferences.d/microsoft > /dev/null

        run_apt update

        # Installing this package requires accepting the EULA and run_apt
        # doesn't preserve the environment, so run apt-get directly here.
        sudo ACCEPT_EULA=Y apt-get $SOCI_APT_OPTIONS install msodbcsql18
        ;;

    freetds)
        # The package registers the driver with unixODBC on its own, but does
        # it using just the library name and not its full path, which can
        # result in "Can't open lib 'libtdsodbc.so' : file not found" errors,
        # so register it again using the full path to be on the safe side.
        tdsodbc_lib=$(dpkg -L tdsodbc | grep -F 'libtdsodbc.so')
        tdsodbc_ini=$(mktemp)
        sed -e "s@^Driver.*=.*@Driver=${tdsodbc_lib}@" \
            /usr/share/tdsodbc/odbcinst.ini > ${tdsodbc_ini}
        sudo odbcinst -i -d -f ${tdsodbc_ini}
        rm ${tdsodbc_ini}
        ;;
esac

echo 'Available ODBC drivers:'
echo '---------------------------------- >8 --------------------------------------'
odbcinst -q -d
echo '---------------------------------- >8 --------------------------------------'

echo 'Waiting for SQL Server startup...'
num_tries=1
wait_time=3 # seconds
while true; do
    if echo 'select @@version' | mssql_sql master > /dev/null 2>&1; then
        echo 'SQL Server is available now'
        break
    fi

    if [[ $num_tries -gt 60 ]]; then
        echo 'Timed out waiting for SQL Server startup, server log follows:'
        docker logs ${MSSQL_CONTAINER}
        exit 1
    fi

    sleep $wait_time
    ((num_tries++))
done

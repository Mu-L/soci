#ifndef SOCI_TESTS_MYSQL_H_INCLUDED
#define SOCI_TESTS_MYSQL_H_INCLUDED

#include "test-context.h"

using namespace soci;
using namespace soci::tests;

// DDL Creation objects for common tests
struct table_creator_one : public table_creator_base
{
    table_creator_one(soci::session & sql)
        : table_creator_base(sql)
    {
        sql << "create table soci_test(id integer, val integer, c char, "
                 "str varchar(20), sh int2, ll bigint, ul bigint unsigned, "
                 "d float8, num76 numeric(7,6), "
                 "tm datetime, i1 integer, i2 integer, i3 integer, "
                 "name varchar(20)) engine=InnoDB";
    }
};

struct table_creator_two : public table_creator_base
{
    table_creator_two(soci::session & sql)
        : table_creator_base(sql)
    {
        sql  << "create table soci_test(num_float float8, num_int integer,"
                     " name varchar(20), sometime datetime, chr char)";
    }
};

struct table_creator_three : public table_creator_base
{
    table_creator_three(soci::session & sql)
        : table_creator_base(sql)
    {
        sql << "create table soci_test(name varchar(100) not null, "
            "phone varchar(15))";
    }
};

struct table_creator_for_get_affected_rows : table_creator_base
{
    table_creator_for_get_affected_rows(soci::session & sql)
        : table_creator_base(sql)
    {
        sql << "create table soci_test(val integer)";
    }
};

struct table_creator_for_blob : public tests::table_creator_base
{
    table_creator_for_blob(soci::session & sql)
        : tests::table_creator_base(sql)
    {
        sql << "create table soci_test(id integer, b blob)";
    }
};


//
// Support for SOCI Common Tests
//

class test_context : public test_context_common
{
public:
    test_context() = default;

    std::string get_example_connection_string() const override
    {
        return "dbname=test user=root password=\'Ala ma kota\'";
    }

    std::string get_backend_name() const override
    {
        return "mysql";
    }

    table_creator_base* table_creator_1(soci::session& s) const override
    {
        return new table_creator_one(s);
    }

    table_creator_base* table_creator_2(soci::session& s) const override
    {
        return new table_creator_two(s);
    }

    table_creator_base* table_creator_3(soci::session& s) const override
    {
        return new table_creator_three(s);
    }

    table_creator_base* table_creator_4(soci::session& s) const override
    {
        return new table_creator_for_get_affected_rows(s);
    }

    std::string to_date_time(std::string const &datdt_string) const override
    {
        return "\'" + datdt_string + "\'";
    }

    table_creator_base * table_creator_blob(soci::session &s) const override
    {
        return new table_creator_for_blob(s);
    }

    bool has_fp_bug() const override
    {
        // MySQL fails in the common test3() with "1.8000000000000000 !=
        // 1.7999999999999998", so don't use exact doubles comparisons for it.
        return true;
    }

    bool has_transactions_support(soci::session& sql) const override
    {
        sql << "drop table if exists soci_test";
        sql << "create table soci_test (id int) engine=InnoDB";
        row r;
        sql << "show table status like \'soci_test\'", into(r);
        bool retv = (r.get<std::string>(1) == "InnoDB");
        sql << "drop table soci_test";
        return retv;
    }

    bool has_silent_truncate_bug(soci::session& sql) const override
    {
        std::string sql_mode;
        sql << "select @@session.sql_mode", into(sql_mode);

        // The database must be configured to use STRICT_{ALL,TRANS}_TABLES in
        // SQL mode to avoid silent truncation of too long values.
        return sql_mode.find("STRICT_") == std::string::npos;
    }

    bool enable_std_char_padding(soci::session& sql) const override
    {
        // turn on standard right padding on mysql. This options is supported as of version 5.1.20
        try
        {
            sql << "SET @@session.sql_mode = 'PAD_CHAR_TO_FULL_LENGTH'";
            return true;
        }
        catch(const soci_error&)
        {
            // Padding cannot be enabled - test will not be performed
            return false;
        }
    }

    std::string sql_length(std::string const& s) const override
    {
        return "char_length(" + s + ")";
    }
};

#endif // SOCI_TESTS_MYSQL_H_INCLUDED

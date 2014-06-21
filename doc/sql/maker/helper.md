# NAME

SQL::Maker::Helper - helper functions for SQL::Maker

# SYNOPSIS

    include SQL::Maker::Helper
    sql_raw('WHERE `id` = ?' => [1])

# DESCRIPTION

This module is to to provide sql_xxx helper functions. 

# FUNCTIONS

Following functions will be available by `include SQL::Maker::Helper`: 

* sql_raw
* sql_op
* sql_is_null
* sql_is_not_null
* sql_eq
* sql_ne
* sql_lt
* sql_gt
* sql_le
* sql_ge
* sql_like
* sql_between
* sql_not_between
* sql_not
* sql_and
* sql_or
* sql_in
* sql_not_in
* sql_not_in

and

* sql_union
* sql_union_all
* sql_intersect
* sql_intersect_all
* sql_except
* sql_except_all

Please see [SQL::QueryMaker](../query_maker.md)
and [SQL::Maker::SelectSet](./select_set.md) for details.

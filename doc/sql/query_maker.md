# NAME

SQL::QueryMaker - helper functions for SQL query generation

# SYNOPSIS

    include SQL::Maker::Helper # adds `sql_eq`, etc
    
    query = sql_eq(:foo => v)
    query.as_sql                 # `foo`=?
    query.bind                   # (v)

    query = sql_lt(:foo => v)
    query.as_sql                 # `foo`<?
    query.bind                   # (v)

    query = sql_in(:foo => [
        v1, v2, v3,
    ])
    query.as_sql                 # `foo` IN (?,?,?)
    query.bind                   # (v1,v2,v3)

    query = sql_and(:foo => [
        sql_ge(min),
        sql_lt(max)
    ])
    query.as_sql                 # `foo`>=? AND `foo`<?
    query.bind                   # (min,max)

    query = sql_and([
        sql_eq(:foo => v1),
        sql_eq(:bar => v2)
    ]
    query.as_sql                 # `foo`=? AND `bar`=?
    query.bind                   # (v1,v2)

    query = sql_and([
        :foo => v1,
        :bar => sql_lt(v2),
    ])
    query.as_sql                 # `foo`=? AND `bar`<?
    query.bind                   # (v1,v2)

    query = sql_raw('COUNT(*)')
    query.as_asl                 # COUNT(*)
    query.bind                   # []

    query = sql_raw('SELECT * FROM t WHERE id=?',123)
    query.as_sql                 # SELECT * FROM t WHERE id=?
    query.bind                   # [123]

# DESCRIPTION

This module concentrates on providing an expressive, concise way to declare SQL
expressions by exporting carefully-designed functions.
It is possible to use the module to generate SQL query conditions and pass them
as arguments to other more versatile query builders such as SQL::Maker.

The functions exported by the module instantiate comparator objects that build
SQL expressions when their as_sql method are being invoked.
There are two ways to specify the names of the columns to the comparator; to
pass in the names as argument or to specify then as an argument to the
as_sql method.

# FUNCTIONS

### sql_eq([column,] value)
### sql_eq(column => value)

### sql_lt([column,] value)
### sql_lt(column => value)

### sql_gt([column,] value)
### sql_gt(column => value)

### sql_le([column,] value)
### sql_le(column => value)

### sql_ge([column,] value)
### sql_ge(column => value)

### sql_like([column,] value)
### sql_like(column => value)

### sql_is_null([column])

### sql_is_not_null([column])

### sql_not([column])

### sql_between([column,] min_value, max_value)
### sql_between([column,] min_value, max_value)

### sql_not_between([column,] min_value, max_value)

### sql_in([column,] values)
### sql_in(column => values)

### sql_not_in([column,] \@values)
### sql_not_in(column => \@values)

Instantiates a comparator object that tests a column against given value(s).

### sql_and([column,] conditions)
### sql_and(column => conditions)

### sql_or([column,] conditions)
### sql_or(column => conditions)

Aggregates given comparator objects into a logical expression.

If specified, the column name is pushed down to the arguments when the
as_sql method is being called, as show in the second example below.

    sql_and([                   # => `foo`=? AND `bar`<?
        sql_eq("foo" => v1),
        sql_lt("bar" => v2)
    ])

    sql_and("foo" => [          # => `foo`>=min OR `foo`<max
        sql_ge(min),
        sql_lt(max),
    ])

### sql_and(conditions)

### sql_or(conditions)

Aggregates given pairs of column names and comparators into a logical
expression.

The value part is composed of as the argument to the = operator if it is
not a blessed reference.

    query = sql_and({
        :foo => 'abc',
        :bar => sql_lt(123),
    })
    query.as_sql             # => `foo`=? AND bar<?
    query.bind               # => ('abc', 123)


### sql_op([column,] op_sql, bind_values)

Generates a comparator object that tests a column using the given SQL and
values.  <@> in the given SQL are replaced by the column name (specified
either by the argument to the function or later by the call to the <as_sql>
method), and <?> are substituted by the given bind values.

### sql_raw(sql[, bind_values])
### sql_raw(sql => bind_values)

Generates a comparator object from raw SQL and bind values.  <?> in the
given SQL are replaced by the bind values.

### obj.as_sql

### obj.as_sql(column_name)

### obj.as_sql(column_name, quote_identifier_cb)

Compiles given comparator object and returns an SQL expression.
Corresponding bind values should be obtained by calling the bind method.

The function optionally accepts a column name to which the comparator object
should be bound; an error is thrown if the comparator object is already bound
to another column.

The function also accepts a callback for quoting the identifiers.  If omitted,
the identifiers are quoted using ` after being splitted using .; i.e. a
column designated as foo.bar is quoted as `foo`.`bar`.

### obj.bind

Returns a list of bind values corresponding to the SQL expression returned by
the as_sql method.

# CHEAT SHEET

    IN:        sql_eq('foo' => 'bar')
    OUT QUERY: '`foo` = ?'
    OUT BIND:  ['bar']

    IN:        sql_in('foo' => ['bar', 'baz'])
    OUT QUERY: '`foo` IN (?,?)'
    OUT BIND:  ['bar','baz']

    IN:        sql_and([sql_eq('foo' => 'bar'), sql_eq('baz' => 123)])
    OUT QUERY: '(`foo` = ?) AND (`baz` = ?)'
    OUT BIND:  ['bar',123]

    IN:        sql_and('foo' => [sql_ge(3), sql_lt(5)])
    OUT QUERY: '(`foo` >= ?) AND (`foo` < ?)'
    OUT BIND:  [3,5]

    IN:        sql_or([sql_eq('foo' => 'bar'), sql_eq('baz' => 123)])
    OUT QUERY: '(`foo` = ?) OR (`baz` = ?)'
    OUT BIND:  ['bar',123]

    IN:        sql_or('foo' => ['bar', 'baz'])
    OUT QUERY: '(`foo` = ?) OR (`foo` = ?)'
    OUT BIND:  ['bar','baz']

    IN:        sql_is_null('foo')
    OUT QUERY: '`foo` IS NULL'
    OUT BIND:  []

    IN:        sql_is_not_null('foo')
    OUT QUERY: '`foo` IS NOT NULL'
    OUT BIND:  []

    IN:        sql_between('foo', 1, 2)
    OUT QUERY: '`foo` BETWEEN ? AND ?'
    OUT BIND:  [1,2]

    IN:        sql_not('foo')
    OUT QUERY: 'NOT `foo`'
    OUT BIND:  []

    IN:        sql_op('apples', 'MATCH (@) AGAINST (?)', ['oranges'])
    OUT QUERY: 'MATCH (`apples`) AGAINST (?)'
    OUT BIND:  ['oranges']

    IN:        sql_raw('COUNT(*)')
    OUT QUERY: 'COUNT(*)'
    OUT BIND:  []

    IN:        sql_raw('SELECT * FROM t WHERE id=?',123)
    OUT QUERY: 'SELECT * FROM t WHERE id=?'
    OUT BIND:  [123]

    IN:        sql_in('foo' => [123,sql_raw('SELECT id FROM t WHERE cat=?',5)])
    OUT QUERY: '`foo` IN (?,(SELECT id FROM t WHERE cat=?))'
    OUT BIND:  [123,5]

# AUTHOR

Natoshi Seo (Originally designed by Kazuho Oku as a Perl module)

# LICENSE

This library is free software; you can redistribute it and/or modify it under the MIT License.

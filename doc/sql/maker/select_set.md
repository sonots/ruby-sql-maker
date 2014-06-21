# NAME

SQL::Maker::SelectSet - provides set functions

# SYNOPSIS

    include SQL::Maker::Helper

    s1 = SQL::Maker::Select.new()
      .add_select('foo')
      .add_from('t1')
    s2 = SQL::Maker::Select.new()
      .add_select('bar')
      .add_from('t2')
    sql_union_all( s1, s2 ).as_sql
    # =>
    #  SQL::Maker::SelectSet.new_set(
    #      :operator => 'UNION ALL',
    #      :new_line => s1.new_line
    #  ).add_statement(s1)
    #   .add_statement(s2)
    #   .as_sql
    # => "SELECT foo FROM t1 UNION ALL SELECT bar FROM t2"
    except( s1, s2 ).as_sql
    # => SQL::Maker::SelectSet.new_set( :operator => 'EXCEPT', :new_line => s1.new_line )
    #     .add_statement( s1 )
    #     .add_statement( s2 )
    #     .as_sql
    # => "SELECT foo FROM t1 EXCEPT SELECT bar FROM t2"

# DESCRIPTION

This module provides some set functions which return a SQL::Maker::SelectSet object
inherited from SQL::Maker::Select.

# FUNCTION

Following functions will be avaiable with `include SQL::Maker::Helper`.

### sql_union(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by UNION.

### sql_union_all(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by UNION ALL.

### sql_intersect(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by INTERSECT.

### sql_intersect_all(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by INTERSECT ALL.

### sql_except(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by EXCEPT.

### sql_except(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet

Tow statements are combined by EXCEPT ALL.

# Class Method

## stmt = SQL::Maker::SelectSet.new( args )

opretaor is a set operator (ex. UNION).
one and another are SQL::Maker::Select object or SQL::Maker::SelectSet object.
It returns a SQL::Maker::SelectSet object.

The parameters are:

### new_line

Default values is "\n".

### operator : Str

The operator. This parameter is required.

# Instance Methods

## sql = set.as_sql : Str

Returns a new select statement.

## bind = set.bind : Array[Str]

Returns bind variables.

## set.add_statement(stmt) : SQL::Maker::SelectSet

This method adds new statement object. stmt must provides 'as_sql' method.

I<Return Value> is the set itself.

# SEE ALSO

[SQL::Maker::Select](./select.md)

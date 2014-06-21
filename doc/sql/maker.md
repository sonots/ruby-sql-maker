# NAME

SQL::Maker - Yet another SQL builder

# SYNOPSIS

    use SQL::Maker

    builder = SQL::Maker.new(
        :driver => 'SQLite', # or your favorite driver
    )

    # SELECT
    sql, bind = builder.select(table, fields, where, opt)

    # INSERT
    sql, bind = builder.insert(table, values, opt)

    # DELETE
    sql, bind = builder.delete(table, where, opt)

    # UPDATE
    sql, bind = builder.update(table, set, where)
    sql, bind = builder.update(table, set, where)

# DESCRIPTION

SQL::Maker is yet another SQL builder class.

# METHODS



## builder = SQL::Maker.new(args)

Create new instance of SQL::Maker.

Attributes are the following:



### driver: Str

Driver name is required. The driver type is needed to create SQL string.

### quote_char: Str

This is the character that a table or column name will be quoted with.

Default: auto detect from driver.

### name_sep: Str

This is the character that separates a table and column name.

Default: '.'

### new_line: Str

This is the character that separates a part of statements.

Default: '\n'

### strict: Bool

In strict mode, all the expressions must be declared by using instances of SQL::QueryMaker

Default: false



## sql, bind = builder.select(table|tables, fields, where, opt)

    sql, bind = builder.select('user', ['*'], {:name => 'john'}, {:order_by => 'user_id DESC'})
    # =>
    #   SELECT * FROM `user` WHERE (`name` = ?) ORDER BY user_id DESC
    #   ['john']

This method returns the SQL string and bind variables for a SELECT statement.



### table

Table name for the FROM clause as scalar or arrayref. You can specify the instance of SQL::Maker::Select for a sub-query.

If you are using opt[:joins] >> this should be I<< undef since it's passed via the first join.

### fields

This is a list for retrieving fields from database.

Each element of the fields is normally an array of column names.
If you want to specify an alias of the field, you can use an array of hashes containing a pair
of column and alias names (e.g. ['foo.id' => 'foo_id']).

### where

where clause from hash or array via SQL::Maker::Condition, or SQL::Maker::Condition object.

### opt

These are the options for the SELECT statement



### opt[:prefix]

This is a prefix for the SELECT statement.

For example, you can provide the 'SELECT SQL_CALC_FOUND_ROWS '. It's useful for MySQL.

Default Value: 'SELECT '

### opt[:limit]

This option adds a 'LIMIT n' clause.

### opt[:offset]

This option adds an 'OFFSET n' clause.

### opt[:order_by]

This option adds an ORDER BY clause

You can write it in any of the following forms:

    builder.select(..., {:order_by => 'foo DESC, bar ASC'})
    builder.select(..., {:order_by => ['foo DESC', 'bar ASC']})
    builder.select(..., {:order_by => {:foo => 'DESC'}})
    builder.select(..., {:order_by => [{:foo => 'DESC'}, {:bar => 'ASC'}]})

### opt[:group_by]

This option adds a GROUP BY clause

You can write it in any of the following forms:

    builder.select(..., {:group_by => 'foo DESC, bar ASC'})
    builder.select(..., {:group_by => ['foo DESC', 'bar ASC']})
    builder.select(..., {:group_by => {:foo => 'DESC'}})
    builder.select(..., {:group_by => [{:foo => 'DESC'}, {:bar => 'ASC'}]})

### opt[:having]

This option adds a HAVING clause

### opt[:for_update]

This option adds a 'FOR UPDATE" clause.

### opt[:joins]

This option adds a 'JOIN' via SQL::Maker::Select.

You can write it as follows:

    builder.select(nil, ..., {:joins => [[:user => {:table => 'group', :condition => 'user.gid = group.gid'}], ...]})

### opt[:index_hint]

This option adds an INDEX HINT like as 'USE INDEX' clause for MySQL via SQL::Maker::Select.

You can write it as follows:

    builder.select(..., { :index_hint => 'foo' })
    builder.select(..., { :index_hint => ['foo', 'bar'] })
    builder.select(..., { :index_hint => { :list => 'foo' })
    builder.select(..., { :index_hint => { :type => 'FORCE', :list => ['foo', 'bar'] })





## sql, bind = builder.insert(table, values, opt);

    sql, bind = builder.insert(:user, {:name => 'john'})
    # =>
    #    INSERT INTO `user` (`name`) VALUES (?)
    #    ['john']

Generate an INSERT query.



### table

Table name

### values

These are the values for the INSERT statement.

### opt

These are the options for the INSERT statement



### opt[:prefix]

This is a prefix for the INSERT statement.

For example, you can provide 'INSERT IGNORE INTO' for MySQL.

Default Value: 'INSERT INTO'





## sql, bind = builder.delete(table, where, opt)

    sql, bind = builder.delete(table, where)
    # =>
    #    DELETE FROM `user` WHERE (`name` = ?)
    #    ['john']

Generate a DELETE query.



### table

Table name

### where

where clause from hash or array, or SQL::Maker::Condition object.

### opt

These are the options for the DELETE statement



### opt[:using]

This option adds a USING clause. It takes a scalar or an arrayref of table names as argument:

    (sql, bind) = bulder.delete(table, where, { :using => 'group' })
    # =>
    #    DELETE FROM `user` USING `group` WHERE (`group`.`name` = ?)
    #    ['doe']
    bulder.delete(..., { :using => ['bar', 'qux'] })





## sql, bind = builder.update(table, set, where)

Generate a UPDATE query.

    sql, bind = builder.update('user', ['name' => 'john', :email => 'john@example.com'], {:user_id => 3})
    # =>
    #    'UPDATE `user` SET `name` = ?, `email` = ? WHERE (`user_id` = ?)'
    #    ['john','john@example.com',3]



### table

Table name

### set

Setting values.

### where

where clause from a hash or array, or SQL::Maker::Condition object.



## select = builder.new_select(args)

Create new instance of SQL::Maker::Select using the settings from builder.

This method returns an instance of SQL::Maker::Select.

## builder.new_condition()

Create new SQL::Maker::Condition object from  builder  settings.

## sql, bind = builder.where(where)

Where clause from a hash or array, or SQL::Maker::Condition object.



# PLUGINS

SQL::Maker features a plugin system. Write the code as follows:

    require 'sql/maker'
    SQL::Maker.load_plugin('insert_multi')

# FAQ



### Why don't you use Arel or ActiveRecord?

I wanted a query builder rather than ORM.

I wanted simpler one than Arel.



# SEE ALSO

Perl version is located at https://github.com/tokuhirom/SQL-Maker

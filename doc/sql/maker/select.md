# NAME

SQL::Maker::Select - dynamic SQL generator

# SYNOPSIS

    sql = SQL::Maker::Select.new
      .add_select('foo')
      .add_select('bar')
      .add_select('baz')
      .add_from('table_name' => 't')
      .as_sql
    # => "SELECT foo, bar, baz FROM table_name t"

# DESCRIPTION

# METHODS



### sql = stmt.as_sql

Render the SQL string.

### bind = stmt.bind

Get the bind variables.

### stmt.add_select('*')

### stmt.add_select(:col => alias)

### stmt.add_select(sql_raw('COUNT(*)') => 'cnt')

Add a new select term. It's automatically quoted.

### stmt.add_from(table :Str | select :SQL::Maker::Select) : SQL::Maker::Select

Add a new FROM clause. You can specify the table name or an instance of SQL::Maker::Select for a sub-query.

I<Return:> stmt itself.

### stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => 'user.user_id = config.user_id'})

### stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => {'user.user_id' => 'config.user_id'})

### stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => ['user_id']})

Add a new JOIN clause. If you pass an array for 'condition' then it uses 'USING'. If 'type' is omitted
it falls back to plain JOIN.

    stmt = SQL::Maker::Select.new
    stmt.add_join(
        :user => {
            :type      => 'inner',
            :table     => 'config',
            :condition => 'user.user_id = config.user_id',
        }
    )
    stmt.as_sql
    # => 'FROM user INNER JOIN config ON user.user_id = config.user_id'

    stmt = SQL::Maker::Select.new(:quote_char => '`', :name_sep => '.')
    stmt.add_join(
        :user => {
            :type      => 'inner',
            :table     => 'config',
            :condition => {'user.user_id' => 'config.user_id'},
        }
    )
    stmt.as_sql
    # => 'FROM `user` INNER JOIN `config` ON `user`.`user_id` = `config`.`user_id`'

    stmt = SQL::Maker::Select.new
    stmt.add_select('name')
    stmt.add_join(
        :user => {
            :type      => 'inner',
            :table     => 'config',
            :condition => ['user_id'],
        }
    )
    stmt.as_sql
    # => 'SELECT name FROM user INNER JOIN config USING (user_id)'

    subquery = SQL::Maker::Select.new
    subquery.add_select('*')
    subquery.add_from( 'foo' )
    subquery.add_where( 'hoge' => 'fuga' )
    stmt = SQL::Maker::Select.new
    stmt.add_join(
        [ subquery, 'bar' ] => {
            :type      => 'inner',
            :table     => 'baz',
            :alias     => 'b1',
            :condition => 'bar.baz_id = b1.baz_id'
        },
    )
    stmt.as_sql
    # => "FROM (SELECT * FROM foo WHERE (hoge = ?)) bar INNER JOIN baz b1 ON bar.baz_id = b1.baz_id"

### stmt.add_index_hint(:foo => {:type => 'USE', :list => ['index_hint']})

### stmt.add_index_hint(:foo => 'index_hint')

### stmt.add_index_hint(:foo => ['index_hint'])

    stmt = SQL::Maker::Select.new
    stmt.add_select('name')
    stmt.add_from('user')
    stmt.add_index_hint(:user => {:type => 'USE', :list => ['index_hint']})
    stmt.as_sql
    # => "SELECT name FROM user USE INDEX (index_hint)"

### stmt.add_where('foo_id' => 'bar')

Add a new WHERE clause.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_where('name' => 'john')
                                 .add_where('type' => {:IN => %w/1 2 3/})
                                 .as_sql
    # => "SELECT c FROM foo WHERE (name = ?) AND (type IN (?, ?, ?))"

Please see SQL::Maker::Condition#add for more details.

### stmt.add_where_raw('id = ?', [1])

Add a new WHERE clause from raw placeholder string and bind variables.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_where_raw('EXISTS(SELECT * FROM bar WHERE name = ?)' => ['john'])
                                 .add_where_raw('type IS NOT NULL')
                                 .as_sql
    # => "SELECT c FROM foo WHERE (EXISTS(SELECT * FROM bar WHERE name = ?)) AND (type IS NOT NULL)"


### stmt.set_where(condition)

Set the WHERE clause.

condition should be instance of SQL::Maker::Condition.

    cond1 = SQL::Maker::Condition.new.add("name" => "john")
    cond2 = SQL::Maker::Condition.new.add("type" => {:IN => %w/1 2 3/})
    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .set_where(cond1 & cond2)
                                 .as_sql
    # => "SELECT c FROM foo WHERE ((name = ?)) AND ((type IN (?, ?, ?)))"

### stmt.add_order_by('foo')

### stmt.add_order_by({'foo' => 'DESC'})

Add a new ORDER BY clause.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_order_by('name' => 'DESC')
                                 .add_order_by('id')
                                 .as_sql
    # => "SELECT c FROM foo ORDER BY name DESC, id"

### stmt.add_group_by('foo')

Add a new GROUP BY clause.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_group_by('id')
                                 .as_sql
    # => "SELECT c FROM foo GROUP BY id"

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_group_by('id' => 'DESC')
                                 .as_sql
    # => "SELECT c FROM foo GROUP BY id DESC"

### stmt.limit(30)

### stmt.offset(5)

Add LIMIT and OFFSET.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .limit(30)
                                 .offset(5)
                                 .as_sql
    # => "SELECT c FROM foo LIMIT 30 OFFSET 5"

### stmt.add_having(:cnt => 2)

Add a HAVING clause.

    stmt = SQL::Maker::Select.new.add_from('foo')
                                 .add_select(sql_raw('COUNT(*)') => 'cnt')
                                 .add_having(:cnt => 2)
                                 .as_sql
    # => "SELECT COUNT(*) AS cnt FROM foo HAVING (COUNT(*) = ?)"

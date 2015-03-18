# NAME

SQL::Maker::Condition - condition object for SQL::Maker

# SYNOPSIS

    condition = SQL::Maker::Condition.new(
        name_sep   => '.',
        quote_char => '`',
    )
    condition.add('foo_id' => 3)
    condition.add('bar_id' => 4)
    sql = condition.as_sql # (`foo_id`=?) AND (`bar_id`=?)
    bind = condition.bind  # (3, 4)

    # add_raw
    condition = SQL::Maker::Condition.new(
        name_sep   => '.',
        quote_char => '`',
    )
    condition.add_raw('EXISTS(SELECT * FROM bar WHERE name = ?)' => ['john'])
    condition.add_raw('type IS NOT NULL')
    sql = condition.as_sql # (EXISTS(SELECT * FROM bar WHERE name = ?)) AND (type IS NOT NULL)
    bind = condition.bind  # ('john')

    # composite and
    other = SQL::Maker::Condition.new(
        name_sep => '.',
        quote_char => '`',
    )
    other.add('name' => 'john')
    comp_and = condition & other
    sql = comp_and.as_sql # ((`foo_id`=?) AND (`bar_id`=?)) AND (`name`=?)
    bind = comp_and.bind  # (3, 4, 'john')

    # composite or
    comp_or = condition | other
    sql = comp_and.as_sql # ((`foo_id`=?) AND (`bar_id`=?)) OR (`name`=?)
    bind = comp_and.bind  # (3, 4, 'john')


# CONDITION CHEAT SHEET

Here is a cheat sheet for conditions.

    IN:        {'foo'=>'bar'}
    OUT QUERY: '`foo` = ?'
    OUT BIND:  ['bar']

    IN:        {'foo'=>['bar','baz']}
    OUT QUERY: '`foo` IN (?, ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo'=>{'IN' => ['bar','baz']}}
    OUT QUERY: '`foo` IN (?, ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo'=>{'not IN' => ['bar','baz']}}
    OUT QUERY: '`foo` NOT IN (?, ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo'=>{'!=' => 'bar'}}
    OUT QUERY: '`foo` != ?'
    OUT BIND:  ['bar']

    IN:        {'foo'=>{'between' => ['1','2']}}
    OUT QUERY: '`foo` BETWEEN ? AND ?'
    OUT BIND:  ['1','2']

    IN:        {'foo'=>{'like' => 'xaic%'}}
    OUT QUERY: '`foo` LIKE ?'
    OUT BIND:  ['xaic%']

    IN:        {'foo'=>[{'>' => 'bar'},{'<' => 'baz'}]}
    OUT QUERY: '(`foo` > ?) OR (`foo` < ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo'=>{:AND => [{'>' => 'bar'},{'<' => 'baz'}]}}
    OUT QUERY: '(`foo` > ?) AND (`foo` < ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo'=>{:AND => ['foo','bar','baz']}}
    OUT QUERY: '(`foo` = ?) AND (`foo` = ?) AND (`foo` = ?)'
    OUT BIND:  ['foo','bar','baz']

    IN:        {'foo_id'=>{'IN' => sql_raw('SELECT foo_id FROM bar WHERE t=?',44)}}
    OUT QUERY: '`foo_id` IN (SELECT foo_id FROM bar WHERE t=?)'
    OUT BIND:  [44]

    IN:        {'foo_id'=>nil}
    OUT QUERY: '`foo_id` IS NULL'
    OUT BIND:  []

    IN:        {'foo_id'=>{'IN' => []}}
    OUT QUERY: '0=1'
    OUT BIND:  []

    IN:        {'foo_id'=>{'NOT IN' => []}}
    OUT QUERY: '1=1'
    OUT BIND:  []

    # IN:        ['foo_id',\['MATCH (col1, col2) AGAINST (?)','apples']]
    # OUT QUERY: '`foo_id` MATCH (col1, col2) AGAINST (?)'
    # OUT BIND:  ['apples']

    # IN:        ['foo_id', [123,sql_type(\3, SQL_INTEGER)]]
    # OUT QUERY: '`foo_id` IN (?, ?)'
    # OUT BIND:  (123, sql_type(\3, SQL_INTEGER))

    # IN:        ['foo_id', sql_type(\3, SQL_INTEGER)]
    # OUT QUERY: '`foo_id` = ?'
    # OUT BIND:  sql_type(\3, SQL_INTEGER)

    # IN:        ['created_on', { '>', \'DATE_SUB(NOW(), INTERVAL 1 DAY)' }]
    # OUT QUERY: '`created_on` > DATE_SUB(NOW(), INTERVAL 1 DAY)'
    # OUT BIND:  

It is also possible to use the functions exported by SQL::Maker::Helper to define the conditions.

    IN:        {'foo' => sql_in(['bar','baz'])}
    OUT QUERY: '`foo` IN (?,?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo' => sql_lt(3)}
    OUT QUERY: '`foo` < ?'
    OUT BIND:  [3]

    IN:        {'foo' => sql_not_in(['bar','baz'])}
    OUT QUERY: '`foo` NOT IN (?,?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo' => sql_ne('bar')}
    OUT QUERY: '`foo` != ?'
    OUT BIND:  ['bar']

    IN:        {'foo' => sql_is_not_null}
    OUT QUERY: '`foo` IS NOT NULL'
    OUT BIND:  []

    IN:        {'foo' => sql_between('1','2')}
    OUT QUERY: '`foo` BETWEEN ? AND ?'
    OUT BIND:  ['1','2']

    IN:        {'foo' => sql_like('xaic%')}
    OUT QUERY: '`foo` LIKE ?'
    OUT BIND:  ['xaic%']

    IN:        {'foo' => sql_or([sql_gt('bar'), sql_lt('baz')])}
    OUT QUERY: '(`foo` > ?) OR (`foo` < ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo' => sql_and([sql_gt('bar'), sql_lt('baz')])}
    OUT QUERY: '(`foo` > ?) AND (`foo` < ?)'
    OUT BIND:  ['bar','baz']

    IN:        {'foo_id' => sql_op('IN (SELECT foo_id FROM bar WHERE t=?)',[44])}
    OUT QUERY: '`foo_id` IN (SELECT foo_id FROM bar WHERE t=?)'
    OUT BIND:  [44]

    IN:        {'foo_id' => sql_in([sql_raw('SELECT foo_id FROM bar WHERE t=?',44)])}
    OUT QUERY: '`foo_id` IN ((SELECT foo_id FROM bar WHERE t=?))'
    OUT BIND:  [44]

    IN:        {'foo_id' => sql_op('MATCH (@) AGAINST (?)',['apples'])}
    OUT QUERY: 'MATCH (`foo_id`) AGAINST (?)'
    OUT BIND:  ['apples']

    IN:        {'foo_id'=>sql_in([])}
    OUT QUERY: '0=1'
    OUT BIND:  []

    IN:        {'foo_id'=>sql_not_in([])}
    OUT QUERY: '1=1'
    OUT BIND:  []

    # IN:        ['foo_id', sql_type(\3, SQL_INTEGER)]
    # OUT QUERY: '`foo_id` = ?'
    # OUT BIND:  sql_type(\3, SQL_INTEGER)

    # IN:        ['foo_id', sql_in([sql_type(\3, SQL_INTEGER)])]
    # OUT QUERY: '`foo_id` IN (?)'
    # OUT BIND:  sql_type(\3, SQL_INTEGER)

    # IN:        ['created_on', sql_gt(sql_raw('DATE_SUB(NOW(), INTERVAL 1 DAY)')) ]
    # OUT QUERY: '`created_on` > DATE_SUB(NOW(), INTERVAL 1 DAY)'
    # OUT BIND:

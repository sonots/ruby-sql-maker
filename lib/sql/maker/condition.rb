require 'sql/maker/util'
require 'sql/query_maker'

class SQL::Maker::Condition
  include SQL::Maker::Util
  attr_accessor :sql, :bind, :strict, :name_sep, :quote_char

  def initialize(args = {})
    @sql = args[:sql] || []
    @bind = args[:bind] || []
    @strict = args[:strict].nil? ? false : args[:strict]
    @name_sep = args[:name_sep] || ''
    @quote_char = args[:quote_char] || ''
  end

  def &(other)
    self.compose_and(other)
  end

  def |(other)
    self.compose_or(other)
  end

  def _quote(label)
    quote_identifier(label, self.quote_char, self.name_sep)
  end

  # _make_term(:x => 1)
  def _make_term(*args)
    col, val = parse_args(*args)
    col = col.to_s

    if val.is_a?(SQL::QueryMaker)
      return [val.as_sql(col, self.method(:_quote)), val.bind]
    elsif self.strict
      croak("can pass only SQL::QueryMaker as an argument in strict mode")
    end

    if val.is_a?(Array)
      if val.first.is_a?(Hash)
        # {'foo'=>[{'>' => 'bar'},{'<' => 'baz'}]} => (`foo` > ?) OR (`foo` < ?)
        return self._make_or_term(col, 'OR', val)
      else
        # {'foo'=>['bar','baz']} => `foo` IN (?, ?)
        return self._make_in_term(col, 'IN', val)
      end
    elsif val.is_a?(Hash)
      op, v = val.each.first
      op = op.upcase.to_s
      if ( op == 'AND' || op == 'OR' ) && v.is_a?(Array)
        # {'foo'=>[{'>' => 'bar'},{'<' => 'baz'}]} => (`foo` > ?) OR (`foo` < ?)
        return self._make_or_term(col, op, v)
      elsif ( op == 'IN' || op == 'NOT IN' )
        return self._make_in_term(col, op, v)
      elsif ( op == 'BETWEEN' ) && v.is_a?(Array)
        croak("USAGE: make_term(foo => {BETWEEN => [a, b]})") if v.size != 2
        return [self._quote(col) + " BETWEEN ? AND ?", v]
      else
        # make_term(foo => { '<' => \"DATE_SUB(NOW(), INTERVAL 3 DAY)"}) => 'foo < DATE_SUB(NOW(), INTERVAL 3 DAY)'
        # return [self._quote(col) + " op " + v, []]
        # make_term(foo => { '<' => 3 }) => foo < 3
        return [self._quote(col) + " #{op} ?", [v]]
      end
    elsif val
      # make_term(foo => "3") => foo = 3
      return [self._quote(col) + " = ?", [val]]
    else
      # make_term(foo => nil) => foo IS NULL
      return [self._quote(col) + " IS NULL", []]
    end
  end

  def _make_or_term(col, op, values)
    binds = []
    terms = []
    values.each do |v|
      term, bind = self._make_term(col => v)
      terms.push "(#{term})"
      binds.push bind
    end
    term = terms.join(" #{op} ")
    bind = binds.flatten
    return [term, bind]
  end

  def _make_in_term(col, op, v)
    if v.respond_to?(:as_sql)
      # make_term(foo => { 'IN' => sql_raw('SELECT foo FROM bar') }) => foo IN (SELECT foo FROM bar)
      term = "#{self._quote(col)} #{op} (#{v.as_sql})"
      [term, v.bind]
    elsif v.is_a?(Array)
      if v.size == 0
        if op == 'IN'
          # make_term(foo => {'IN' => []}) => 0=1
          return ['0=1', []]
        else
          # make_term(foo => {'NOT IN' => []}) => 1=1
          return ['1=1', []]
        end
      else
        # make_term(foo => { 'IN' => [1,2,3] }) => [foo IN (?,?,?), [1,2,3]]
        term = "#{self._quote(col)} #{op} (#{(['?'] * v.size).join(', ')})"
        return [term, v]
      end
    else
      croad("_make_in_term: arguments must be either of query instance or array")
    end
  end

  def add(*args)
    term, bind = self._make_term(*args)
    self.sql.push "(#{term})" if term
    self.bind += array_wrap(bind) if bind

    return self # for influent interface
  end

  def add_raw(*args)
    term, bind = parse_args(*args)
    self.sql.push "(#{term})"
    self.bind += array_wrap(bind) if bind
    return self
  end

  def compose_and(other)
    if self.sql.empty?
      if other.sql.empty?
        return SQL::Maker::Condition.new
      end
      return SQL::Maker::Condition.new(
        :sql => ['(' + other.as_sql() + ')'],
        :bind => other.bind,
      )
    end
    if other.sql.empty?
      return SQL::Maker::Condition.new(
        :sql => ['(' + self.as_sql() + ')'],
        :bind => self.bind,
      )
    end

    return SQL::Maker::Condition.new(
      :sql => ['(' + self.as_sql() + ') AND (' + other.as_sql() + ')'],
      :bind => self.bind + other.bind,
    )
  end

  def compose_or(other)
    if self.sql.empty?
      if other.sql.empty?
        return SQL::Maker::Condition.new
      end
      return SQL::Maker::Condition.new(
        :sql => ['(' + other.as_sql() + ')'],
        :bind => other.bind,
      )
    end
    if other.sql.empty?
      return SQL::Maker::Condition.new(
        :sql => ['(' + self.as_sql() + ')'],
        :bind => self.bind,
      )
    end

    # return value is enclosed with '()'.
    # because 'OR' operator priority less than 'AND'.
    return SQL::Maker::Condition.new(
      :sql => ['((' + self.as_sql() + ') OR (' + other.as_sql() + '))'],
      :bind => self.bind + other.bind,
    )
  end

  def as_sql
    self.sql.join(' AND ')
  end
  alias_method :to_s, :as_sql
end

__END__

=for test_synopsis
my (sql, @bind)

=head1 NAME

SQL::Maker::Condition - condition object for SQL::Maker

=head1 SYNOPSIS

    my condition = SQL::Maker::Condition.new(
        name_sep   => '.',
        quote_char => '`',
    )
    condition.add('foo_id' => 3)
    condition.add('bar_id' => 4)
    sql = condition.as_sql() # (`foo_id`=?) AND (`bar_id`=?)
    @bind = condition.bind()  # (3, 4)

    # add_raw
    my condition = SQL::Maker::Condition.new(
        name_sep   => '.',
        quote_char => '`',
    )
    condition.add_raw('EXISTS(SELECT * FROM bar WHERE name = ?)' => ['john'])
    condition.add_raw('type IS NOT NULL')
    sql = condition.as_sql() # (EXISTS(SELECT * FROM bar WHERE name = ?)) AND (type IS NOT NULL)
    @bind = condition.bind()  # ('john')

    # composite and
    my other = SQL::Maker::Condition.new(
        name_sep => '.',
        quote_char => '`',
    )
    other.add('name' => 'john')
    my $comp_and = condition & other
    sql = $comp_and.as_sql() # ((`foo_id`=?) AND (`bar_id`=?)) AND (`name`=?)
    @bind = $comp_and.bind()  # (3, 4, 'john')

    # composite or
    my $comp_or = condition | other
    sql = $comp_and.as_sql() # ((`foo_id`=?) AND (`bar_id`=?)) OR (`name`=?)
    @bind = $comp_and.bind()  # (3, 4, 'john')


=head1 CONDITION CHEAT SHEET

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

#    IN:        {'foo'=>\'IS NOT NULL'}
#    OUT QUERY: '`foo` IS NOT NULL'
#    OUT BIND:  []

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

#    IN:        ['foo_id',\['MATCH (col1, col2) AGAINST (?)','apples']]
#    OUT QUERY: '`foo_id` MATCH (col1, col2) AGAINST (?)'
#    OUT BIND:  ['apples']

    IN:        {'foo_id'=>nil}
    OUT QUERY: '`foo_id` IS NULL'
    OUT BIND:  []

    IN:        {'foo_id'=>{'IN' => []}}
    OUT QUERY: '0=1'
    OUT BIND:  []

    IN:        {'foo_id'=>{'NOT IN' => []}}
    OUT QUERY: '1=1'
    OUT BIND:  []

#    IN:        ['foo_id', [123,sql_type(\3, SQL_INTEGER)]]
#    OUT QUERY: '`foo_id` IN (?, ?)'
#    OUT BIND:  (123, sql_type(\3, SQL_INTEGER))
#
#    IN:        ['foo_id', sql_type(\3, SQL_INTEGER)]
#    OUT QUERY: '`foo_id` = ?'
#    OUT BIND:  sql_type(\3, SQL_INTEGER)
#
#    IN:        ['created_on', { '>', \'DATE_SUB(NOW(), INTERVAL 1 DAY)' }]
#    OUT QUERY: '`created_on` > DATE_SUB(NOW(), INTERVAL 1 DAY)'
#    OUT BIND:  

It is also possible to use the functions exported by C<SQL::QueryMaker> to define the conditions.

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

    IN:        {'foo' => sql_is_not_null()}
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

#    IN:        ['foo_id', sql_type(\3, SQL_INTEGER)]
#    OUT QUERY: '`foo_id` = ?'
#    OUT BIND:  sql_type(\3, SQL_INTEGER)
#
#    IN:        ['foo_id', sql_in([sql_type(\3, SQL_INTEGER)])]
#    OUT QUERY: '`foo_id` IN (?)'
#    OUT BIND:  sql_type(\3, SQL_INTEGER)
#
#    IN:        ['created_on', sql_gt(sql_raw('DATE_SUB(NOW(), INTERVAL 1 DAY)')) ]
#    OUT QUERY: '`created_on` > DATE_SUB(NOW(), INTERVAL 1 DAY)'
#    OUT BIND:

=head1 SEE ALSO

L<SQL::Maker>


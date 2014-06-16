require 'sql/maker/util'

class SQL::QueryMaker
  include SQL::Maker::Util

  FNOP = {
    'is_null' => 'IS NULL',
    'is_not_null' => 'IS NOT NULL',
    'eq' => '= ?',
    'ne' => '!= ?',
    'lt' => '< ?',
    'gt' => '> ?',
    'le' => '<= ?',
    'ge' => '>= ?',
    'like' => 'LIKE ?',
    'between' => 'BETWEEN ? AND ?',
    'not_between' => 'NOT BETWEEN ? AND ?',
    'not' => 'NOT @',
  }

  class << self
    %w[and or].each do |_|
      fn = "sql_#{_}"
      op = _.upcase

      define_method(fn) do |args|
        column = nil
        if args.is_a?(Hash)
          if args.each.first[1].is_a?(Array)
            # :foo => [v1, v2, v3]
            # :foo => [sql_ge(min), sql_lt(max)]
            column, args = args.each.first
          else
            # {:foo => 1, :bar => sql_eq(2), baz => sql_lt(3)}
            conds = []
            args.each do |column, value|
              if value.respond_to?(:bind_column)
                value.bind_column(column)
              else
                value = sql_eq(column, value)
              end
              conds.push(value)
            end
            args = conds
          end
        elsif args.is_a?(Array)
          # [sql_eq(:foo => v1), sql_eq(:bar => v2)]
          # [:foo => v1, :bar => sql_lt(v2)]
        else
          croak("arguments to `#{op}` must be an array or a hash")
        end
        # build and return the compiler
        return SQL::QueryMaker.new(column, Proc.new {|column, quote_cb|
          next op == 'AND' ? '0=1' : '1=1' if args.empty?
          terms = []
          args.each do |arg|
            if arg.respond_to?(:as_sql)
              (t, bind) = arg.as_sql(column, quote_cb)
              terms.push "(#{t})"
            else
              croak("no column binding for fn") unless column
              terms.push '(' + quote_cb.call(column) + ' = ?)'
            end
          end
          term = terms.join " #{op} "
        }, Proc.new {
          bind = []
          args.each do |arg|
            if arg.respond_to?(:bind)
              bind += arg.bind
            else
              bind += [arg]
            end
          end
          bind
        }.call)
      end
    end

    %w[in not_in].each do |_|
      fn = "sql_#{_}"
      op = _.upcase.gsub(/_/, ' ')

      define_method(fn) do |args|
        column = nil
        if args.is_a?(Hash)
          if args.each.first[1].is_a?(Array)
            # :foo => [v1, v2, v3]
            column, args = args.each.first
          else
            croak("arguments to `#{op}` must be an {key => array}")
          end
        elsif args.is_a?(Array)
          # [v1, v2, v3] # bind column later
        else
          croak("arguments to `#{op}` must be an array or a hash")
        end
        return SQL::QueryMaker.new(column, Proc.new {|column, quote_cb|
          croak("no column binding for #{fn}") unless column
          next op == 'IN' ? '0=1' : '1=1' if args.empty?
          terms = []
          args.each do |arg|
            if arg.respond_to?(:as_sql)
              t = arg.as_sql(nil, quote_cb)
              terms.push(t == '?' ? t : "(#{t})") # emit parens only when necessary
            else
              terms.push '?'
            end
          end
          term = quote_cb.call(column) + " #{op} (" + terms.join(',') + ')'
        }, Proc.new {
          bind = []
          args.each do |arg|
            if arg.respond_to?(:bind)
              bind += arg.bind
            else
              bind += [arg]
            end
          end
          bind
        }.call)
      end
    end

    FNOP.each do |_, expr|
      fn = "sql_#{_}"

      define_method(fn) do |*args|
        (num_args, builder) = _compile_builder(expr)
        column = nil
        if args.first.is_a?(Hash)
          # sql_eq(foo: => 3)
          column, args = args.first.each.first
          args = array_wrap(args)
        else
          if args.size > num_args
            # sql_is_null('foo')
            column, args = [args.first, args[1..-1]]
          else
            column, args = [nil, args]
          end
        end
        croak("the operator expects num_args parameters, but got #{args.size}") if num_args != args.size
        return _sql_op(fn, builder, column, args)
      end
    end

    # sql_op('IN (SELECT foo_id FROM bar WHERE t=?)', [44])
    # sql_op('foo','IN (SELECT foo_id FROM bar WHERE t=?)', [44])
    def sql_op(*args)
      column, expr, bind = (args.size >= 3 ? args : [nil] + args)
      (num_bind, builder) = _compile_builder(expr)
      croak("the operator expects num_bind but got #{bind.size}") if num_bind != bind.size
      return _sql_op("sql_op", builder, column, bind)
    end

    def _sql_op(fn, builder, column, bind)
      return SQL::QueryMaker.new(column, Proc.new {|column, quote_cb|
        croak("no column binding for fn(bind...)") unless column
        term = builder.call(quote_cb.call(column))
      }, bind)
    end

    def sql_raw(*args)
      sql, bind = parse_args(*args)
      return SQL::QueryMaker.new(nil, Proc.new { sql }, bind)
    end

    def _compile_builder(expr)
      # substitute the column character
      expr = "@ #{expr}" if expr !~ /@/
      num_args = expr.count('?')
      exprs = expr.split(/@/, -1)
      builder = Proc.new {|quoted_column|
        exprs.join(quoted_column)
      }
      return [num_args, builder]
    end
  end

  attr_accessor :column, :as_sql, :bind
  def initialize(column, as_sql, bind)
    bind = bind.nil? ? [] : array_wrap(bind)
    bind.each do |b|
      croak("cannot bind an array or an hash") if b.is_a?(Array) or b.is_a?(Hash)
    end
    @column = column
    @as_sql = as_sql
    @bind  = bind
  end

  def bind_column(column = nil)
    if column
      croak('cannot rebind column for \`' + self.column + "` to: `column`") if self.column
    end
    @column = column
  end

  def as_sql(supplied_colname = nil, quote_cb = nil)
    self.bind_column(supplied_colname) if supplied_colname
    quote_cb ||= self.method(:quote_identifier)
    return @as_sql.call(@column, quote_cb)
  end

  def quote_identifier(label)
    label.to_s.split(/\./).map {|e| "`#{e}`"}.join('.')
  end
end

__END__

=head1 NAME

SQL::QueryMaker - helper functions for SQL query generation

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module concentrates on providing an expressive, concise way to declare SQL
expressions by exporting carefully-designed functions.
It is possible to use the module to generate SQL query conditions and pass them
as arguments to other more versatile query builders such as L<SQL::Maker>.

The functions exported by the module instantiate comparator objects that build
SQL expressions when their C<as_sql> method are being invoked.
There are two ways to specify the names of the columns to the comparator; to
pass in the names as argument or to specify then as an argument to the
C<as_sql> method.

=head1 FUNCTIONS

=head2 C<< sql_eq([column,] value) >>

=head2 C<< sql_lt([column,] value) >>

=head2 C<< sql_gt([column,] value) >>

=head2 C<< sql_le([column,] value) >>

=head2 C<< sql_ge([column,] value) >>

=head2 C<< sql_like([column,] value) >>

=head2 C<< sql_is_null([column]) >>

=head2 C<< sql_is_not_null([column]) >>

=head2 C<< sql_not([column]) >>

=head2 C<< sql_between([column,] min_value, max_value) >>

=head2 C<< sql_not_between([column,] min_value, max_value) >>

=head2 C<< sql_in([column,] \@values) >>

=head2 C<< sql_not_in([column,] \@values) >>

Instantiates a comparator object that tests a column against given value(s).

=head2 C<< sql_and([column,] \@conditions) >>

=head2 C<< sql_or([$ column,] \@conditions) >>

Aggregates given comparator objects into a logical expression.

If specified, the column name is pushed down to the arguments when the
C<as_sql> method is being called, as show in the second example below.

    sql_and([                   # => `foo`=? AND `bar`<?
        sql_eq("foo" => v1),
        sql_lt("bar" => v2)
    ])

    sql_and("foo" => [          # => `foo`>=min OR `foo`<max
        sql_ge(min),
        sql_lt(max),
    ])

=head2 C<< sql_and(\%conditions) >>

=head2 C<< sql_or(\%conditions) >>

Aggregates given pairs of column names and comparators into a logical
expression.

The value part is composed of as the argument to the C<=> operator if it is
not a blessed reference.

    query = sql_and({
        :foo => 'abc',
        :bar => sql_lt(123),
    })
    query.as_sql             # => `foo`=? AND bar<?
    query.bind               # => ('abc', 123)


=head2 C<< sql_op([column,] op_sql, \@bind_values) >>

Generates a comparator object that tests a column using the given SQL and
values.  C<<@>> in the given SQL are replaced by the column name (specified
either by the argument to the function or later by the call to the C<<as_sql>>
method), and C<<?>> are substituted by the given bind values.

=head2 C<< sql_raw(sql, @bind_values) >>

Generates a comparator object from raw SQL and bind values.  C<<?>> in the
given SQL are replaced by the bind values.

=head2 C<< obj.as_sql() >>

=head2 C<< obj.as_sql(column_name) >>

=head2 C<< obj.as_sql(column_name, quote_identifier_cb) >>

Compiles given comparator object and returns an SQL expression.
Corresponding bind values should be obtained by calling the C<bind> method.

The function optionally accepts a column name to which the comparator object
should be bound; an error is thrown if the comparator object is already bound
to another column.

The function also accepts a callback for quoting the identifiers.  If omitted,
the identifiers are quoted using C<`> after being splitted using C<.>; i.e. a
column designated as C<foo.bar> is quoted as C<`foo`.`bar`>.

=head2 C<< obj.bind() >>

Returns a list of bind values corresponding to the SQL expression returned by
the C<as_sql> method.

=head1 CHEAT SHEET

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

    IN:        sql_raw('SELECT * FROM t WHERE id=?',123)
    OUT QUERY: 'SELECT * FROM t WHERE id=?'
    OUT BIND:  [123]

    IN:        sql_in('foo' => [123,sql_raw('SELECT id FROM t WHERE cat=?',5)])
    OUT QUERY: '`foo` IN (?,(SELECT id FROM t WHERE cat=?))'
    OUT BIND:  [123,5]

=head1 AUTHOR

Natoshi Seo (Originally designed by Kazuho Oku as a Perl module)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the MIT License.

=cut

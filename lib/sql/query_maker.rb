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

    # sql_raw('SELECT foo_id FROM bar WHERE t=44')
    # sql_raw('SELECT foo_id FROM bar WHERE t=?', [44])
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

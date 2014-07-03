require 'sql/maker/util'
require 'sql/query_maker'

class SQL::Maker::Condition
  include SQL::Maker::Util
  attr_accessor :quote_char, :name_sep, :strict, :auto_bind
  attr_accessor :sql, :bind

  def initialize(args = {})
    @quote_char = args[:quote_char] || ''
    @name_sep = args[:name_sep] || '.'
    @strict = args[:strict] || false
    @auto_bind = args[:auto_bind] || false

    @sql = args[:sql] || []
    @bind = args[:bind] || []
  end

  def new_condition(args = {})
    SQL::Maker::Condition.new({
      :quote_char => self.quote_char,
      :name_sep   => self.name_sep,
      :strict     => self.strict,
    }.merge(args))
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
      croak("Condition#add: can pass only SQL::QueryMaker object as an argument in strict mode")
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
      op = op.to_s.upcase
      if ( op == 'AND' || op == 'OR' ) && v.is_a?(Array)
        # {'foo'=>{'or' => [{'>' => 'bar'},{'<' => 'baz'}]}} => (`foo` > ?) OR (`foo` < ?)
        return self._make_or_term(col, op, v)
      elsif ( op == 'IN' || op == 'NOT IN' )
        # {'foo'=>{'in' => ['bar','baz']}} => `foo` IN (?, ?)
        return self._make_in_term(col, op, v)
      elsif ( op == 'BETWEEN' ) && v.is_a?(Array)
        croak("USAGE: add(foo => {BETWEEN => [a, b]})") if v.size != 2
        return [self._quote(col) + " BETWEEN ? AND ?", v]
      else
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
        return new_condition
      end
      return new_condition(
        :sql => ['(' + other.as_sql() + ')'],
        :bind => other.bind,
      )
    end
    if other.sql.empty?
      return new_condition(
        :sql => ['(' + self.as_sql() + ')'],
        :bind => self.bind,
      )
    end

    return new_condition(
      :sql => ['(' + self.as_sql() + ') AND (' + other.as_sql() + ')'],
      :bind => self.bind + other.bind,
    )
  end

  def compose_or(other)
    if self.sql.empty?
      if other.sql.empty?
        return new_condition
      end
      return new_condition(
        :sql => ['(' + other.as_sql() + ')'],
        :bind => other.bind,
      )
    end
    if other.sql.empty?
      return new_condition(
        :sql => ['(' + self.as_sql() + ')'],
        :bind => self.bind,
      )
    end

    # return value is enclosed with '()'.
    # because 'OR' operator priority less than 'AND'.
    return new_condition(
      :sql => ['((' + self.as_sql() + ') OR (' + other.as_sql() + '))'],
      :bind => self.bind + other.bind,
    )
  end

  def as_sql
    sql = self.sql.join(' AND ')
    @auto_bind ? bind_param(sql, self.bind) : sql
  end
end

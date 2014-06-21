require 'sql/maker/select'

class SQL::Maker::SelectSet
  include ::SQL::Maker::Util

  FNOP = %w[union union_all intersect intersect_all except except_all]
  FNOP.each do |fn|
    method = "sql_#{fn}" # sql_union
    operator = fn.upcase.gsub(/_/, ' ')

    define_singleton_method(method) do |*statements|
      stmt = SQL::Maker::SelectSet.new(
        :operator => operator,
        :new_line => statements.first.new_line,
      )
      statements.each {|statement| stmt.add_statement(statement) }
      stmt
    end
  end

  attr_accessor :new_line, :operator, :statements, :quote_char, :name_sep, :order_by

  def initialize(args = {})
    croak("Missing mandatory parameter 'operator' for SQL::Maker::SelectSet.new") unless args[:operator]
    @new_line = args[:new_line] || "\n"
    @operator = args[:operator]
    @quote_char = args[:quote_char]
    @name_sep = args[:name_sep]
    @statements = []
    @order_by = []
  end

  def add_statement(statement)
    unless statement.respond_to?(:as_sql)
      croak( "'statement' doesn't have 'as_sql' method.")
    end
    self.statements.push statement
    self # method chain
  end

  def as_sql_order_by
    attrs = self.order_by
    return '' if attrs.empty?

    return 'ORDER BY ' + attrs.map {|e|
      col, type = e
      type ? self._quote(col) + " #{type}" : self._quote(col)
    }.join(', ')
  end

  def _quote(label)
    SQL::Maker::Util.quote_identifier(label, self.quote_char, self.name_sep)
  end

  def as_sql
    new_line = self.new_line
    operator = self.operator

    sql = self.statements.map {|st| st.as_sql }.join(new_line + operator + new_line)
    sql += ' ' + self.as_sql_order_by unless self.order_by.empty?
    sql
  end
  alias_method :to_s, :as_sql

  def bind
    bind = []
    self.statements.each do |select|
      bind += select.bind
    end
    bind
  end

  def add_order_by(*args)
    col, type = parse_args(*args)
    self.order_by += [[col, type]]
    self # method chain
  end
end

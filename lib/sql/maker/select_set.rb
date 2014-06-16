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

__END__

=head1 NAME

SQL::Maker::SelectSet - provides set functions

=head1 SYNOPSIS

    use SQL::Maker::SelectSet qw(union_all except)
    s1 = SQL::Maker::Select .new()
                                .add_select('foo')
                                .add_from('t1')
    s2 = SQL::Maker::Select .new()
                                .add_select('bar')
                                .add_from('t2')
    union_all( s1, s2 ).as_sql
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

=head1 DESCRIPTION

This module provides some set functions which return a SQL::Maker::SelectSet object
inherited from L<SQL::Maker::Select>.

=head1 FUNCTION

=over 4

=item C<< union(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<UNION>.

=item C<< union_all(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<UNION ALL>.

=item C<< intersect(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<INTERSECT>.

=item C<< intersect_all(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<INTERSECT ALL>.

=item C<< except(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<EXCEPT>.

=item C<< except(select :SQL::Maker::Select | set :SQL::Maker::SelectSet) : SQL::Maker::SelectSet >>

Tow statements are combined by C<EXCEPT ALL>.

=back

=head1 Class Method

=over 4

=item stmt = SQL::Maker::SelectSet.new( %args )

opretaor is a set operator (ex. C<UNION>).
one and another are SQL::Maker::Select object or SQL::Maker::SelectSet object.
It returns a SQL::Maker::SelectSet object.

The parameters are:

=over 4

=item new_line

Default values is "\n".

=item operator : Str

The operator. This parameter is required.

=back

=back

=head1 Instance Methods

=over 4

=item C<< sql = set.as_sql() : Str >>

Returns a new select statement.

=item C<< @bind = set.bind() : Array[Str] >>

Returns bind variables.

=item C<< set.add_statement(stmt : stmt.can('as_sql')) : SQL::Maker::SelectSet >>

This method adds new statement object. C<< stmt >> must provides 'as_sql' method.

I<Return Value> is the set itself.

=back

=head1 SEE ALSO

L<SQL::Maker::Select>

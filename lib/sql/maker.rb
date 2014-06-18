require 'sql/maker/select'
require 'sql/maker/select/oracle'
require 'sql/maker/condition'
require 'sql/maker/util'

class SQL::Maker
  include SQL::Maker::Util

  # todo
  # def self.load_plugin(role)
  #   load "sql/maker/plugin/#{role}.rb"
  #   self.include "SQL::Maker::Plugin::#{role.camelize}"
  # end

  attr_accessor :quote_char, :select_class, :name_sep, :new_line, :strict, :driver, :auto_bind

  def initialize(args)
    unless @driver = args[:driver].to_s.downcase
      croak(":driver is required for creating new instance of SQL::Maker")
    end
    unless @quote_char = args[:quote_char]
      @quote_char =
        if @driver == 'mysql'
          %q{`}
        else
          %q{"}
        end
    end
    @select_class = @driver == 'oracle' ? SQL::Maker::Select::Oracle : SQL::Maker::Select

    @name_sep = args[:name_sep] || '.'
    @new_line = args[:new_line] || "\n"
    @strict = args[:strict] || false
    @auto_bind = args[:auto_bind] || false # apply client-side prepared statement binding autocatically
  end

  def new_condition
    SQL::Maker::Condition.new(
      :quote_char => self.quote_char,
      :name_sep   => self.name_sep,
      :strict     => self.strict,
    )
  end

  def new_select(args = {})
    return self.select_class.new({
      :name_sep   => self.name_sep,
      :quote_char => self.quote_char,
      :new_line   => self.new_line,
      :strict     => self.strict,
    }.merge(args))
  end

  def insert(*args)
    table, values, opt =
      if args.size == 1 and args.first.is_a?(Hash)
        args = args.first.dup
        [args.delete(:table), args.delete(:values) || {}, args]
      else
        [args[0], args[1] || {}, args[2] || {}]
      end

    prefix = opt[:prefix] || 'INSERT INTO'

    quoted_table = self._quote(table)
    quoted_columns = []
    columns = []
    bind_columns = []

    while true
      col, val =
        if values.is_a?(Hash)
          values.shift
        elsif values.is_a?(Array)
          values.slice!(0, 2)
        elsif values.nil?
          [nil, nil]
        else
          [values.first, nil]
        end
      break unless col
      quoted_columns += [self._quote(col)]
      if val.respond_to?(:as_sql)
        columns += [val.as_sql(nil, Proc.new {|e| self._quote(e) })]
        bind_columns += val.bind
      else
        croak("cannot pass in an unblessed ref as an argument in strict mode") if self.strict
        if val.is_a?(Hash)
          # builder.insert(:foo => { :created_on => ["NOW()"] })
          columns += [val]
        elsif val.is_a?(Array)
          # builder.insert( :foo => [ 'UNIX_TIMESTAMP(?)', '2011-04-12 00:34:12' ] )
          stmt, sub_bind = [val.first, val[1..-1]]
          columns += [stmt]
          bind_columns += sub_bind
        else
          # normal values
          columns += ['?']
          bind_columns += [val]
        end
      end
    end

    # Insert an empty record in SQLite.
    # ref. https://github.com/tokuhirom/SQL-Maker/issues/11
    if self.driver == 'sqlite' && columns.empty?
      sql  = "#{prefix} #{quoted_table}" + self.new_line + 'DEFAULT VALUES'
      return [sql, []]
    end

    sql  = "#{prefix} #{quoted_table}" + self.new_line
    sql += '(' + quoted_columns.join(', ') + ')' + self.new_line +
      'VALUES (' + columns.join(', ') + ')'

    @auto_bind ? bind_param(sql, bind_columns) : [sql, bind_columns]
  end

  def _quote(label) 
    SQL::Maker::Util::quote_identifier(label, self.quote_char, self.name_sep)
  end

  def delete(*args)
    table, where, opt =
      if args.size == 1 and args.first.is_a?(Hash)
        args = args.first.dup
        [args.delete(:table), args.delete(:where) || {}, args]
      else
        [args[0], args[1] || {}, args[2] || {}]
      end

    w = self._make_where_clause(where)
    quoted_table = self._quote(table)
    sql = "DELETE FROM #{quoted_table}"
    if opt[:using]
      # bulder.delete('foo', \%where, { :using => 'bar' })
      # bulder.delete('foo', \%where, { :using => ['bar', 'qux'] })
      tables = array_wrap(opt[:using])
      sql += " USING " + tables.map {|t| self._quote(t) }.join(', ')
    end
    sql += w[0]

    @auto_bind ? bind_param(sql, w[1]) : [sql, w[1]]
  end

  def update(*args)
    table, values, where, opt =
      if args.size == 1 and args.first.is_a?(Hash)
        args = args.first.dup
        [args.delete(:table), args.delete(:set) || {}, args.delete(:where) || {}, args]
      else
        [args[0], args[1] || {}, args[2] || {}, args[3] || {}]
      end

    columns, bind_columns = self.make_set_clause(values)

    w = self._make_where_clause(where)
    bind_columns += array_wrap(w[1])

    quoted_table = self._quote(table)
    sql = "UPDATE #{quoted_table} SET " + columns.join(', ') + w[0]

    @auto_bind ? bind_param(sql, bind_columns) : [sql, bind_columns]
  end

  # make "SET" clause.
  def make_set_clause(args)
    columns = []
    bind_columns = []
    while true
      col, val =
        if args.is_a?(Hash)
          args.shift
        elsif args.is_a?(Array)
          args.slice!(0, 2)
        else
          [args, nil]
        end
      break unless col
      quoted_col = self._quote(col)
      if val.respond_to?(:as_sql)
        columns += ["#{quoted_col} = " + val.as_sql(nil, Proc.new {|label| self._quote(label) })]
        bind_columns += val.bind
      else
        if self.strict
          croak("cannot pass in an unblessed ref as an argument in strict mode")
          if val.is_a?(Hash)
            # builder.update(:foo => { :created_on => \"NOW()" })
            # columns += ["quoted_col = " + $val
          end
        elsif val.is_a?(Array)
          # builder.update( :foo => \[ 'VALUES(foo) + ?', 10 ] )
          stmt, sub_bind = [val.first, val[1..-1]]
          columns += ["#{quoted_col} = " + stmt]
          bind_columns += sub_bind
        else
          # normal values
          columns += ["#{quoted_col} = ?"]
          bind_columns += [val]
        end
      end
    end
    return [columns, bind_columns]
  end

  def where(where)
    cond = self._make_where_condition(where)
    return [cond.as_sql, cond.bind]
  end

  def _make_where_condition(where = nil)
    return self.new_condition unless where
    if where.respond_to?(:as_sql)
      return where
    end

    cond = self.new_condition
    while true
      col, val =
        if where.is_a?(Hash)
          where.shift
        elsif where.is_a?(Array)
          where.slice!(0, 2)
        else
          [where, nil]
        end
      break unless col
      cond.add(col => val)
    end
    return cond
  end

  def _make_where_clause(where = nil)
    return ['', []] unless where

    w = self._make_where_condition(where)
    sql = w.as_sql
    return [sql.empty? ? "" : " WHERE #{sql}", array_wrap(w.bind)]
  end

  # my(stmt, @bind) = sql−>select(table, \@fields, \%where, \%opt)
  def select(*args)
    stmt = self.select_query(*args)

    @auto_bind ? bind_param(stmt.as_sql, stmt.bind) : [stmt.as_sql, stmt.bind]
  end

  def select_query(*args)
    table, fields, where, opt =
      if args.size == 1 and args.first.is_a?(Hash)
        args = args.first.dup
        [args.delete(:table), args.delete(:fields) || [], args.delete(:where) || {}, args]
      else
        [args[0], args[1] || [], args[2] || {}, args[3] || {}]
      end

    unless fields.is_a?(Array)
      croak("SQL::Maker::select_query: fields should be Array")
    end

    stmt = self.new_select
    fields.each do |field|
      stmt.add_select(field)
    end

    if table
      if table.is_a?(Array)
        table.each do |t|
          stmt.add_from(t)
        end
      else
        stmt.add_from( table )
      end
    end

    stmt.prefix(opt[:prefix]) if opt[:prefix]

    if where
      stmt.set_where(self._make_where_condition(where))
    end

    if joins = opt[:joins]
      joins.each do |join|
        stmt.add_join(join)
      end
    end

    if o = opt[:order_by]
      if o.is_a?(Array)
        o.each do |order|
          if order.is_a?(Hash)
            # Skinny-ish [{:foo => 'DESC'}, {:bar => 'ASC'}]
            stmt.add_order_by(order)
          else
            # just ['foo DESC', 'bar ASC']
            stmt.add_order_by(order)
          end
        end
      elsif o.is_a?(Hash)
        # Skinny-ish {:foo => 'DESC'}
        stmt.add_order_by(o)
      else
        # just 'foo DESC, bar ASC'
        stmt.add_order_by(o)
      end
    end
    if o = opt[:group_by]
      if o.is_a?(Array)
        o.each do | group|
          if group.is_a?(Hash)
            # Skinny-ish [{:foo => 'DESC'}, {:bar => 'ASC'}]
            stmt.add_group_by(group)
          else
            # just ['foo DESC', 'bar ASC']
            stmt.add_group_by(group)
          end
        end
      elsif o.is_a?(Hash)
        # Skinny-ish {:foo => 'DESC'end
        stmt.add_group_by(o)
      else
        # just 'foo DESC, bar ASC'
        stmt.add_group_by(o)
      end
    end
    if o = opt[:index_hint]
      stmt.add_index_hint(table, o)
    end

    stmt.limit(opt[:limit])    if opt[:limit]
    stmt.offset(opt[:offset])  if opt[:offset]

    if terms = opt[:having]
      term.each do |col, val|
        stmt.add_having(:col => val)
      end
    end

    stmt.for_update(1) if opt[:for_update]
    return stmt
  end
end

__END__

=encoding utf8

=head1 NAME

SQL::Maker - Yet another SQL builder

=head1 SYNOPSIS

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

=head1 DESCRIPTION

SQL::Maker is yet another SQL builder class.

=head1 METHODS

=over 4

=item C<< builder = SQL::Maker.new(args) >>

Create new instance of SQL::Maker.

Attributes are the following:

=over 4

=item driver: Str

Driver name is required. The driver type is needed to create SQL string.

=item quote_char: Str

This is the character that a table or column name will be quoted with.

Default: auto detect from driver.

=item name_sep: Str

This is the character that separates a table and column name.

Default: '.'

=item new_line: Str

This is the character that separates a part of statements.

Default: '\n'

=item strict: Bool

In strict mode, all the expressions must be declared by using instances of SQL::QueryMaker

Default: false

=back

=item C<< select = builder.new_select(args) >>

Create new instance of L<SQL::Maker::Select> using the settings from B<builder>.

This method returns an instance of L<SQL::Maker::Select>.

=item C<< sql, bind = builder.select(table|tables, fields, where, opt) >>

    sql, bind = builder.select('user', ['*'], {:name => 'john'}, {:order_by => 'user_id DESC'})
    # =>
    #   SELECT * FROM `user` WHERE (`name` = ?) ORDER BY user_id DESC
    #   ['john']

This method returns the SQL string and bind variables for a SELECT statement.

=over 4

=item C<< table >>

Table name for the B<FROM> clause as scalar or arrayref. You can specify the instance of B<SQL::Maker::Select> for a sub-query.

If you are using C<< opt.joins >> this should be I<< undef >> since it's passed via the first join.

=item C<< fields >>

This is a list for retrieving fields from database.

Each element of the C<fields> is normally an array of column names.
If you want to specify an alias of the field, you can use an array of hashes containing a pair
of column and alias names (e.g. C<< ['foo.id' => 'foo_id'] >>).

=item C<< where >>

where clause from hash or array via L<SQL::Maker::Condition>, or L<SQL::Maker::Condition> object.

=item C<< opt >>

These are the options for the SELECT statement

=over 4

=item C<< opt[:prefix] >>

This is a prefix for the SELECT statement.

For example, you can provide the 'SELECT SQL_CALC_FOUND_ROWS '. It's useful for MySQL.

Default Value: 'SELECT '

=item C<< opt[:limit] >>

This option adds a 'LIMIT n' clause.

=item C<< opt[:offset] >>

This option adds an 'OFFSET n' clause.

=item C<< opt[:order_by] >>

This option adds an B<ORDER BY> clause

You can write it in any of the following forms:

    builder.select(..., {:order_by => 'foo DESC, bar ASC'})
    builder.select(..., {:order_by => ['foo DESC', 'bar ASC']})
    builder.select(..., {:order_by => {:foo => 'DESC'}})
    builder.select(..., {:order_by => [{:foo => 'DESC'}, {:bar => 'ASC'}]})

=item C<< opt[:group_by] >>

This option adds a B<GROUP BY> clause

You can write it in any of the following forms:

    builder.select(..., {:group_by => 'foo DESC, bar ASC'})
    builder.select(..., {:group_by => ['foo DESC', 'bar ASC']})
    builder.select(..., {:group_by => {:foo => 'DESC'}})
    builder.select(..., {:group_by => [{:foo => 'DESC'}, {:bar => 'ASC'}]})

=item C<< opt[:having] >>

This option adds a HAVING clause

=item C<< opt[:for_update] >>

This option adds a 'FOR UPDATE" clause.

=item C<< opt[:joins] >>

This option adds a 'JOIN' via L<SQL::Maker::Select>.

You can write it as follows:

    builder.select(nil, ..., {:joins => [[:user => {:table => 'group', :condition => 'user.gid = group.gid'}], ...]})

=item C<< opt[:index_hint] >>

This option adds an INDEX HINT like as 'USE INDEX' clause for MySQL via L<SQL::Maker::Select>.

You can write it as follows:

    builder.select(..., { :index_hint => 'foo' })
    builder.select(..., { :index_hint => ['foo', 'bar'] })
    builder.select(..., { :index_hint => { :list => 'foo' })
    builder.select(..., { :index_hint => { :type => 'FORCE', :list => ['foo', 'bar'] })

=back

=back

=item C<< sql, bind = builder.insert(table, values, opt); >>

    sql, bind = builder.insert(:user, {:name => 'john'})
    # =>
    #    INSERT INTO `user` (`name`) VALUES (?)
    #    ['john']

Generate an INSERT query.

=over 4

=item C<< table >>

Table name

=item C<< values >>

These are the values for the INSERT statement.

=item C<< opt >>

These are the options for the INSERT statement

=over 4

=item C<< opt[:prefix] >>

This is a prefix for the INSERT statement.

For example, you can provide 'INSERT IGNORE INTO' for MySQL.

Default Value: 'INSERT INTO'

=back

=back

=item C<< sql, bind = builder.delete(table, where, opt) >>

    sql, bind = builder.delete(table, where)
    # =>
    #    DELETE FROM `user` WHERE (`name` = ?)
    #    ['john']

Generate a DELETE query.

=over 4

=item C<< table >>

Table name

=item C<< where >>

where clause from hash or array, or L<SQL::Maker::Condition> object.

=item C<< opt >>

These are the options for the DELETE statement

=over 4

=item C<< opt[:using] >>

This option adds a USING clause. It takes a scalar or an arrayref of table names as argument:

    (sql, bind) = bulder.delete(table, where, { :using => 'group' })
    # =>
    #    DELETE FROM `user` USING `group` WHERE (`group`.`name` = ?)
    #    ['doe']
    bulder.delete(..., { :using => ['bar', 'qux'] })

=back

=back

=item C<< sql, bind = builder.update(table, set, where) >>

Generate a UPDATE query.

    sql, bind = builder.update('user', ['name' => 'john', :email => 'john@example.com'], {:user_id => 3})
    # =>
    #    'UPDATE `user` SET `name` = ?, `email` = ? WHERE (`user_id` = ?)'
    #    ['john','john@example.com',3]

=over 4

=item table

Table name

=item set

Setting values.

=item where

where clause from a hash or array, or L<SQL::Maker::Condition> object.

=back

=item C<< builder.new_condition() >>

Create new L<SQL::Maker::Condition> object from C< builder > settings.

=item C<< sql, bind = builder.where(where) >>

Where clause from a hash or array, or L<SQL::Maker::Condition> object.

=back

=head1 PLUGINS

SQL::Maker features a plugin system. Write the code as follows:

    require 'sql/maker'
    SQL::Maker.load_plugin('insert_multi')

=head1 FAQ

=over 4

=item Why don't you use Arel or ActiveRecord?

I wanted a query builder rather than ORM.

I wanted simpler one than Arel.

=back

=head1 SEE ALSO

Perl version is located at https://github.com/tokuhirom/SQL-Maker

=cut

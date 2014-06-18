require 'sql/maker/condition'
require 'sql/maker/util'

class SQL::Maker::Select
  include SQL::Maker::Util

  attr_reader :quote_char, :name_sep, :new_line, :strict, :auto_bind
  attr_accessor :select, :select_map, :select_map_reverse, :from, :joins,
    :index_hint, :group_by, :order_by, :where, :having, :for_update, :subqueries

  def initialize(args = {})
    @quote_char = args[:quote_char] || ''
    @name_sep = args[:name_sep] || '.'
    @new_line = args[:new_line] || "\n"
    @strict = args[:strict] || false
    @auto_bind = args[:auto_bind] || false

    @select = args[:select] || []
    @distinct = args[:distinct] || false
    @select_map = args[:select_map] || {}
    @select_map_reverse = args[:select_map_reverse] || {}
    @from = args[:from] || []
    @joins = args[:joins] || []
    @index_hint = args[:index_hint] || {}
    @group_by = args[:group_by] || []
    @order_by = args[:order_by] || []
    @prefix = args[:prefix] || 'SELECT '
    @where = args[:where]
    @having = args[:having]
    @limit = args[:limit]
    @offset = args[:offset]
    @for_update = args[:for_update]
    @subqueries = []
  end

  def distinct(distinct = nil)
    if distinct
      @distinct = distinct
      self # method chain
    else
      @distinct
    end
  end

  def prefix(prefix = nil)
    if prefix
      @prefix = prefix
      self # method chain
    else
      @prefix
    end
  end

  def offset(offset = nil)
    if offset
      @offset = offset
      self # method chain
    else
      @offset
    end
  end

  def limit(limit = nil)
    if limit
      @limit = limit
      self # method chain
    else
      @limit
    end
  end

  def new_condition
    SQL::Maker::Condition.new(
      :quote_char => self.quote_char,
      :name_sep   => self.name_sep,
      :strict     => self.strict,
    )
  end

  def bind
    bind = []
    bind += self.subqueries if self.subqueries
    bind += self.where.bind if self.where
    bind += self.having.bind if self.having
    bind
  end

  def add_select(*args)
    term, col = parse_args(*args)
    term = term.to_s if term.is_a?(Symbol)
    col ||= term
    self.select += array_wrap(term)
    self.select_map[term] = col
    self.select_map_reverse[col] = term
    self # method chain
  end

  def add_from(*args)
    table, as = parse_args(*args)
    if table.respond_to?(:as_sql)
      self.subqueries += table.bind
      self.from += [[table, as]]
    else
      table = table.to_s
      self.from += [[table, as]]
    end
    self
  end

  def add_join(*args)
    # :user => { :type => 'inner', :table => 'config', :condition => {'user.user_id' => 'config.user_id'} }
    # [ subquery, 'bar' ] => { :type => 'inner', :table => 'config', :condition => {'user.user_id' => 'config.user_id'} }
    table, joins = parse_args(*args)
    table, as = parse_args(*table)

    if table.respond_to?(:as_sql)
      self.subqueries += table.bind
      table = '('  + table.as_sql + ')'
    else
      table = table.to_s
    end

    self.joins += [{
      :table => [ table, as ],
      :joins => joins
    }]
    self
  end

  def add_index_hint(*args)
    table, hint = parse_args(*args)
    table = table.to_s
    if hint.is_a?(Hash)
      # { :type => '...', :list => ['foo'] }
      type = hint[:type] || 'USE'
      list = array_wrap(hint[:list])
    else
      # ['foo, 'bar'] or just 'foo'
      type = 'USE'
      list = array_wrap(hint)
    end

    self.index_hint[table] = {
      :type => type,
      :list => list,
    }

    return self
  end

  def _quote(label)
    SQL::Maker::Util.quote_identifier(label, self.quote_char, self.name_sep)
  end

  def as_sql
    sql = ''
    new_line = self.new_line
   
    unless self.select.empty?
      sql += self.prefix
      sql += 'DISTINCT ' if self.distinct
      sql += self.select.map {|col|
        as = self.select_map[col]
        col = col.respond_to?(:as_sql) ? col.as_sql : self._quote(col)
        next col if as.nil?
        as = as.respond_to?(:as_sql) ? as.as_sql : self._quote(as)
        if as && col =~ /(?:^|\.)#{Regexp.escape(as)}$/
          col
        else
          col + ' AS ' +  as
        end
      }.join(', ') + new_line
    end

    sql += 'FROM '

    ## Add any explicit JOIN statements before the non-joined tables.
    unless self.joins.empty?
      initial_table_written = 0
      self.joins.each do |j|
        table = j[:table]
        join  = j[:joins]
        table = self._add_index_hint(table); ## index hint handling
        sql += table if initial_table_written == 0
        initial_table_written += 1
        sql += ' ' + join[:type].upcase if join[:type]
        sql += ' JOIN ' + self._quote(join[:table])
        sql += ' ' + self._quote(join[:alias]) if join[:alias]

        if condition = join[:condition]
          if condition.is_a?(Array)
            sql += ' USING (' + condition.map {|e| self._quote(e) }.join(', ') + ')'
          elsif condition.is_a?(Hash)
            conds = []
            condition.keys.each do |key|
              conds += [self._quote(key) + ' = ' + self._quote(condition[key])]
            end
            sql += ' ON ' + conds.join(' AND ')
          else
            sql += ' ON ' + condition
          end
        end
      end
      sql += ', ' unless self.from.empty?
    end

    unless self.from.empty?
      sql += self.from.map {|e| self._add_index_hint(e[0], e[1]) }.join(', ')
    end

    sql += new_line
    sql += self.as_sql_where     if self.where

    sql += self.as_sql_group_by  if self.group_by
    sql += self.as_sql_having    if self.having
    sql += self.as_sql_order_by  if self.order_by

    sql += self.as_sql_limit     if self.limit

    sql += self.as_sql_for_update
    sql.gsub!(/#{new_line}+$/, '')

    @auto_bind ? bind_param(sql, self.bind) : sql
  end

  def as_sql_limit
    return '' unless n = self.limit
    croak("Non-numerics in limit clause (n)") if n =~ /\D/
    return sprintf "LIMIT %d%s" + self.new_line, n,
      (self.offset ? " OFFSET " + self.offset.to_i.to_s : "")
  end

  def add_order_by(*args)
    col, type = parse_args(*args)
    self.order_by += [[col, type]]
    return self
  end

  def as_sql_order_by
    attrs = self.order_by
    return '' if attrs.empty?

    return 'ORDER BY ' + attrs.map {|e|
      col, type = e
      if col.respond_to?(:as_sql)
        col.as_sql
      else
        type ? self._quote(col) + " #{type}" : self._quote(col)
      end
    }.join(', ') + self.new_line
  end

  def add_group_by(*args)
    group, order = parse_args(*args)
    self.group_by +=
      if group.respond_to?(:as_sql)
        [group.as_sql]
      else
        order ? [self._quote(group) + " #{order}"] : [self._quote(group)]
      end
    return self
  end

  def as_sql_group_by
    elems = self.group_by
    return '' if elems.empty?

    return 'GROUP BY ' + elems.join(', ') + self.new_line
  end

  def set_where(where)
    self.where = where
    return self
  end

  def add_where(*args)
    self.where ||= self.new_condition()
    self.where.add(*args)
    return self
  end

  def add_where_raw(*args)
    self.where ||= self.new_condition()
    self.where.add_raw(*args)
    return self
  end

  def as_sql_where
    where = self.where.as_sql()
    where and !where.empty? ? "WHERE #{where}" + self.new_line : ''
  end

  def as_sql_having
    if self.having
      'HAVING ' + self.having.as_sql + self.new_line
    else
      ''
    end
  end

  def add_having(*args)
    col, val = parse_args(*args)
    col = col.to_s
    if orig = self.select_map_reverse[col]
      col = orig.respond_to?(:as_sql) ? orig.as_sql : orig
    end

    self.having ||= self.new_condition()
    self.having.add(col, val)
    return self
  end

  def as_sql_for_update
    self.for_update ? ' FOR UPDATE' : ''
  end

  def _add_index_hint(*args)
    table, as = parse_args(*args)
    tbl_name =
      if table.respond_to?(:as_sql)
        '(' + table.as_sql + ')'
      else
        self._quote(table)
      end
    quoted = as ? tbl_name + ' ' + self._quote(as) : tbl_name
    hint = self.index_hint[table]
    return quoted unless hint && hint.is_a?(Hash)
    if hint[:list]&& !hint[:list].empty?
      return quoted + ' ' + (hint[:type].upcase || 'USE') + ' INDEX (' + 
        hint[:list].map {|e| self._quote(e) }.join(',') + ')'
    end
    return quoted
  end
end

__END__

=head1 NAME

SQL::Maker::Select - dynamic SQL generator

=head1 SYNOPSIS

    sql = SQL::Maker::Select.new
      .add_select('foo')
      .add_select('bar')
      .add_select('baz')
      .add_from('table_name' => 't')
      .as_sql
    # => "SELECT foo, bar, baz FROM table_name t"

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item C<< sql = stmt.as_sql >>

Render the SQL string.

=item C<< bind = stmt.bind >>

Get the bind variables.

=item C<< stmt.add_select('*') >>

=item C<< stmt.add_select(:col => alias) >>

=item C<< stmt.add_select(sql_raw('COUNT(*)') => 'cnt') >>

Add a new select term. It's automatically quoted.

=item C<< stmt.add_from(table :Str | select :SQL::Maker::Select) : SQL::Maker::Select >>

Add a new FROM clause. You can specify the table name or an instance of L<SQL::Maker::Select> for a sub-query.

I<Return:> stmt itself.

=item C<< stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => 'user.user_id = config.user_id'}) >>

=item C<< stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => {'user.user_id' => 'config.user_id'}) >>

=item C<< stmt.add_join(:user => {:type => 'inner', :table => 'config', :condition => ['user_id']}) >>

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

=item C<< stmt.add_index_hint(:foo => {:type => 'USE', :list => ['index_hint']}) >>

=item C<< stmt.add_index_hint(:foo => 'index_hint') >>

=item C<< stmt.add_index_hint(:foo => ['index_hint']) >>

    stmt = SQL::Maker::Select.new
    stmt.add_select('name')
    stmt.add_from('user')
    stmt.add_index_hint(:user => {:type => 'USE', :list => ['index_hint']})
    stmt.as_sql
    # => "SELECT name FROM user USE INDEX (index_hint)"

=item C<< stmt.add_where('foo_id' => 'bar'); >>

Add a new WHERE clause.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_where('name' => 'john')
                                 .add_where('type' => {:IN => %w/1 2 3/})
                                 .as_sql
    # => "SELECT c FROM foo WHERE (name = ?) AND (type IN (?, ?, ?))"

=item C<< stmt.add_where_raw('id = ?', [1]) >>

Add a new WHERE clause from raw placeholder string and bind variables.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_where_raw('EXISTS(SELECT * FROM bar WHERE name = ?)' => ['john'])
                                 .add_where_raw('type IS NOT NULL')
                                 .as_sql
    # => "SELECT c FROM foo WHERE (EXISTS(SELECT * FROM bar WHERE name = ?)) AND (type IS NOT NULL)"


=item C<< stmt.set_where(condition) >>

Set the WHERE clause.

condition should be instance of L<SQL::Maker::Condition>.

    cond1 = SQL::Maker::Condition.new.add("name" => "john")
    cond2 = SQL::Maker::Condition.new.add("type" => {:IN => %w/1 2 3/})
    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .set_where(cond1 & cond2)
                                 .as_sql
    # => "SELECT c FROM foo WHERE ((name = ?)) AND ((type IN (?, ?, ?)))"

=item C<< stmt.add_order_by('foo'); >>

=item C<< stmt.add_order_by({'foo' => 'DESC'}); >>

Add a new ORDER BY clause.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .add_order_by('name' => 'DESC')
                                 .add_order_by('id')
                                 .as_sql
    # => "SELECT c FROM foo ORDER BY name DESC, id"

=item C<< stmt.add_group_by('foo'); >>

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

=item C<< stmt.limit(30) >>

=item C<< stmt.offset(5) >>

Add LIMIT and OFFSET.

    stmt = SQL::Maker::Select.new.add_select('c')
                                 .add_from('foo')
                                 .limit(30)
                                 .offset(5)
                                 .as_sql
    # => "SELECT c FROM foo LIMIT 30 OFFSET 5"

=item C<< stmt.add_having(:cnt => 2) >>

Add a HAVING clause.

    stmt = SQL::Maker::Select.new.add_from('foo')
                                 .add_select(sql_raw('COUNT(*)') => 'cnt')
                                 .add_having(:cnt => 2)
                                 .as_sql
    # => "SELECT COUNT(*) AS cnt FROM foo HAVING (COUNT(*) = ?)"

=back

=head1 SEE ALSO

L<Data::ObjectDriver::SQL>

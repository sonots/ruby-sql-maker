require_relative '../spec_helper'
require 'sql/maker/select_set'
require 'sql/maker/select'
require 'sql/maker/helper'

describe SQL::Maker::SelectSet do
  include SQL::Maker::Helper

  def ns
    SQL::Maker::Select.new( :quote_char => '', :name_sep => '.', :new_line => ' ' )
  end

  context 'basic' do
    let(:s1) do
      ns()
        .add_from( 'table1' )
        .add_select( 'id' )
        .add_where( :foo => 100 )
    end

    let(:s2) do
      ns()
        .add_from( 'table2' )
        .add_select( 'id' )
        .add_where( :bar => 200 )
    end

    let(:s3) do
      ns()
        .add_from( 'table3' )
        .add_select( 'id' )
        .add_where( :baz => 300 )
    end

    it 'error' do
      expect{ sql_union( s1, s2 ) }.not_to raise_error
      expect { SQL::Maker::SelectSet.sql_union( s1, s2 ) }.not_to raise_error
      expect { SQL::Maker::SelectSet.sql_union( s1 ) }.not_to raise_error
    end

    it 'sql_union' do
      set = sql_union( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) UNION SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set = sql_union( set, s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) UNION SELECT id FROM table2 WHERE (bar = ?) UNION SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_union( s3, sql_union( s1, s2 ) )
      expect(set.as_sql).to be == %q{SELECT id FROM table3 WHERE (baz = ?) UNION SELECT id FROM table1 WHERE (foo = ?) UNION SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '300, 100, 200'

      set = sql_union_all( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) UNION ALL SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set.add_order_by( 'id' )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) UNION ALL SELECT id FROM table2 WHERE (bar = ?) ORDER BY id}
      expect(set.bind.join(', ')).to be == '100, 200'

      set = sql_union( sql_union( s3, s1 ), s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table3 WHERE (baz = ?) UNION SELECT id FROM table1 WHERE (foo = ?) UNION SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '300, 100, 200'

      set = sql_union( sql_union( s1, s2 ), sql_union( s2, s3) )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) UNION SELECT id FROM table2 WHERE (bar = ?) UNION SELECT id FROM table2 WHERE (bar = ?) UNION SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 200, 300'
    end

    it 'sql_intersect' do
      set = sql_intersect( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) INTERSECT SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set = sql_intersect( set, s3)
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) INTERSECT SELECT id FROM table2 WHERE (bar = ?) INTERSECT SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_intersect( s3, sql_intersect( s1, s2 ) )
      expect(set.as_sql).to be == %q{SELECT id FROM table3 WHERE (baz = ?) INTERSECT SELECT id FROM table1 WHERE (foo = ?) INTERSECT SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '300, 100, 200'

      set = sql_intersect_all( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) INTERSECT ALL SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set.add_order_by( 'id' )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) INTERSECT ALL SELECT id FROM table2 WHERE (bar = ?) ORDER BY id}
      expect(set.bind.join(', ')).to be == '100, 200'
    end

    it 'sql_except' do
      set = sql_except( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set = sql_except( set, s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?) EXCEPT SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_except( s3, sql_except( s1, s2 ) )
      expect(set.as_sql).to be == %q{SELECT id FROM table3 WHERE (baz = ?) EXCEPT SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '300, 100, 200'

      set = sql_except_all( s1, s2 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT ALL SELECT id FROM table2 WHERE (bar = ?)}
      expect(set.bind.join(', ')).to be == '100, 200'

      set.add_order_by( 'id' )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT ALL SELECT id FROM table2 WHERE (bar = ?) ORDER BY id}
      expect(set.bind.join(', ')).to be == '100, 200'
    end

    it 'multiple' do
      set = sql_intersect( sql_except(s1, s2), s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?) INTERSECT SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_intersect_all( sql_except( s1, s2 ), s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?) INTERSECT ALL SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_union( sql_except( s1, s2), s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT SELECT id FROM table2 WHERE (bar = ?) UNION SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'

      set = sql_union( sql_except_all( s1, s2 ), s3 )
      expect(set.as_sql).to be == %q{SELECT id FROM table1 WHERE (foo = ?) EXCEPT ALL SELECT id FROM table2 WHERE (bar = ?) UNION SELECT id FROM table3 WHERE (baz = ?)}
      expect(set.bind.join(', ')).to be == '100, 200, 300'
    end
  end

  def check_sql(arg)
    lines = arg.split("\n")
    sql = ''
    lines.each do |line|
      line.gsub!(/^\s+/, '')
      line.gsub!(/^WHERE/, ' WHERE')
      line.gsub!(/^FROM/, ' FROM')
      line.gsub!(/^INNER/, ' INNER')
      line.gsub!(/^EXCEPT/, ' EXCEPT')
      line.gsub!(/^UNION/, ' UNION')
      sql += line
    end
    sql
  end

  context 'complex' do
    let(:s1) do
      ns.add_from( 'member' )
        .add_select('id')
        .add_select('created_on')
        .add_where( :is_deleted => 'f' )
    end

    let(:not_in) do
      ns.add_from('group_member')
        .add_select('member_id')
        .add_where( 'is_beginner' => 'f' )
    end

    let(:s2) do
      ns.add_from( s1, 'm1' )
        .add_select('m1.id')
        .add_select('m1.created_on')
        .add_where( 'm1.id' => { 'NOT IN' => not_in })
    end

    let(:s3) do
      ns.add_select('mi.id')
        .add_select( 'false', 'is_group' )
        .add_select('mi.created_on')
        .add_join( [s2, 'm2'] => { :table => 'member_index', :alias => 'mi', :type => 'inner', :condition => 'mi.id = m2.id' } )
        .add_where( 'mi.lang' => 'ja' )
    end

    it do
      expect(s1.as_sql).to be == "SELECT id, created_on FROM member WHERE (is_deleted = ?)"

      expect(not_in.as_sql).to be == "SELECT member_id FROM group_member WHERE (is_beginner = ?)"

      expect(s2.as_sql).to be == check_sql(<<SQL)
SELECT m1.id, m1.created_on
FROM (SELECT id, created_on FROM member WHERE (is_deleted = ?)) m1
WHERE (m1.id NOT IN (SELECT member_id FROM group_member WHERE (is_beginner = ?)))
SQL

      expect(s3.as_sql).to be == check_sql(<<SQL)
SELECT mi.id, false AS is_group, mi.created_on
    FROM (
        SELECT m1.id, m1.created_on FROM (
            SELECT id, created_on FROM member WHERE (is_deleted = ?)
        ) m1 WHERE (m1.id NOT IN (SELECT member_id FROM group_member WHERE (is_beginner = ?)))
    ) m2 INNER JOIN member_index mi ON mi.id = m2.id WHERE (mi.lang = ?)
SQL
      expect(s3.bind.join(', ')).to be == 'f, f, ja'

      s4 = ns.add_join(
        ['group', 'g1'] => {
          :table => 'group_member', :alias => 'gm1',
          :type => 'inner', :condition => 'gm1.member_id = g1.id'
        }
      ).add_join(
        ['group', 'g1'] => {
          :table => 'member', :alias => 'm3',
          :type => 'inner', :condition => 'gm1.member_id = m3.id'
        }
      ).add_select( 'g1.id' )
        .add_where( 'g1.type' => 'hoge' )

      expect(s4.as_sql).to be == "SELECT g1.id FROM group g1 INNER JOIN group_member gm1 ON gm1.member_id = g1.id INNER JOIN member m3 ON gm1.member_id = m3.id WHERE (g1.type = ?)"

      not_in2 = ns.add_select('id')
        .add_from('member')
        .add_where( 'is_monger' => 't' )

      s5 = ns.add_select( 'g2.id' ).add_join(
        ['group', 'g2'] => {
          :table => 'group_member', :alias => 'gm2',
          :type => 'inner', :condition => 'gm2.member_id = g2.id'
        }
      ).add_where( 'gm2.member_id' => { 'NOT IN' => not_in2 })
        .add_where( 'g2.is_deleted' => 'f' )

      expect(s5.as_sql).to be == "SELECT g2.id FROM group g2 INNER JOIN group_member gm2 ON gm2.member_id = g2.id WHERE (gm2.member_id NOT IN (SELECT id FROM member WHERE (is_monger = ?))) AND (g2.is_deleted = ?)"

      set = sql_except( s4, s5 )

      s6 = ns.add_join(
        [set, 'g'] => {
          :table => 'group_index', :alias => 'gi',
          :type => 'inner', :condition => 'gi.id = g.id'
        }
      ).add_select( 'g.id' )
        .add_select( 'true', 'is_group' )
        .add_select( 'gsi.created_on' )
        .add_where( 'gi.lang' => 'ja' )

      expect(s6.as_sql).to be == check_sql(<<SQL)
SELECT g.id, true AS is_group, gsi.created_on
    FROM (
    SELECT g1.id FROM group g1
        INNER JOIN group_member gm1 ON gm1.member_id = g1.id
        INNER JOIN member m3 ON gm1.member_id = m3.id
        WHERE (g1.type = ?)
    EXCEPT 
    SELECT g2.id FROM group g2
        INNER JOIN group_member gm2 ON gm2.member_id = g2.id
        WHERE (gm2.member_id NOT IN (
            SELECT id FROM member WHERE (is_monger = ?)
        )) AND (g2.is_deleted = ?)
    ) g INNER JOIN group_index gi ON gi.id = g.id WHERE (gi.lang = ?)
SQL

      expect(s6.bind.join(', ')).to be == 'hoge, t, f, ja'

      set = sql_union( s3, s6 )

      s7 = ns.add_select( 'id' )
        .add_select( 'is_group' )
        .add_from( set, 'list_table' )
        .add_order_by( 'created_on' )


      expect(s7.as_sql).to be == check_sql(<<SQL)
SELECT id, is_group FROM (
    SELECT mi.id, false AS is_group, mi.created_on
        FROM (
            SELECT m1.id, m1.created_on FROM (
                SELECT id, created_on FROM member WHERE (is_deleted = ?)
            ) m1 WHERE (m1.id NOT IN (SELECT member_id FROM group_member WHERE (is_beginner = ?)))
        ) m2 INNER JOIN member_index mi ON mi.id = m2.id WHERE (mi.lang = ?)
    UNION 
    SELECT g.id, true AS is_group, gsi.created_on
        FROM (
        SELECT g1.id FROM group g1
            INNER JOIN group_member gm1 ON gm1.member_id = g1.id
            INNER JOIN member m3 ON gm1.member_id = m3.id
            WHERE (g1.type = ?)
        EXCEPT 
            SELECT g2.id FROM group g2
            INNER JOIN group_member gm2 ON gm2.member_id = g2.id
            WHERE (gm2.member_id NOT IN (
                SELECT id FROM member WHERE (is_monger = ?)
            )) AND (g2.is_deleted = ?)
        ) g INNER JOIN group_index gi ON gi.id = g.id WHERE (gi.lang = ?)
) list_table ORDER BY created_on
SQL

      expect(s7.bind.join(', ')).to be == 'f, f, ja, hoge, t, f, ja'
    end
  end
end

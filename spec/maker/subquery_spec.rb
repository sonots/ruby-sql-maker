require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  context 'select_subquery' do
    context 'driver: sqlite' do
      builder = SQL::Maker.new(:driver => 'sqlite')

      it do
        stmt1 = builder.select_query('sakura', ['hoge', 'fuga'], {:fuga => 'piyo', :zun => 'doko'})
        expect(stmt1.as_sql).to be == %Q{SELECT "hoge", "fuga"\nFROM "sakura"\nWHERE ("fuga" = ?) AND ("zun" = ?)}
        expect(stmt1.bind.join(',')).to be == 'piyo,doko'

        stmt2 = builder.select_query([stmt1,'stmt1'], ['foo', 'bar'], {:bar => 'baz', :john => 'man'})
        expect(stmt2.as_sql).to be == %Q{SELECT "foo", "bar"\nFROM (SELECT "hoge", "fuga"\nFROM "sakura"\nWHERE ("fuga" = ?) AND ("zun" = ?)), "stmt1"\nWHERE ("bar" = ?) AND ("john" = ?)}
        expect(stmt2.bind.join(',')).to be == 'piyo,doko,baz,man'

        stmt3 = builder.select_query([stmt2,'stmt2'], ['baz'], {'baz'=>'bar'}, {:order_by => 'yo'})
        expect(stmt3.as_sql).to be == %Q{SELECT "baz"\nFROM (SELECT "foo", "bar"\nFROM (SELECT "hoge", "fuga"\nFROM "sakura"\nWHERE ("fuga" = ?) AND ("zun" = ?)), "stmt1"\nWHERE ("bar" = ?) AND ("john" = ?)), "stmt2"\nWHERE ("baz" = ?)\nORDER BY "yo"}
        expect(stmt3.bind.join(',')).to be == 'piyo,doko,baz,man,bar'
      end

      #it 'no infinite loop' do
      #  stmt = builder.new_select
      #  stmt.add_select( 'id' )
      #  stmt.add_where( 'foo'=>'bar' )
      #  stmt.add_from( stmt, 'itself' )

      #  expect(stmt.as_sql).to be == %Q{SELECT "id"\nFROM (SELECT "id"\nFROM \nWHERE ("foo" = ?)), "itself"\nWHERE ("foo" = ?)} 
      #  expect(stmt.bind.join(',')).to be == 'bar,bar'
      #end
    end
  end

  it 'subquery_and_join' do
    subquery = SQL::Maker::Select.new( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
    subquery.add_select('*')
    subquery.add_from( 'foo' )
    subquery.add_where( 'hoge' => 'fuga' )

    stmt = SQL::Maker::Select.new( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
    stmt.add_join(
      [ subquery, 'bar' ] => {
        :type      => 'inner',
        :table     => 'baz',
        :alias     => 'b1',
        :condition => 'bar.baz_id = b1.baz_id'
      },
    )
    expect(stmt.as_sql).to be == "FROM (SELECT * FROM foo WHERE (hoge = ?)) bar INNER JOIN baz b1 ON bar.baz_id = b1.baz_id"
    expect(stmt.bind.join(',')).to be == 'fuga'
  end

  it 'complex' do
    s1 = SQL::Maker::Select.new( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
    s1.add_select('*')
    s1.add_from( 'foo' )
    s1.add_where( 'hoge' => 'fuga' )

    s2 = SQL::Maker::Select.new( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
    s2.add_select('*')
    s2.add_from( s1, 'f' )
    s2.add_where( 'piyo' => 'puyo' )

    stmt = SQL::Maker::Select.new( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
    stmt.add_join(
      [ s2, 'bar' ] => {
        :type      => 'inner',
        :table     => 'baz',
        :alias     => 'b1',
        :condition => 'bar.baz_id = b1.baz_id'
      },
    )
    expect(stmt.as_sql).to be == "FROM (SELECT * FROM (SELECT * FROM foo WHERE (hoge = ?)) f WHERE (piyo = ?)) bar INNER JOIN baz b1 ON bar.baz_id = b1.baz_id"
    expect(stmt.bind.join(',')).to be == 'fuga,puyo'
  end
end

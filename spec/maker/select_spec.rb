require_relative '../spec_helper'
require 'sql/maker'
require 'sql/maker/helper'

describe 'SQL::Maker#select' do
  include SQL::Maker::Helper

  context 'driver: sqlite' do
    builder = SQL::Maker.new(:driver => 'sqlite')

    it 'columns and tables' do
      sql, bind = builder.select( 'foo', [ '*' ] )
      expect(sql).to be == %Q{SELECT *\nFROM "foo"}
      expect(bind.join(',')).to be == ''
    end

    it 'scalar ref columns and tables' do
      sql, bind = builder.select( 'foo', [ sql_raw('bar'), sql_raw('baz') ] )
      expect(sql).to be == %Q{SELECT bar, baz\nFROM "foo"}
      expect(bind.join(',')).to be == ''
    end

    it 'columns with alias column and tables' do
      sql, bind = builder.select( 'foo', [ 'foo', {:bar => 'barbar'} ] )
      expect(sql).to be == %Q{SELECT "foo", "bar" AS "barbar"\nFROM "foo"}
      expect(bind.join(',')).to be == ''
    end

    it 'columns and tables, where cause (hash ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (array ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (condition)' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], cond )
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (hash ref), order by' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => sql_raw('yo')})
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY yo}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (array ref), order by' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY "yo"}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (condition), order by' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select( 'foo', ['foo', 'bar'], cond, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY "yo"}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (array ref), order by, limit, offset' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo', :limit => 1, :offset => 3})
      expect(sql).to be == %Q{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY "yo"\nLIMIT 1 OFFSET 3}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'modify prefix' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {}, { :prefix => 'SELECT SQL_CALC_FOUND_ROWS '} )
      expect(sql).to be == %Q{SELECT SQL_CALC_FOUND_ROWS "foo", "bar"\nFROM "foo"}
      expect(bind.join(',')).to be == ''
    end

    context 'order_by' do
      it 'scalar' do
        sql, bind = builder.select('foo', ['*'] , {}, {:order_by => sql_raw('yo')})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nORDER BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nORDER BY "yo" DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => [sql_raw('yo'), sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nORDER BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => [{'yo' => 'DESC'}, sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nORDER BY "yo" DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'group_by' do
      it 'scalar' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => sql_raw('yo')})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nGROUP BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nGROUP BY "yo" DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => [sql_raw('yo'), sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nGROUP BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => [{'yo' => 'DESC'}, sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM "foo"\nGROUP BY "yo" DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'from' do
      it 'multi from' do
        sql, bind = builder.select( %w/foo bar/, ['*'], {} )
        expect(sql).to be == %Q{SELECT *\nFROM "foo", "bar"}
        expect(bind.join(',')).to be == ''
      end

      it 'multi from with alias' do
        sql, bind = builder.select( [ { :foo => 'f' }, { :bar => 'b' } ], ['*'], {} )
        expect(sql).to be == %Q{SELECT *\nFROM "foo" "f", "bar" "b"}
        expect(bind.join(',')).to be == ''
      end
    end

    it 'join' do
        sql, bind = builder.select(nil, ['*'], {}, {:joins => {
            :foo => {
                :type      => 'LEFT OUTER',
                :table     => 'bar',
                :condition => 'foo.bar_id = bar.id',
            }
        }})
        expect(sql).to be == %Q{SELECT *\nFROM "foo" LEFT OUTER JOIN "bar" ON foo.bar_id = bar.id}
        expect(bind.join(',')).to be == ''
    end
  end

  context 'driver: mysql' do
    builder = SQL::Maker.new(:driver => 'mysql')

    it 'columns and tables' do
      sql, bind = builder.select( 'foo', [ '*' ])
      expect(sql).to be == %Q{SELECT *\nFROM `foo`}
      expect(bind.join(',')).to be == ''
    end

    it 'columns with alias column and tables' do
      sql, bind = builder.select( 'foo', [ 'foo', {:bar => 'barbar'} ])
      expect(sql).to be == %Q{SELECT `foo`, `bar` AS `barbar`\nFROM `foo`}
      expect(bind.join(',')).to be == ''
    end

    it 'scalar ref columns and tables' do
      sql, bind = builder.select( 'foo', [ sql_raw('bar'), sql_raw('baz') ])
      expect(sql).to be == %Q{SELECT bar, baz\nFROM `foo`}
      expect(bind.join(',')).to be == ''
    end

    it 'columns and tables, where cause (hash ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (array ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (condition)' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], cond )
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (hash ref), order by' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY `yo`}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (array ref), order by' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY `yo`}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (condition), order by' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select( 'foo', ['foo', 'bar'], cond, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY `yo`}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (array ref), order by, limit, offset' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => sql_raw('yo'), :limit => 1, :offset => 3})
      expect(sql).to be == %Q{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY yo\nLIMIT 1 OFFSET 3}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'modify prefix' do
      sql, bind = builder.select( 'foo', ['foo', 'bar'], {}, { :prefix => 'SELECT SQL_CALC_FOUND_ROWS '} )
      expect(sql).to be == %Q{SELECT SQL_CALC_FOUND_ROWS `foo`, `bar`\nFROM `foo`}
      expect(bind.join(',')).to be == ''
    end

    context 'order_by' do
      it 'scalar' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:order_by => sql_raw('yo')})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nORDER BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:order_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nORDER BY `yo` DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:order_by => [sql_raw('yo'), sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nORDER BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:order_by => [{'yo' => 'DESC'}, sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nORDER BY `yo` DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'group_by' do
      it 'scalar' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:group_by => sql_raw('yo')})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nGROUP BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:group_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nGROUP BY `yo` DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:group_by => [sql_raw('yo'), sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nGROUP BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select( 'foo', ['*'], {}, {:group_by => [{'yo' => 'DESC'}, sql_raw('ya')]})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`\nGROUP BY `yo` DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'from' do
      it 'multi from' do
        sql, bind = builder.select( %w/foo bar/, ['*'], {})
        expect(sql).to be == %Q{SELECT *\nFROM `foo`, `bar`}
        expect(bind.join(',')).to be == ''
      end

      it 'multi from with alias' do
        sql, bind = builder.select( [{ :foo => 'f' }, { :bar => 'b' }], ['*'], {})
        expect(sql).to be == %Q{SELECT *\nFROM `foo` `f`, `bar` `b`}
        expect(bind.join(',')).to be == ''
      end
    end

    it 'join' do
      sql, bind = builder.select( nil, ['*'], {}, {:joins => {
        :foo => {
          :type      => 'LEFT OUTER',
          :table     => 'bar',
          :condition => 'foo.bar_id = bar.id',
        }
      }})
      expect(sql).to be == %Q{SELECT *\nFROM `foo` LEFT OUTER JOIN `bar` ON foo.bar_id = bar.id}
      expect(bind.join(',')).to be == ''
    end
  end

  context 'driver: mysql, quote_char: "", new_line: " "' do
    builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')

    it 'columns and tables' do
      sql, bind = builder.select( 'foo', [ '*' ] )
      expect(sql).to be == %Q{SELECT * FROM foo}
      expect(bind.join(',')).to be == ''
    end

    it 'columns and tables, where cause (hash ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (array ref)' do
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], { :bar => 'baz', :john => 'man' } )
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (condition)' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select( 'foo', [ 'foo', 'bar' ], cond )
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and tables, where cause (hash ref), order by' do
      sql, bind = builder.select('foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo}
      expect(bind.join(',')).to be == 'baz,man'
    end

    # it 'columns and table, where cause (array ref), order by' do

    it 'columns and table, where cause (condition), order by' do
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.select('foo', ['foo', 'bar'], cond, {:order_by => 'yo'})
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'columns and table, where cause (array ref), order by, limit, offset' do
      sql, bind = builder.select('foo', ['foo', 'bar'], {:bar => 'baz', :john => 'man'}, {:order_by => 'yo', :limit => 1, :offset => 3})
      expect(sql).to be == %Q{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo LIMIT 1 OFFSET 3}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'modify prefix' do
      sql, bind = builder.select('foo', ['foo', 'bar'], {}, {:prefix => 'SELECT SQL_CALC_FOUND_ROWS '})
      expect(sql).to be == %Q{SELECT SQL_CALC_FOUND_ROWS foo, bar FROM foo}
      expect(bind.join(',')).to be == ''
    end

    context 'order_by' do
      it 'scalar' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => 'yo'})
        expect(sql).to be == %Q{SELECT * FROM foo ORDER BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT * FROM foo ORDER BY yo DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => ['yo', 'ya']})
        expect(sql).to be == %Q{SELECT * FROM foo ORDER BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select('foo', ['*'], {}, {:order_by => [{'yo' => 'DESC'}, 'ya']})
        expect(sql).to be == %Q{SELECT * FROM foo ORDER BY yo DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'group_by' do
      it 'scalar' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => 'yo'})
        expect(sql).to be == %Q{SELECT * FROM foo GROUP BY yo}
        expect(bind.join(',')).to be == ''
      end

      it 'hash ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => {'yo' => 'DESC'}})
        expect(sql).to be == %Q{SELECT * FROM foo GROUP BY yo DESC}
        expect(bind.join(',')).to be == ''
      end

      it 'array ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => ['yo', 'ya']})
        expect(sql).to be == %Q{SELECT * FROM foo GROUP BY yo, ya}
        expect(bind.join(',')).to be == ''
      end

      it 'mixed' do
        sql, bind = builder.select('foo', ['*'], {}, {:group_by => [{'yo' => 'DESC'}, 'ya']})
        expect(sql).to be == %Q{SELECT * FROM foo GROUP BY yo DESC, ya}
        expect(bind.join(',')).to be == ''
      end
    end

    context 'index_hint' do
      it 'scalar' do
        sql, bind = builder.select('foo', ['*'], {}, {:index_hint => 'bar'})
        expect(sql).to be == %Q{SELECT * FROM foo USE INDEX (bar)}
      end

      it 'array ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:index_hint => ['bar', 'baz']})
        expect(sql).to be == %Q{SELECT * FROM foo USE INDEX (bar,baz)}
      end

      it 'hash ref' do
        sql, bind = builder.select('foo', ['*'], {}, {:index_hint => {:type => 'FORCE', :list => ['bar']}})
        expect(sql).to be == %Q{SELECT * FROM foo FORCE INDEX (bar)}
      end
    end

    context 'from' do
      it 'multi from' do
        sql, bind = builder.select(%w/foo bar/, ['*'], {}, )
        expect(sql).to be == %Q{SELECT * FROM foo, bar}
        expect(bind.join(',')).to be == ''
      end

      it 'multi from with alias' do
        sql, bind = builder.select([ { :foo => 'f' }, { :bar => 'b' } ], ['*'], {})
        expect(sql).to be == %Q{SELECT * FROM foo f, bar b}
        expect(bind.join(',')).to be == ''
      end
    end

    it 'join' do
      sql, bind = builder.select(nil, ['*'], {}, {:joins => {
        :foo => {
          :type      => 'LEFT OUTER',
          :table     => 'bar',
          :condition => 'foo.bar_id = bar.id',
        }
      }})
      expect(sql).to be == %Q{SELECT * FROM foo LEFT OUTER JOIN bar ON foo.bar_id = bar.id}
      expect(bind.join(',')).to be == ''
    end
  end
end

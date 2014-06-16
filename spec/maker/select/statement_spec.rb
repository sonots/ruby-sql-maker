require_relative '../../spec_helper'
require 'sql/maker/select'

describe 'SQL::Maker::Select' do
  def ns(args)
    SQL::Maker::Select.new(args)
  end

  context 'PREFIX' do
    context 'quote_char: "`", name_sep: "."' do
      it 'simple' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_select('*')
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "SELECT *\nFROM `foo`"
      end

      it 'SQL_CALC_FOUND_ROWS' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.prefix('SELECT SQL_CALC_FOUND_ROWS ')
        stmt.add_select('*')
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "SELECT SQL_CALC_FOUND_ROWS *\nFROM `foo`"
      end
    end

    context 'quote_char: "", name_sep: ".", new_line: " "' do
      it 'simple' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ })
        stmt.add_select('*')
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "SELECT * FROM foo"
      end

      it 'SQL_CALC_FOUND_ROWS' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.prefix('SELECT SQL_CALC_FOUND_ROWS ')
        stmt.add_select('*')
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "SELECT SQL_CALC_FOUND_ROWS * FROM foo"
      end
    end
  end

  context 'FROM' do
    context 'quote_char: "`", name_sep: "."' do
      it 'single' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "FROM `foo`"
      end

      it 'multi' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_from( 'bar' )
        expect(stmt.as_sql).to be == "FROM `foo`, `bar`"
      end

      it 'multi + alias' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' => 'f' )
        stmt.add_from( 'bar' => 'b' )
        expect(stmt.as_sql).to be == "FROM `foo` `f`, `bar` `b`"
      end
    end

    context 'quote_char: "", name_sep: ".", new_line: " "' do
      it 'single' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from('foo')
        expect(stmt.as_sql).to be == "FROM foo"
      end

      it 'multi' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.add_from( 'bar' )
        expect(stmt.as_sql).to be == "FROM foo, bar"
      end

      it 'multi + alias' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' => 'f' )
        stmt.add_from( 'bar' => 'b' )
        expect(stmt.as_sql).to be == "FROM foo f, bar b"
      end
    end
  end

  context 'JOIN' do
    context 'quote_char: "`", name_sep: "."' do
      it 'inner join' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
          }
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz`"
      end

      it 'inner join with condition' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => 'foo.baz_id = baz.baz_id'
          }
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` ON foo.baz_id = baz.baz_id"
      end

      it 'from and inner join with condition' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'bar' )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => 'foo.baz_id = baz.baz_id'
          }
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` ON foo.baz_id = baz.baz_id, `bar`"
      end

      it 'inner join with hash condition' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => {'foo.baz_id' => 'baz.baz_id'},
          }
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` ON `foo`.`baz_id` = `baz`.`baz_id`"
      end

      it 'inner join with hash condition with multi keys' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => {
              'foo.baz_id' => 'baz.baz_id',
              'foo.status' => 'baz.status',
            },
          }
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` ON `foo`.`baz_id` = `baz`.`baz_id` AND `foo`.`status` = `baz`.`status`"
      end

      it 'test case for bug found where add_join is called twice' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :alias     => 'b1',
            :condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1'
          },
        )
        stmt.add_join(
          :foo => {
            :type      => 'left',
            :table     => 'baz',
            :alias     => 'b2',
            :condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2'
          },
        )
        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` `b1` ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN `baz` `b2` ON foo.baz_id = b2.baz_id AND b2.quux_id = 2"
      end

      it 'test case adding another table onto the whole mess' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :alias     => 'b1',
            :condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1'
          },
        )
        stmt.add_join(
          :foo => {
            :type      => 'left',
            :table     => 'baz',
            :alias     => 'b2',
            :condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2'
          },
        )
        stmt.add_join(
          :quux => {
            :type      => 'inner',
            :table     => 'foo',
            :alias     => 'f1',
            :condition => 'f1.quux_id = quux.q_id'
          }
        )

        expect(stmt.as_sql).to be == "FROM `foo` INNER JOIN `baz` `b1` ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN `baz` `b2` ON foo.baz_id = b2.baz_id AND b2.quux_id = 2 INNER JOIN `foo` `f1` ON f1.quux_id = quux.q_id"
      end

      context 'quote_char: "", name_sep: ".", new_line: " "' do
        it 'inner join' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_join(
            :foo => {
              :type      => 'inner',
              :table     => 'baz',
            }
          )
          expect(stmt.as_sql).to be == "FROM foo INNER JOIN baz"
        end

        it 'inner join with condition' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_join(
            :foo => {
              :type      => 'inner',
              :table     => 'baz',
              :condition => 'foo.baz_id = baz.baz_id'
            }
          )
          expect(stmt.as_sql).to be == "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id"
        end

        it 'from and inner join with condition' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_from( 'bar' )
          stmt.add_join(
            :foo => {
              :type      => 'inner',
              :table     => 'baz',
              :condition => 'foo.baz_id = baz.baz_id'
            }
          )
          expect(stmt.as_sql).to be == "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id, bar"
        end

        it 'test case for bug found where add_join is called twice' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_join(
            :foo => {
              :type      => 'inner',
              :table     => 'baz',
              :alias     => 'b1',
              :condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1'
            },
          )
          stmt.add_join(
            :foo => {
              :type      => 'left',
              :table     => 'baz',
              :alias     => 'b2',
              :condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2'
            },
          )
          expect(stmt.as_sql).to be == "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2"
        end

        it 'test case adding another table onto the whole mess' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_join(
            :foo => {
              :type      => 'inner',
              :table     => 'baz',
              :alias     => 'b1',
              :condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1'
            },
          )
          stmt.add_join(
            :foo => {
              :type      => 'left',
              :table     => 'baz',
              :alias     => 'b2',
              :condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2'
            },
          )
          stmt.add_join(
            :quux => {
              :type      => 'inner',
              :table     => 'foo',
              :alias     => 'f1',
              :condition => 'f1.quux_id = quux.q_id'
            }
          ) 
          expect(stmt.as_sql).to be == "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2 INNER JOIN foo f1 ON f1.quux_id = quux.q_id"
        end
      end
    end 
  end

  context 'GROUP BY' do
    context 'quote_char: "`", name_sep: "."' do
      it do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz')
        expect(stmt.as_sql).to be == "FROM `foo`\nGROUP BY `baz`" # 'single bare group by'
      end

      it do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz' => 'DESC')
        expect(stmt.as_sql).to be == "FROM `foo`\nGROUP BY `baz` DESC" # 'single group by with desc'
      end

      it do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz')
        stmt.add_group_by('quux')
        expect(stmt.as_sql).to be == "FROM `foo`\nGROUP BY `baz`, `quux`" # 'multiple group by'
      end

      it do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz',  'DESC')
        stmt.add_group_by('quux', 'DESC')
        expect(stmt.as_sql).to be == "FROM `foo`\nGROUP BY `baz` DESC, `quux` DESC" # 'multiple group by with desc'
      end
    end

    context 'quote_char: "", name_sep: ".", new_line: " "' do
      it do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz')
        expect(stmt.as_sql).to be == "FROM foo GROUP BY baz" # 'single bare group by'
      end

      it do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz' => 'DESC')
        expect(stmt.as_sql).to be == "FROM foo GROUP BY baz DESC" # 'single group by with desc'
      end

      it do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz')
        stmt.add_group_by('quux')
        expect(stmt.as_sql).to be == "FROM foo GROUP BY baz, quux" # 'multiple group by'
      end

      it do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.add_group_by('baz',  'DESC')
        stmt.add_group_by('quux', 'DESC')
        expect(stmt.as_sql).to be == "FROM foo GROUP BY baz DESC, quux DESC" # 'multiple group by with desc'
      end
    end

    context 'ORDER BY' do
      context 'quote_char: "`", name_sep: "."' do
        it do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_from( 'foo' )
          stmt.add_order_by('baz' => 'DESC')
          expect(stmt.as_sql).to be == "FROM `foo`\nORDER BY `baz` DESC" # 'single order by'
        end

        it do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_from( 'foo' )
          stmt.add_order_by( 'baz' => 'DESC' )
          stmt.add_order_by( 'quux' => 'ASC' )
          expect(stmt.as_sql).to be == "FROM `foo`\nORDER BY `baz` DESC, `quux` ASC" # 'multiple order by'
        end

        # it do
        #   stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        #   stmt.add_from( 'foo' )
        #   stmt.add_order_by( \'baz DESC' )
        #   expect(stmt.as_sql).to be == "FROM `foo`\nORDER BY baz DESC" # should not quote
        # end
      end

      context 'quote_char: "", name_sep: ".", new_line: " "' do
        it do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_from( 'foo' )
          stmt.add_order_by('baz' => 'DESC')
          expect(stmt.as_sql).to be == "FROM foo ORDER BY baz DESC" # 'single order by'
        end

        it do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ })
          stmt.add_from( 'foo' )
          stmt.add_order_by( 'baz' => 'DESC' )
          stmt.add_order_by( 'quux' => 'ASC' )
          expect(stmt.as_sql).to be == "FROM foo ORDER BY baz DESC, quux ASC" # 'multiple order by'
        end

        # it 'scalarref' do
        #   stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ })
        #   stmt.add_from( 'foo' )
        #   stmt.add_order_by( 'baz DESC' )
        #   expect(stmt.as_sql).to be == "FROM foo ORDER BY baz DESC" # should not quote
        # end
      end
    end

    context 'GROUP BY + ORDER BY' do
      it 'quote_char: "`", name_sep: "."' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.add_group_by('quux')
        stmt.add_order_by('baz' => 'DESC')
        expect(stmt.as_sql).to be == "FROM `foo`\nGROUP BY `quux`\nORDER BY `baz` DESC" # 'group by with order by'
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ })
        stmt.add_from( 'foo' )
        stmt.add_group_by('quux')
        stmt.add_order_by('baz' => 'DESC')
        expect(stmt.as_sql).to be == "FROM foo GROUP BY quux ORDER BY baz DESC" # 'group by with order by'
      end
    end

    context 'LIMIT OFFSET' do
      it 'quote_char: "`", name_sep: "."' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_from( 'foo' )
        stmt.limit(5)
        expect(stmt.as_sql).to be == "FROM `foo`\nLIMIT 5"
        stmt.offset(10)
        expect(stmt.as_sql).to be == "FROM `foo`\nLIMIT 5 OFFSET 10"
        stmt.limit("  15g");  ## Non-numerics should cause an error
        expect { stmt.as_sql }.to raise_error("Non-numerics in limit clause (n)") # "bogus limit causes as_sql assertion")
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_from( 'foo' )
        stmt.limit(5)
        expect(stmt.as_sql).to be == "FROM foo LIMIT 5"
        stmt.offset(10)
        expect(stmt.as_sql).to be == "FROM foo LIMIT 5 OFFSET 10"
        stmt.limit("  15g");  ## Non-numerics should cause an error
        expect { stmt.as_sql }.to raise_error("Non-numerics in limit clause (n)") # bogus limit causes as_sql assertion")
      end
    end

    context 'WHERE' do
      context 'quote_char: "`", name_sep: "."' do
        it 'single equals' do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_where(:foo => 'bar')
          expect(stmt.as_sql_where).to be == "WHERE (`foo` = ?)\n"
          expect(stmt.bind.size).to be == 1
          expect(stmt.bind[0]).to be == 'bar'
        end

        it 'single equals multi values is IN() statement' do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_where(:foo => [ 'bar', 'baz' ])
          expect(stmt.as_sql_where).to be == "WHERE (`foo` IN (?, ?))\n"
          expect(stmt.bind.size).to be == 2
          expect(stmt.bind[0]).to be == 'bar'
          expect(stmt.bind[1]).to be == 'baz'
        end

        it 'new condition, single equals multi values is IN() statement' do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          cond =  stmt.new_condition()
          cond.add(:foo => [ 'bar', 'baz' ])
          stmt.set_where(cond)
          expect(stmt.as_sql_where).to be == "WHERE (`foo` IN (?, ?))\n"
          expect(stmt.bind.size).to be == 2
          expect(stmt.bind[0]).to be == 'bar'
          expect(stmt.bind[1]).to be == 'baz'
        end
      end

      context 'quote_char: "", name_sep: ".", new_line: " "' do
        it 'single equals' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_where(:foo => 'bar')
          expect(stmt.as_sql_where).to be == "WHERE (foo = ?) "
          expect(stmt.bind.size).to be == 1
          expect(stmt.bind[0]).to be == 'bar'
        end

        it 'single equals multi values is IN() statement' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_where(:foo => [ 'bar', 'baz' ])
          expect(stmt.as_sql_where).to be == "WHERE (foo IN (?, ?)) "
          expect(stmt.bind.size).to be == 2
          expect(stmt.bind[0]).to be == 'bar'
          expect(stmt.bind[1]).to be == 'baz'
        end

        it 'new condition, single equals multi values is IN() statement' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          cond =  stmt.new_condition()
          cond.add(:foo => [ 'bar', 'baz' ])
          stmt.set_where(cond)
          expect(stmt.as_sql_where).to be == "WHERE (foo IN (?, ?)) "
          expect(stmt.bind.size).to be == 2
          expect(stmt.bind[0]).to be == 'bar'
          expect(stmt.bind[1]).to be == 'baz'
        end
      end
    end

    context 'add_select' do
      context 'quote_char: "`", name_sep: "."' do
        it 'simple' do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_select(:foo => 'foo')
          stmt.add_select('bar')
          stmt.add_from( %w( baz ) )
          expect(stmt.as_sql).to be == "SELECT `foo`, `bar`\nFROM `baz`"
        end

        #it 'with scalar ref' do
        #  stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        #  stmt.add_select('f.foo' => 'foo')
        #  stmt.add_select(\'COUNT(*)' => 'count')
        #  stmt.add_from( %w( baz ) )
        #  expect(stmt.as_sql).to be == "SELECT `f`.`foo`, COUNT(*) AS `count`\nFROM `baz`"
        #end
      end

      context 'quote_char: "", name_sep: ".", new_line: " "' do
        it 'simple' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_select(:foo => 'foo')
          stmt.add_select('bar')
          stmt.add_from( %w( baz ) )
          expect(stmt.as_sql).to be == "SELECT foo, bar FROM baz"
        end

        it 'with scalar ref' do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_select('f.foo' => 'foo')
          stmt.add_select('COUNT(*)' => 'count')
          stmt.add_from( %w( baz ) )
          expect(stmt.as_sql).to be == "SELECT f.foo, COUNT(*) AS count FROM baz"
        end
      end
    end

    context 'HAVING' do
      # it 'quote_char: "`", name_sep: "."' do
      #   stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
      #   stmt.add_select(:foo => 'foo')
      #   stmt.add_select(\'COUNT(*)' => 'count')
      #   stmt.add_from( %w(baz) )
      #   stmt.add_where(:foo => 1)
      #   stmt.add_group_by('baz')
      #   stmt.add_order_by('foo' => 'DESC')
      #   stmt.limit(2)
      #   stmt.add_having(:count => 2)
      #   #expect(stmt.as_sql).to be == "SELECT `foo`, COUNT(*) AS `count`\nFROM `baz`\nWHERE (`foo` = ?)\nGROUP BY `baz`\nHAVING (COUNT(*) = ?)\nORDER BY `foo` DESC\nLIMIT 2"
      #   expect(stmt.as_sql).to be == "SELECT `foo`, COUNT(*) AS `count`\nFROM `baz`\nWHERE (`foo` = ?)\nGROUP BY `baz`\nHAVING (COUNT(*) = ?)\nORDER BY `foo` DESC\nLIMIT 2"
      # end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_select('COUNT(*)' => 'count')
        stmt.add_from( %w(baz) )
        stmt.add_where(:foo => 1)
        stmt.add_group_by('baz')
        stmt.add_order_by('foo' => 'DESC')
        stmt.limit(2)
        stmt.add_having(:count => 2)
        expect(stmt.as_sql).to be == "SELECT foo, COUNT(*) AS count FROM baz WHERE (foo = ?) GROUP BY baz HAVING (COUNT(*) = ?) ORDER BY foo DESC LIMIT 2"
      end
    end

    context 'DISTINCT' do
      it 'quote_char: "`", name_sep: "."' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz`"
        stmt.distinct(1)
        expect(stmt.as_sql).to be == "SELECT DISTINCT `foo`\nFROM `baz`"
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        expect(stmt.as_sql).to be == "SELECT foo FROM baz" # "DISTINCT is absent by default"
        stmt.distinct(1)
        expect(stmt.as_sql).to be == "SELECT DISTINCT foo FROM baz" # "we can turn on DISTINCT"
      end
    end

    context 'index hint' do
      it 'quote_char: "`", name_sep: "."' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz`" # "index hint is absent by default"
        stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
        expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz` USE INDEX (`index_hint`)" # "we can turn on USE INDEX"
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        expect(stmt.as_sql).to be == "SELECT foo FROM baz" # "index hint is absent by default"
        stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
        expect(stmt.as_sql).to be == "SELECT foo FROM baz USE INDEX (index_hint)" # "we can turn on USE INDEX"
      end

      it 'hint as scalar' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        stmt.add_index_hint('baz' => 'index_hint')
        expect(stmt.as_sql).to be == "SELECT foo FROM baz USE INDEX (index_hint)" # "we can turn on USE INDEX"
      end

      it 'hint as array ref' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_from( %w(baz) )
        stmt.add_index_hint('baz' => ['index_hint'])
        expect(stmt.as_sql).to be == "SELECT foo FROM baz USE INDEX (index_hint)" # "we can turn on USE INDEX"
      end
    end

    context 'index hint with joins' do
      context 'quote_char: "`", name_sep: "."' do
        it do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_select(:foo => 'foo')
          stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
          stmt.add_join(
            :baz => {
              :type      => 'inner',
              :table     => 'baz',
              :condition => 'baz.baz_id = foo.baz_id'
            }
          )
          expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz` USE INDEX (`index_hint`) INNER JOIN `baz` ON baz.baz_id = foo.baz_id" # 'USE INDEX with JOIN'
        end

        it do
          stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
          stmt.add_select(:foo => 'foo')
          stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
          stmt.add_join(
            :baz => {
              :type      => 'inner',
              :table     => 'baz',
              :alias     => 'b1',
              :condition => 'baz.baz_id = b1.baz_id AND b1.quux_id = 1'
            },
          )
          stmt.add_join(
            :baz => {
              :type      => 'left',
              :table     => 'baz',
              :alias     => 'b2',
              :condition => 'baz.baz_id = b2.baz_id AND b2.quux_id = 2'
            },
          )
          expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz` USE INDEX (`index_hint`) INNER JOIN `baz` `b1` ON baz.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN `baz` `b2` ON baz.baz_id = b2.baz_id AND b2.quux_id = 2" # 'USE INDEX with JOINs'
        end
      end

      context 'quote_char: "", name_sep: ".", new_line: " "' do
        it do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_select(:foo => 'foo')
          stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
          stmt.add_join(
            :baz => {
              :type      => 'inner',
              :table     => 'baz',
              :condition => 'baz.baz_id = foo.baz_id'
            }
          )
          expect(stmt.as_sql).to be == "SELECT foo FROM baz USE INDEX (index_hint) INNER JOIN baz ON baz.baz_id = foo.baz_id" # 'USE INDEX with JOIN'
        end

        it do
          stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
          stmt.add_select(:foo => 'foo')
          stmt.add_index_hint('baz' => { :type => 'USE', :list => ['index_hint']})
          stmt.add_join(
            :baz => {
              :type      => 'inner',
              :table     => 'baz',
              :alias     => 'b1',
              :condition => 'baz.baz_id = b1.baz_id AND b1.quux_id = 1'
            },
          )
          stmt.add_join(
            :baz => {
              :type      => 'left',
              :table     => 'baz',
              :alias     => 'b2',
              :condition => 'baz.baz_id = b2.baz_id AND b2.quux_id = 2'
            },
          )
          expect(stmt.as_sql).to be == "SELECT foo FROM baz USE INDEX (index_hint) INNER JOIN baz b1 ON baz.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON baz.baz_id = b2.baz_id AND b2.quux_id = 2" # 'USE INDEX with JOINs'
        end
      end
    end

    context 'select + from' do
      it 'quote_char: "`", name_sep: "."' do
        stmt = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        stmt.add_select(:foo => 'foo')
        stmt.add_from(%w(baz))
        expect(stmt.as_sql).to be == "SELECT `foo`\nFROM `baz`"
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        stmt = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        stmt.add_select(:foo => 'foo')
        stmt.add_from(%w(baz))
        expect(stmt.as_sql).to be == "SELECT foo FROM baz"
      end
    end

    context 'join_with_using' do
      it 'quote_char: "`", name_sep: "."' do
        sql = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        sql.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => %w/ hoge_id fuga_id /,
          },
        )
        expect(sql.as_sql).to be == "FROM `foo` INNER JOIN `baz` USING (`hoge_id`, `fuga_id`)"
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        sql = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        sql.add_join(
          :foo => {
            :type      => 'inner',
            :table     => 'baz',
            :condition => %w/ hoge_id fuga_id /,
          },
        )
        expect(sql.as_sql).to be == "FROM foo INNER JOIN baz USING (hoge_id, fuga_id)"
      end
    end

    context 'add_where_raw' do
      it 'quote_char: "`", name_sep: "."' do
        sql = ns( :quote_char => %q{`}, :name_sep => %q{.}, )
        sql.add_select( :foo => 'foo' )
        sql.add_from( 'baz' )
        sql.add_where_raw( 'MATCH(foo) AGAINST (?)' => 'hoge' )

        expect(sql.as_sql).to be == "SELECT `foo`\nFROM `baz`\nWHERE (MATCH(foo) AGAINST (?))"
        expect(sql.bind[0]).to be == 'hoge'
      end

      it 'quote_char: "", name_sep: ".", new_line: " "' do
        sql = ns( :quote_char => %q{}, :name_sep => %q{.}, :new_line => %q{ } )
        sql.add_select( :foo => 'foo' )
        sql.add_from( 'baz' )
        sql.add_where_raw( 'MATCH(foo) AGAINST (?)' => 'hoge' )

        expect(sql.as_sql).to be == "SELECT foo FROM baz WHERE (MATCH(foo) AGAINST (?))"
        expect(sql.bind[0]).to be == 'hoge'
      end

      it 'multi values' do
        sql = ns( :quote_char => %q{}, :name_sep => %q{.} )
        sql.add_select( :foo => 'foo' )
        sql.add_from( 'baz' )
        sql.add_where_raw( 'foo = IF(bar = ?, ?, ?)' => ['hoge', 'fuga', 'piyo'] )

        expect(sql.as_sql).to be == "SELECT foo\nFROM baz\nWHERE (foo = IF(bar = ?, ?, ?))"
        expect(sql.bind[0]).to be == 'hoge'
        expect(sql.bind[1]).to be == 'fuga'
        expect(sql.bind[2]).to be == 'piyo'
      end

      it 'without value' do
        sql = ns( :quote_char => %q{}, :name_sep => %q{.} )
        sql.add_select( :foo => 'foo' )
        sql.add_from( 'baz' )
        sql.add_where_raw( 'foo IS NOT NULL' )

        expect(sql.as_sql).to be == "SELECT foo\nFROM baz\nWHERE (foo IS NOT NULL)"
        expect(sql.bind.size).to be == 0
      end
    end
  end
end

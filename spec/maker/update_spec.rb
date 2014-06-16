require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker#update' do
  include SQL::Maker::Helper

  context 'driver: sqlite' do
    builder = SQL::Maker.new(:driver => 'sqlite')
    # it 'arrayref, where cause(hashref)' do

    # it 'arrayref, where cause(arrayref)' do

    # it 'arrayref, where cause(condition)' do

    it 'ordered hashref, where cause(hashref)' do
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, {:yo => 'king'})
      expect(sql).to be == %Q{UPDATE "foo" SET "bar" = ?, "john" = ? WHERE ("yo" = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    #it 'ordered hashref, where cause(arrayref)' do

    it 'ordered hashref, where cause(condition)' do
      cond = builder.new_condition
      cond.add(:yo => 'king')
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, cond)
      expect(sql).to be == %Q{UPDATE "foo" SET "bar" = ?, "john" = ? WHERE ("yo" = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    it 'ordered hashref' do
      # no where
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %Q{UPDATE "foo" SET "bar" = ?, "john" = ?}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'literal, sub query' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => ['datetime(?)', 'now'], :counter => ['counter + 1' ] })
      expect(sql).to be == %Q{UPDATE "foo" SET "user_id" = ?, "updated_on" = datetime(?), "counter" = counter + 1}
      expect(bind.join(',')).to be == '100,now'
    end

    it 'literal, sub query using term' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => sql_raw('datetime(?)', 'now'), :counter => sql_raw('counter + 1') } )
      expect(sql).to be == %Q{UPDATE "foo" SET "user_id" = ?, "updated_on" = datetime(?), "counter" = counter + 1}
      expect(bind.join(',')).to be == '100,now'
    end
  end

  context 'driver: mysql' do
    builder = SQL::Maker.new(:driver => 'mysql')
    # it 'array ref, where cause(hashref)' do

    # it 'array ref, where cause(arrayref)' do

    # it 'array ref, where cause(condition)' do

    it 'ordered hashref, where cause(hashref)' do
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, {:yo => 'king'})
      expect(sql).to be == %Q{UPDATE `foo` SET `bar` = ?, `john` = ? WHERE (`yo` = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    # it 'ordered hashref, where cause(arrayref)' do

    it 'ordered hashref, where cause(condition)' do
      cond = builder.new_condition
      cond.add(:yo => 'king')
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, cond)
      expect(sql).to be == %Q{UPDATE `foo` SET `bar` = ?, `john` = ? WHERE (`yo` = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    it 'ordered hashref' do
      # no where
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %Q{UPDATE `foo` SET `bar` = ?, `john` = ?}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'literal, sub query' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => ['FROM_UNIXTIME(?)', 1302241686], :counter => ['counter + 1' ] })
      expect(sql).to be == %Q{UPDATE `foo` SET `user_id` = ?, `updated_on` = FROM_UNIXTIME(?), `counter` = counter + 1}
      expect(bind.join(',')).to be == '100,1302241686'
    end

    it 'literal, sub query using term' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => sql_raw('FROM_UNIXTIME(?)', 1302241686), :counter => sql_raw('counter + 1') } )
      expect(sql).to be == %Q{UPDATE `foo` SET `user_id` = ?, `updated_on` = FROM_UNIXTIME(?), `counter` = counter + 1}
      expect(bind.join(',')).to be == '100,1302241686'
    end
  end

  context 'driver: mysql, quote_char: "", new_line: " "' do
    builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
    # it 'array ref, where cause(hashref)' do

    # it 'array ref, where cause(arrayref)' do

    # it 'array ref, where cause(condition)' do

    it 'ordered hashref, where cause(hashref)' do
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, {:yo => 'king'})
      expect(sql).to be == %Q{UPDATE foo SET bar = ?, john = ? WHERE (yo = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    # it 'ordered hashref, where cause(arrayref)' do

    it 'ordered hashref, where cause(condition)' do
      cond = builder.new_condition
      cond.add(:yo => 'king')
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'}, cond)
      expect(sql).to be == %Q{UPDATE foo SET bar = ?, john = ? WHERE (yo = ?)}
      expect(bind.join(',')).to be == 'baz,man,king'
    end

    it 'ordered hashref' do
      # no where
      sql, bind = builder.update('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %Q{UPDATE foo SET bar = ?, john = ?}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'literal, sub query' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => ['FROM_UNIXTIME(?)', 1302241686], :counter => ['counter + 1' ]} )
      expect(sql).to be == %Q{UPDATE foo SET user_id = ?, updated_on = FROM_UNIXTIME(?), counter = counter + 1}
      expect(bind.join(',')).to be == '100,1302241686'
    end

    it 'literal, sub query using term' do
      sql, bind = builder.update('foo', { :user_id => 100, :updated_on => sql_raw('FROM_UNIXTIME(?)', 1302241686), :counter => sql_raw('counter + 1') } )
      expect(sql).to be == %Q{UPDATE foo SET user_id = ?, updated_on = FROM_UNIXTIME(?), counter = counter + 1}
      expect(bind.join(',')).to be == '100,1302241686'
    end
  end
end

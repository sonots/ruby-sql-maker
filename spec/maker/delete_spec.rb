require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  context 'driver sqlite' do
    it 'simple where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %q{DELETE FROM "foo" WHERE ("bar" = ?) AND ("john" = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    # it 'simple where_as_arrayref' do

    it 'simple where_as_condition' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.delete('foo', cond)
      expect(sql).to be == %q{DELETE FROM "foo" WHERE ("bar" = ?) AND ("john" = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'delete all' do
      builder = SQL::Maker.new(:driver => 'sqlite')
      sql, bind = builder.delete('foo')
      expect(sql).to be == %q{DELETE FROM "foo"}
      expect(bind.join(',')).to be == ''
    end
  end

  context 'driver mysql' do
    it 'simple where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %q{DELETE FROM `foo` WHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    # it 'simple where_as_arrayref' do

    it 'simple where_as_condition' do
      builder = SQL::Maker.new(:driver => 'mysql')
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.delete('foo', cond)
      expect(sql).to be == %q{DELETE FROM `foo` WHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'delete all' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.delete('foo')
      expect(sql).to be == %q{DELETE FROM `foo`}
      expect(bind.join(',')).to be == ''
    end

    it 'delete using where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'}, {:using => 'bar'})
      expect(sql).to be == %q{DELETE FROM `foo` USING `bar` WHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'delete using array where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'}, {:using => ['bar', 'qux']})
      expect(sql).to be == %q{DELETE FROM `foo` USING `bar`, `qux` WHERE (`bar` = ?) AND (`john` = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end
  end

  context 'driver mysql, quote_char: "", new_line: " "' do
    it 'simple where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'})
      expect(sql).to be == %q{DELETE FROM foo WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    # it 'simple where_as_arrayref' do

    it 'simple where_as_condition' do
      builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
      cond = builder.new_condition
      cond.add(:bar => 'baz')
      cond.add(:john => 'man')
      sql, bind = builder.delete('foo', cond)
      expect(sql).to be == %q{DELETE FROM foo WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'delete all' do
      builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
      sql, bind = builder.delete('foo')
      expect(sql).to be == %q{DELETE FROM foo}
      expect(bind.join(',')).to be == ''
    end

    it 'delete using where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'}, {:using => 'bar'})
      expect(sql).to be == %q{DELETE FROM foo USING bar WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end

    it 'delete using array where_as_hashref' do
      builder = SQL::Maker.new(:driver => 'mysql', :quote_char => '', :new_line => ' ')
      sql, bind = builder.delete('foo', {:bar => 'baz', :john => 'man'}, {:using => ['bar', 'qux']})
      expect(sql).to be == %q{DELETE FROM foo USING bar, qux WHERE (bar = ?) AND (john = ?)}
      expect(bind.join(',')).to be == 'baz,man'
    end
  end
end

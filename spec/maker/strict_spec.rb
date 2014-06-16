require_relative '../spec_helper'
require 'sql/maker'

describe 'SQL::Maker' do
  let(:maker) do
    SQL::Maker.new(
      :driver => 'SQLite',
      :strict => true,
    )
  end

  it { expect(maker.strict).to be == true }

  it "maker.new_condition" do
    expect { maker.new_condition.add(:foo => [1]) }.to raise_error(SQL::Maker::Error)
  end

  it "select.new_condition" do
    select = maker.new_select
    expect(select.strict).to be == true
    expect { select.new_condition.add(:foo => [1]) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.select" do
    expect { maker.select("user", ['*'], { :name => ["John", "Tom" ]}) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.insert" do
    expect { maker.insert(
      :user, { :name => "John", :created_on => "datetime(now)" }
    ) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.delete" do
    expect { maker.delete(:user, { :name => ["John", "Tom"]}) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.update where" do
    expect { maker.update(:user, {:name => "John"}, { :user_id => [1, 2] }) }.to raise_error(SQL::Maker::Error)
  end

  it "maker.update set" do
    expect { maker.update(:user, {:name => "select *"}) }.to raise_error(SQL::Maker::Error)
  end
end

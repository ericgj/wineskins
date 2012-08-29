require File.expand_path('./helper', File.dirname(__FILE__))
require File.expand_path('../lib/godwit', File.dirname(__FILE__))

TEST_DB.setup_ado
TEST_DB.setup

module TransferADOTestHelpers

  def setup_source
    TEST_DB.source_ado.disconnect
    TEST_DB.source_ado.drop_table :tests if TEST_DB.source_ado.tables.include?(:tests)
    TEST_DB.source_ado.drop_table :users if TEST_DB.source_ado.tables.include?(:users)
    
    TEST_DB.source_ado.create_table :users do
      primary_key :uid
      String :username
      DateTime :joined_at
    end
    
    TEST_DB.source_ado[:users].multi_insert([
      {:uid => 1, :username => "Wilson", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 2, :username => "Abner",  :joined_at => Time.now - rand(60*60*24)},
      {:uid => 3, :username => "Penelope", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 4, :username => "Harrison", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 5, :username => "Luke", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 6, :username => "Kramer", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 7, :username => "Gjert", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 8, :username => "Yvette", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 9, :username => "Ruth", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 10, :username => "Lambert", :joined_at => Time.now - rand(60*60*24)},
      {:uid => 11, :username => "Percy", :joined_at => Time.now - rand(60*60*24)}
    ])
    
    TEST_DB.source_ado.create_table :tests do
      primary_key :id
      String :name
      Integer :score, :index => true
      DateTime :taken_at
      index :name
      foreign_key :user_id, :users, :on_delete => :cascade
    end

    TEST_DB.source_ado[:tests].multi_insert([
      {:id => 1, :name => 'test1', :score => 65, :taken_at => Time.now - rand(60*60*24)},
      {:id => 2, :name => 'test2', :score => 21, :taken_at => Time.now - rand(60*60*24)},
      {:id => 3, :name => 'test3', :score => 75, :taken_at => Time.now - rand(60*60*24)},
      {:id => 4, :name => 'test4', :score => 84, :taken_at => Time.now - rand(60*60*24)},
      {:id => 5, :name => 'test5', :score => 60, :taken_at => Time.now - rand(60*60*24)},
      {:id => 6, :name => 'test6', :score => 20, :taken_at => Time.now - rand(60*60*24)},
      {:id => 7, :name => 'test7', :score => 66, :taken_at => Time.now - rand(60*60*24)},
      {:id => 8, :name => 'test8', :score => 87, :taken_at => Time.now - rand(60*60*24)},
      {:id => 9, :name => 'test9', :score => 72, :taken_at => Time.now - rand(60*60*24)},
      {:id => 10, :name => 'test10', :score => 33, :taken_at => Time.now - rand(60*60*24)},
      {:id => 11, :name => 'test11', :score => 99, :taken_at => Time.now - rand(60*60*24)}
    ])
    
  end

  def setup_dest
    TEST_DB.dest.create_table! :users do
      primary_key :uid
      String :username
      Time :joined_at
    end
  end
  
  def matchable_specs
    [:allow_null, :primary_key, :type]
  end
  
  # note that for whatever reason, :allow_null => true when creating primary_key columns
  # so this is a hack to ignore checking match of :allow_null
  def matchable_schema(info)
    col, specs = info
    {:column => col}.merge(
      if specs[:primary_key]
        Hash[ specs.select {|k,v| (matchable_specs - [:allow_null]).include?(k)} ]
      else
        Hash[ specs.select {|k,v| matchable_specs.include?(k)} ]
      end
    )  
  end
  
end

describe 'transfer_table, ADO adapter, functional' do
  include TransferADOTestHelpers
  
  subject { Godwit::Transfer.new(source, dest) }
  let(:source) { TEST_DB.source_ado }
  let(:dest)   { TEST_DB.dest   }
  
  before do
    setup_source
    setup_dest
  end
  
  it 'should create a table in dest' do
    subject.transfer_table :tests
    assert_includes dest.tables, :tests 
  end

  it 'should match schema specs in source' do
    subject.transfer_table :tests

    filter = method(:matchable_schema)
    exp = source.schema(:tests).map(&filter)
    act = dest.schema(:tests).map(&filter)
    assert_equal exp, act
  end  
  
  it 'should match index specs in source' do
    subject.transfer_table :tests
    assert_equal source.indexes(:tests), dest.indexes(:tests)
  end
  
end

describe 'transfer_records, ADO adapter, functional' do
  include TransferADOTestHelpers

  subject { Godwit::Transfer.new(source, dest) }
  let(:source) { TEST_DB.source_ado }
  let(:dest)   { TEST_DB.dest   }

  before do
    setup_source
    setup_dest
  end
  
  it 'should insert records matching source' do
    subject.transfer_records :users
    exp = source[:users].all.sort {|a,b| a[:uid] <=> b[:uid]}
    act = dest[:users].all.sort   {|a,b| a[:uid] <=> b[:uid]}
    refute_empty act
    assert_equal exp, act
  end
  
end
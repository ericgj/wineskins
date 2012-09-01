require File.expand_path('./helper', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.source_connect = 'sqlite://test/fixtures/db/source.sqlite3'
TEST_DB.dest_connect   = 'sqlite://test/fixtures/db/dest.sqlite3'

module TransferAssertions
  
  def assert_columns_match(table)
    match_keys = [:allow_null, :primary_key, :type]
    exp = source.schema(table).map {|col| 
            Wineskins::Utils.limit_hash(col, match_keys) 
          }
    act = dest.schema(table).map {|col| 
            Wineskins::Utils.limit_hash(col, match_keys) 
          }
    assert_equal exp.length, act.length,
      "Expected #{exp.length} columns in table #{table}, got #{act.length}"
    exp.each do |col|
      assert_includes act, col,
        "Expected column in table #{table}:\n#{col.inspect}"
    end
  end
  
  def assert_indexes_match(table)
    exp, act = source.indexes(table), dest.indexes(table)
    assert_equal exp.length, act.length, 
      "Expected #{exp.length} indexes for table #{table}, got #{act.length}"
    exp.values.each do |idx|
      assert_includes act.values, idx,
        "Expected index in table #{table}:\n#{idx.inspect}"
    end
  end
  
  def assert_fk_match(table)
    match_keys = [:columns, :table, :key, :on_delete, :on_update]
    exp = source.foreign_key_list(table).map {|fk| 
            Wineskins::Utils.limit_hash(fk, match_keys) 
          }
    act = dest.foreign_key_list(table).map {|fk| 
            Wineskins::Utils.limit_hash(fk, match_keys) 
          }
    assert_equal exp.length, act.length,
      "Expected #{exp.length} foreign key constraints for table #{table}, got #{act.length}"
    exp.each do |fk|
      assert_includes act, fk, 
        "Expected foreign key in table #{table}:\n#{fk.inspect}"
    end
  end
  
end

describe 'Transfer#run, default global options, functional' do

  subject { Wineskins::Transfer.new(source,dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest }
  
  describe 'single table, default options' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest   :users, :test_categories
      subject.define do
        table :tests
      end.run
    end
    
    it 'should create a table in dest' do
      assert_includes dest.tables, :tests 
    end
    
    it 'should match schema specs in source' do
      assert_columns_match(:tests)
    end

    it 'should match index specs in source' do
      assert_indexes_match(:tests)
    end
    
    it 'should match foreign key specs in source' do
      assert_fk_match(:tests)
    end
  
    it 'should have the same number of records as in source' do
      assert_equal source[:tests].count, dest[:tests].count
    end
    
    it 'should have the same range of primary keys as in source' do
      assert_equal source[:tests].get{max(id)}, dest[:tests].get{max(id)}
      assert_equal source[:tests].get{min(id)}, dest[:tests].get{min(id)}
    end
  end
  
  describe 'multiple tables, default options' do
    include TransferAssertions
    
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        table :test_categories
        table :users
        table :tests
      end.run
    end
    
    it 'should create tables in dest' do
      assert_includes dest.tables, :test_categories 
      assert_includes dest.tables, :users 
      assert_includes dest.tables, :tests 
    end
    
    it 'should match schema specs in source' do
      assert_columns_match(:test_categories)
      assert_columns_match(:users)
      assert_columns_match(:tests)
    end

    it 'should match index specs in source' do
      assert_indexes_match(:test_categories)
      assert_indexes_match(:users)
      assert_indexes_match(:tests)
    end
    
    it 'should match foreign key specs in source' do
      assert_fk_match(:test_categories)
      assert_fk_match(:users)
      assert_fk_match(:tests)
    end
  
    it 'each table should have the same number of records as in source' do
      assert_equal source[:test_categories].count, dest[:test_categories].count
      assert_equal source[:users].count, dest[:users].count
      assert_equal source[:tests].count, dest[:tests].count
    end
    
    it 'each table should have the same range of primary keys as in source' do
      assert_equal source[:test_categories].get{max(id)}, dest[:test_categories].get{max(id)}
      assert_equal source[:test_categories].get{min(id)}, dest[:test_categories].get{min(id)}

      assert_equal source[:users].get{max(uid)}, dest[:users].get{max(uid)}
      assert_equal source[:users].get{min(uid)}, dest[:users].get{min(uid)}

      assert_equal source[:tests].get{max(id)}, dest[:tests].get{max(id)}
      assert_equal source[:tests].get{min(id)}, dest[:tests].get{min(id)}
    end
  end
  
end
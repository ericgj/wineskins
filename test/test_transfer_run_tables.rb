require File.expand_path('helper', File.dirname(__FILE__))
require File.expand_path('helpers/transfer_assertions', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.source_connect = 'sqlite://test/fixtures/db/source.sqlite3'
TEST_DB.dest_connect   = 'sqlite://test/fixtures/db/dest.sqlite3'

describe 'Transfer#run, functional' do

  subject { Wineskins::Transfer.new(source,dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest }
  
  #------------------------------------------
  describe 'tables, none specified, default options' do

    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        tables
      end.run
    end
    
    it 'should create all tables in dest' do
      assert_equal source.tables.sort, dest.tables.sort
    end
    
    it 'should match number of records in all tables in dest' do
      [:users, :test_categories, :tests].each do |tbl|
        assert_equal source[tbl].count, dest[tbl].count
      end
    end
    
  end
  
  #------------------------------------------  
  describe 'tables, some specified, some with table rename, default options' do

    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        tables :users, [:test_categories, :categories_of_tests]
      end.run
    end
    
    it 'should create all specified tables in dest' do
      assert_equal [:categories_of_tests, :users], dest.tables.sort
    end
    
    it 'should match number of records in all tables in dest' do
      [[:users, :users], 
       [:test_categories, :categories_of_tests]
      ].each do |(src_tbl, dst_tbl)|
        assert_equal source[src_tbl].count, dest[dst_tbl].count
      end
    end
    
  end

  #------------------------------------------
  # these next tests don't really belong here, but to stick them somewhere for now
  #------------------------------------------
  
  describe 'tables, some specified with options' do

    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        tables :users, :test_categories, :create_fk_constraints => false
        table :tests
      end
    end
    
    it 'should have passed option for all tables specified with option' do
      subject.table_defs[0..1].each do |t|
        assert_equal false, t.create_fk_constraints?
      end
    end

    it 'should have default option for all tables not specified with option' do
      subject.table_defs[2..2].each do |t|
        assert_equal true, t.create_fk_constraints?
      end
    end
    
  end  
  
  describe 'schema_only option' do
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest
      subject.define do
        tables :users, :test_categories, :schema_only => true
      end
    end
    
    it 'should have create tables, indexes, fk constraints options true, and insert records option false' do
      subject.table_defs.each do |t|
        assert_equal true,  t.create_table?
        assert_equal true,  t.create_indexes?
        assert_equal true,  t.create_fk_constraints?
        assert_equal false, t.insert_records?
      end
    end

  end

  describe 'records_only option' do
    before do
      TEST_DB.setup_source :users, :test_categories, :tests
      TEST_DB.setup_dest :users, :test_categories
      subject.define do
        tables :users, :test_categories, :records_only => true
      end
    end
    
    it 'should have create tables, indexes, fk constraints options false, and insert records option true' do
      subject.table_defs.each do |t|
        assert_equal false,  t.create_table?
        assert_equal false,  t.create_indexes?
        assert_equal false,  t.create_fk_constraints?
        assert_equal true, t.insert_records?
      end
    end

  end

end
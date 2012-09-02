require File.expand_path('helper', File.dirname(__FILE__))
require File.expand_path('../lib/wineskins', File.dirname(__FILE__))

TEST_DB.source_connect = 'sqlite://test/fixtures/db/source.sqlite3'
TEST_DB.dest_connect   = 'sqlite://test/fixtures/db/dest.sqlite3'

describe 'Transfer#run callbacks, functional' do

  subject { Wineskins::Transfer.new(source,dest) }
  let(:source) { TEST_DB.source }
  let(:dest)   { TEST_DB.dest }
  
  before do
    TEST_DB.setup_source :users
    TEST_DB.setup_dest
    spy = []
    subject.define do      
      table :users
      
      after  { spy << :after }
      after  { spy << source[:users].count }
      after_create_tables { spy << :after_create_tables }
      after_create_indexes { spy << :after_create_indexes }
      after_create_fk_constraints { spy << :after_create_fk_constraints }
      after_insert_records { spy << :after_insert_records }
      before_insert_records { spy << :before_insert_records }
      before_create_indexes { spy << :before_create_indexes }
      before_create_tables { spy << :before_create_tables }
      before_create_fk_constraints { spy << :before_create_fk_constraints }
      before { spy << :before }
      
    end.run
    @spy = spy
  end
  
  it 'should trigger callbacks in order' do
    exp = [:before,
           :before_create_tables,
           :after_create_tables,
           :before_create_indexes,
           :after_create_indexes,
           :before_create_fk_constraints,
           :after_create_fk_constraints,
           :before_insert_records,
           :after_insert_records,
           :after,
           source[:users].count
          ]
    assert_equal exp, @spy
  end
  
end
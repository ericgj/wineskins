gem 'minitest'
require 'minitest/autorun'

require 'logger'

class << (TEST_DB = Object.new)
  def source 
    @source ||= Sequel.connect('sqlite://test/fixtures/db/source.sqlite3')
  end
  
  def dest   
    @dest ||= Sequel.connect('sqlite://test/fixtures/db/dest.sqlite3')
  end
  
  def setup
    source.loggers << ::Logger.new('test/log/source.log')
    dest.loggers << ::Logger.new('test/log/dest.log')
  end
end

class SequelSpec < MiniTest::Spec
  def run(*args, &block)
    TEST_DB.dest.transaction(:rollback => :always){super}
  end
end

MiniTest::Spec.register_spec_type(/functional/i, SequelSpec)
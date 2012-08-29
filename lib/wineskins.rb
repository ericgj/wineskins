require 'sequel'
require File.expand_path('sequel_ext/adapters/shared/access', File.dirname(__FILE__))

require File.expand_path('wineskins/utils', File.dirname(__FILE__))
require File.expand_path('wineskins/schema_methods', File.dirname(__FILE__))
require File.expand_path('wineskins/record_methods', File.dirname(__FILE__))

module Wineskins

  class Transfer
    include SchemaMethods
    include RecordMethods
    
    attr_accessor :source, :dest
    
    def initialize(source, dest)
      self.source = source
      self.dest = dest
    end

  end
  
end


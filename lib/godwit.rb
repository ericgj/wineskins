require 'sequel'
require File.expand_path('lib/sequel_ext/adapters/shared/access', File.dirname(__FILE__))

require File.expand_path('lib/utils', File.dirname(__FILE__))
require File.expand_path('lib/schema_methods', File.dirname(__FILE__))
require File.expand_path('lib/record_methods', File.dirname(__FILE__))

module Godwit

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


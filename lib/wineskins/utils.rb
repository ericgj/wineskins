module Wineskins

  module Utils
    extend self
   
    def remap_hash(hash, map)
      hash.inject({}) do |memo, (k,v)|
        memo[ map[k] || k ] = v
        memo
      end
    end

    def limit_hash(hash, keys)
      Hash[ hash.select {|k,v| keys.include?(k)} ]
    end
    
  end
  
end
module Wineskins

  module Utils
    extend self
   
    def remap_hash(hash, map)
      map.inject({}) do |memo, (in_key, out_key)|
        memo[out_key] = hash[in_key] if hash[in_key]
        memo
      end    
    end
    
  end
  
end
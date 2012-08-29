module Godwit

  module RecordMethods
  
    # ten at a time
    def transfer_records(tbl, renames=nil)
      src_tbl, dst_tbl = Array(tbl)
      dst_tbl ||= src_tbl
      renames ||= Hash[ source[src_tbl].columns.map {|col| [col,col]} ]
      source[src_tbl].each_slice(10) do |recs|
        dest[dst_tbl].multi_insert(
          recs.map {|rec|
            remap = Utils.remap_hash(rec, renames)
            block_given? ? yield(remap) : remap           
          }
        )
      end
    end
    
  end
  
end
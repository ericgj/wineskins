module Wineskins

  module RecordMethods
  
    # reads + inserts ten records at a time
    def transfer_records(table)
      src_tbl, dst_tbl = table.source_name, table.dest_name
      rename = table.rename_map(source[src_tbl].columns)
      source[src_tbl].each_slice(10) do |recs|
        dest[dst_tbl].multi_insert(
          recs.map {|rec|
            remap = Utils.remap_hash(rec, rename)
            block_given? ? yield(remap) : remap           
          }
        )
      end
    end
    
  end
  
end
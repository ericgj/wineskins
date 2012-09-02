module Wineskins

   class Transcript
  
    def initialize(io=nil)
      @io = io || $stdout
    end
    
    # write all sql and errors, stripping the duration from the front 
    def method_missing(m, msg)
      write msg.gsub(/\A\([\d\.s]+\)\s+/,'')
    end
    
    def write(msg)
      if String === @io
        File.open(@io, 'w+') {|f| f.puts msg}
      else
        @io.puts msg
      end
    end
    
  end
  
end
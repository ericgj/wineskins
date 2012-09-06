require 'optparse'

module Wineskins

  class Runner
  
    def initialize(argv=nil)
      @config = Config.new
      parse_opts argv
    end
    
    def parse_opts(argv)
      opts = OptionParser.new do |opts|
        opts.default_argv = argv if argv
        
        opts.banner = "Usage: wskins [options] [source-db] [dest-db]"
        
        opts.on "-c", "--config SCRIPT", "Transfer script filename, default #{@config.script}" do |file|
          @config.script = file
        end
        
        opts.on "--[no-]dry-run", "Don't commit changes" do |bool|
          @config.dry_run = bool
        end
        
      end
      
      opts.parse!(argv)
      @config.source = argv.shift
      @config.dest   = argv.shift
      
      unless @config.source && @config.dest
        $stderr.puts "You must specify a source and destination database URL"
        $stderr.puts opts
        exit false
      end
      
    end
    
    def run
      t = Transfer.new(@config.source_db, @config.dest_db)
      eval "t.define {\n" + @config.script_text + "\n}"
      t.run @config.run_options
    end
    
  end
  
  class Config < Struct.new(:source, :dest, :script, :dry_run)
  
    def initialize(*args)
      super
      self.script  ||= "./transfer.rb"
      self.dry_run ||= false
    end
    
    def source_db
      @source_db ||= Sequel.connect(self.source)
    end
    
    def dest_db
      @dest_db ||= Sequel.connect(self.dest)
    end
    
    def script_text
      ::File.read(self.script)
    end
    
    def run_options
      [:dry_run].inject({}) do |memo, opt|
        memo[opt] = self.send(opt)
        memo
      end
    end
    
  end
  
end
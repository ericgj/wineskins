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
        
        opts.banner = "Usage: \n"+
                      "(1) wskins [options] [source-db] [dest-db]\n" +
                      "(2) wskins [options]"
        
        opts.separator nil
        opts.separator "Options:"
        
        opts.on "-c", "--config FILE", "Transfer script, default #{@config.script}" do |file|
          @config.script = file
        end
        
        opts.on "-r", "--require FILE", "Require ruby file or gem before running" do |file|
          @config.requires << file
        end
        
        opts.on "--[no-]dry-run", "Don't commit changes" do |bool|
          @config.dry_run = bool
        end
        
        opts.on "-h", "--help", "Show this message" do
          puts opts
          exit
        end
        
        opts.separator nil
        opts.separator "Summary:"
        opts.separator wrap( %Q[
Transfer schema and data from [source-db] to [dest-db], according to 
instructions in transfer script (by default, #{@config.script}).

In form (1), specify a source and destination database URL (as recognized by 
Sequel.connect). In form (2), require (-r) a ruby program that connects to 
databases manually and assigns SOURCE_DB= and DEST_DB=

], 80)
      end
      
      opts.parse!(argv)
      @config.source = argv.shift
      @config.dest   = argv.shift
      
    end
    
    def run
      require_all
      set_global_unless_defined 'SOURCE_DB', @config.source_db
      set_global_unless_defined 'DEST_DB', @config.dest_db
      validate
      t = Transfer.new(::SOURCE_DB, ::DEST_DB)
      eval "t.define {\n" + @config.script_text + "\n}"
      t.run @config.run_options
    end
    
    # require specified libs
    def require_all
      @config.requires.each do |r| require r end
    end

    def set_global_unless_defined(const, value)
      unless Object.const_defined?(const)
        Object.const_set(const, value)
      end
      Object.const_get(const)
    end
    
    def validate
      unless ::SOURCE_DB && ::DEST_DB
        $stderr.puts wrap( %Q[
You must specify a source and destination database URL, or manually assign 
SOURCE_DB= and DEST_DB=
], 80)
        exit false
      end    
    end
    
    private
    
    def wrap(text, width) # :doc:
      text.gsub(/(.{1,#{width}})( +|$\n?)|(.{1,#{width}})/, "\\1\\3\n")
    end
    
  end
  
  class Config < Struct.new(:source, :dest, :script, :dry_run)
  
    attr_reader :requires
    def initialize(*args)
      @requires = []
      super
      self.script  ||= "./transfer.rb"
      self.dry_run ||= false
    end
    
    def source_db
      return unless self.source
      @source_db ||=  Sequel.connect(self.source)
    end
    
    def dest_db
      return unless self.dest
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
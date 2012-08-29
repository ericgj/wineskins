Dir[File.expand_path('test_*.rb', File.dirname(__FILE__))].each do |rb|
  require rb
end
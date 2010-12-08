# Include hook code here
begin
  Dir.new(File.join(File.dirname(__FILE__), 'lib')).each do |file|
    require(File.join(File.dirname(__FILE__), 'lib', file)) if /rb$/.match(file)
  end
rescue Exception => e
  
  puts e.inspect
  ActionController::Base.logger.fatal e if ActionController::Base.logger
end
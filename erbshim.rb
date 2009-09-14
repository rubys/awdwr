$:.push ENV['RUBYPATH'] if ENV['RUBYPATH']
require 'rubygems'
require 'active_support'
begin
  require 'active_support/time'
rescue MissingSourceFile
end

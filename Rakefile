task :default => [:test]

task :setup do
  ruby 'setup.rb'
  sh 'bundle update'
end

task :dashboard do
  cmd = ['rackup']
  cmd += ['-p', ENV['PORT']] if ENV['PORT']
  cmd += ['-o', ENV['IP']] if ENV['IP']
  system *cmd
end

# example usage: rake test[6.1-6.5,save]
task :test, :arg1, :arg2, :arg3, :arg4 do |task, args|
  ruby 'makedepot.rb', *serialize(args)
end

task :check, :arg1 do |task, args|
  ruby 'checkdepot.rb', *serialize(args)
end

task :clean do
  rm_rf 'work'
  rm_rf 'snapshot'
  rm_rf 'makedepot.html'
  rm_rf 'checkdepot.html'
end

def serialize(args)
  args.to_a.sort_by {|k| k.to_s}.map {|k,v| v.to_s}
end

#!/usr/bin/ruby
require 'rubygems'
require 'yaml'
require 'ostruct'

HOME = ENV['HOME']
ENV['LANG']='en_US.UTF-8'
ENV['USER'] ||= HOME.split(File::Separator).last
File.umask(0022)
$rails = "#{HOME}/git/rails"

# parse ARGV based on configuration
config = YAML.load(open('testrails.yml'))
profile = config['default'].dup
config.each do |keyword,overrides| 
  next unless ARGV.include? keyword.to_s
  overrides.each do |key, value|
    if profile[key].respond_to? :push
      profile[key].push(value)
    else
      profile[key] = value
    end
  end
end
PROFILE = OpenStruct.new(profile)

COMMIT = ARGV.find {|arg| arg =~ /http:\/\/github.com\/rails\/rails\/commit\//}

log=config.find_all {|k,v| ARGV.include? k.to_s}.map {|k,v| k}.join('-')
LOG = "#{HOME}/logs/makedepot#{log}.log"
system "mkdir -p #{File.dirname(LOG)}"

OUTPUT = PROFILE.output.map {|token| '-'+token.gsub('.','')}.sort.join
OUTMIN = OUTPUT.gsub('.','')
WORK   = 'work' + OUTMIN
Dir.chdir PROFILE.source do
  system "mkdir -p #{WORK}"
  system "ln -s ../data #{WORK}" unless File.exist?(File.join(WORK, 'data'))
end

BRANCH = PROFILE.branch
DESTDIR = PROFILE.destdir
SCRIPT  = File.join(File.expand_path(File.dirname(__FILE__)), PROFILE.script)

def bash cmd
  cmd = cmd.strip.gsub(/^\s+/,'').gsub(/\n/,'; ')
  puts   cmd
  system 'bash -c ' + cmd.inspect
end

# update Rails
updated = Dir.chdir($rails) do
  system 'git checkout -q origin/master'
  system "git checkout #{BRANCH}"
  system "git checkout #{COMMIT.split('/').last}" if COMMIT
  before = `git log -1 --pretty=format:%H`
  system 'git pull origin'
  `git log -1 --pretty=format:%H` != before
end

# If unchanged, select next or exit now
if !updated
  Process.exit if ARGV.empty?
  if ARGV.delete('next') and ARGV.empty?
    require 'nokogiri'

    dashboard=`ruby /var/www/dashboard.cgi static`.sub(/.*?</m,'<')
    rows = Nokogiri::XML(dashboard).search('tr').to_a
    rows.reject! {|row| !row.at('td')}
    rows.reject! {|row| row.at('td:nth-child(4).hilite')}
    if rows.length>0
      stale = rows.min {|a,b| a.at('td:last').text <=> b.at('td:last').text}
      stale = stale.search('td').to_a[0..2]
      exec "#{$0} #{stale.map {|td| td.text.gsub(/\D/,'')}.join(' ')}"
    end
  end
end

# update gems
Dir.chdir File.join(PROFILE.source,WORK) do
  open('Gemfile','w') do |gemfile|
    gemfile.puts "source 'http://gemcutter.org'"
    gemfile.puts "gem 'rails', :path => #{$rails.inspect}"
    gemfile.puts "gem 'sqlite3-ruby', :require => 'sqlite3'"
    gemfile.puts "gem 'will_paginate', '>= 3.0.pre'"
    gemfile.puts "gem 'test-unit'"
    gemfile.puts "gem 'rdoc'"
    begin
      require 'nokogiri'
    rescue LoadError
      gemfile.puts "gem 'htmlentities'"
    end
  end
end

# update libs
libs = %w(gorp arel rack)
libs.each do |lib|
  Dir.chdir(File.join(HOME,'git',lib)) { system 'git pull' }
end
ENV['RUBYLIB'] = libs.map {|lib| File.join(HOME,'git',lib,'lib')}.
  join(File::PATH_SEPARATOR)

# update awdwr tests
Dir.chdir PROFILE.source
if PROFILE.source.include? 'svn'
  system 'svn up'
else
  system 'git checkout -q master'
  system 'git pull origin'
end

# capture the old status
OLDSTAT = open(File.join(WORK, 'status')) {|file| file.read} rescue ''
OLDSTAT.gsub! /, 0 (pendings|omissions|notifications)/, ''

# select arguments to pass through
args = ARGV.grep(/^(\d+(\.\d+)?-\d+(\.\d+)?|\d+\.\d+?|save|restore)$/)
args << "--work=#{WORK}"

# build a new rvm, if necessary
source=PROFILE.rvm['src']
if source
  release=PROFILE.rvm['bin'].split('-')[1]
  puts "#{HOME}/.rvm/gems/#{PROFILE.gems}/cache"
  puts Dir["#{HOME}/.rvm/gems/#{PROFILE.gems}/cache"].sort.last

  Dir.chdir("#{HOME}/.rvm/src") do
    rev = Dir.chdir(source) do
      system 'svn update'
      `svn info`.scan(/Last Changed Rev: (\d+)/).flatten.first
    end

    break if File.exist? "ruby-#{release}-r#{rev}"

    cache = Dir["#{HOME}/.rvm/gems/#{PROFILE.gems}/cache"].sort.last

    bash %{
      cp -r #{source} ruby-#{release}-r#{rev}
      source #{HOME}/.rvm/scripts/rvm
      TERM=dumb rvm install #{release}-#{rev}
      rvm #{release}-#{rev}
      gem env path | xargs chmod -R 0755
      gem install --no-ri --no-rdoc #{cache}/*
    }

    # keep the last three, and anything built in a week; remove the rest
    horizon = Time.now - 7 * 86400
    keep    = 3

    Dir.chdir("#{HOME}/.rvm") do
      vms = Dir["ruby-#{release}-r*"].sort
      vms.slice! -keep..-1
      vms.delete_if {|vm| File.stat(vm).mtime >= horizon}

      vms.each do |vm|
        system "find . -name #{vm} -exec rm -rfv {} \\;"
      end
    end
  end
end

# find the rvm
rvm = Dir[File.join(HOME,'.rvm',PROFILE.rvm['bin'])].sort.last
unless rvm
  puts "Unable to locate #{File.join(HOME,'.rvm',PROFILE.rvm['bin'])}"
  exit
end

# run the script
bash %{
  source #{HOME}/.rvm/scripts/rvm
  rvm #{rvm.gsub(/.*\/ruby-/,'')}
  eval export BUNDLE_PATH='$'GEM_PATH
  cd #{WORK}
  bundle install
  cd ..
  ruby #{PROFILE.script} #{$rails} #{args.join(' ')} > #{LOG} 2>&1
}

status = $?

# restore rails to master
Dir.chdir($rails) do
  system 'git checkout master' unless BRANCH=='master'
end

exit status.exitstatus

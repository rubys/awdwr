#!/usr/bin/ruby
require 'rubygems'
require 'yaml'
require 'ostruct'

Dir.chdir File.dirname(__FILE__)

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'clerk/rvm'
require_relative 'clerk/rbenv'

HOME = ENV['HOME']
ENV['LANG']='en_US.UTF-8'
ENV['USER'] ||= HOME.split(File::Separator).last
File.umask(0022)
$rails = "#{HOME}/git/rails"

# chaining support
if ARGV.join(' ').include?(',')
  ARGV.join(' ').split(',').each { |args| system "#{$0} #{args.strip}" }
  exit
end

# parse ARGV based on configuration
require_relative 'environment'
PROFILE = OpenStruct.new(AWDWR::config('testrails.yml', *ARGV))
release=PROFILE.ruby['bin'].split('-')[1]

COMMIT = ARGV.find {|arg| arg =~ /http:\/\/github.com\/rails\/rails\/commit\//}

LOG = "#{HOME}/logs/makedepot#{PROFILE.log}.log"
system "mkdir -p #{File.dirname(LOG)}"

def log(message)
  open(LOG, 'a') do |file| 
    file.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S] ====> #{message}")
  end
end

OUTPUT = PROFILE.output.map {|token| '-'+token.gsub('.','')}.sort.join
OUTMIN = OUTPUT.gsub('.','')
WORK   = 'work' + OUTMIN
Dir.chdir PROFILE.source do
  system "mkdir -p #{WORK}"
  system "ln -f -s ../data #{WORK}" unless File.exist?(File.join(WORK, 'data'))
end

BRANCH = PROFILE.branch
DESTDIR = PROFILE.destdir
SCRIPT  = File.join(File.expand_path(File.dirname(__FILE__)), PROFILE.script)

RUNFILE = File.join(PROFILE.source, WORK, 'status.run')
open(RUNFILE,'w') {|running| running.puts(Process.pid)}
at_exit { system "rm -f #{RUNFILE}" }

system "rm -f #{LOG}"
log 'Updating git repositories'

# update Rails
if ARGV.delete('noupdate')
  updated = true
else
  updated = Dir.chdir($rails) do
    system 'git checkout -q origin/master'
    system "git checkout #{BRANCH}"
    system "git checkout #{COMMIT.split('/').last}" if COMMIT
    before = `git log -1 --pretty=format:%H`
    print 'rails: '
    system 'git pull origin'
    `git log -1 --pretty=format:%H` != before
  end
end

$rails_version = (File.read("#{$rails}/RAILS_VERSION").strip rescue '2.x')
$rails_version.sub! '3.1.0.rc1', '3.2.0.pre'

# adjust selection based on arguments
arg_was_present = (not ARGV.empty?)
oldest = ARGV.delete('next') unless updated
missing = ARGV.delete('missing')
failed = ARGV.delete('fail') || ARGV.delete('failed')
before = ARGV.find {|c| c.start_with? '<'}; ARGV.delete(before)
arg_was_present = false if oldest and updated

if ARGV.empty? and arg_was_present
  require 'nokogiri'

  dashboard=`ruby /var/www/dashboard.cgi static=true`.sub(/.*?</m,'<')
  rows = Nokogiri::XML(dashboard).search('tr').to_a
  rows.reject! {|row| !row.at('td')}
  rows.reject! {|row| row.at('td:nth-child(4).hilite')}
  dated = rows.select {|r| r.at('td:last').text =~ /^\d+(-\d+)+.\d+(:\d+)+$/}
  selected = rows - dated

  if oldest
    selected << rows.min {|a,b| a.at('td:last').text <=> b.at('td:last').text}
    selected = selected.slice(0,1)
  elsif before
    before = before.gsub(/\D/, '')
    selected += dated.select {|tr| tr.at('td:last').text.gsub(/\D/,'') < before}
  elsif failed
    selected = rows.select {|tr| tr.at('td.fail')}
  end

  Process.exit if selected.empty?

  args = selected.uniq.map {|tr| 
    tr.search('td').to_a[0..2].map {|td| td.text.gsub('.','')}.join(' ')
  }.join(', ')

  system "rm -f #{RUNFILE}"
  exec "#{$0} #{args}"
end

if PROFILE.path
  ENV['PATH'] = (PROFILE.path + ENV['PATH'].split(':')).uniq.join(':')
end

# clean up mysql
mysql_root = 'mysql -u root'
mysql_root += ' -proot' if system("mysql -u root -proot < /dev/null 2>&0") 
open("|#{mysql_root}",'w') {|f| f.write "drop database depot_production;"}
open("|#{mysql_root}",'w') {|f| f.write "create database depot_production;"}

$gems = gems = AWDWR::dependencies(File.join(HOME, 'git', 'rails'), release)
gems['rails'] ||= {:github => 'rails/rails'}

def gem name, version=nil, opts={}
  if String === version
    opts[:version] ||= []
    opts[:version] << version
  elsif Hash === version
    opts.merge version
  end

  $gems[name] ||= {}
  $gems[name].merge! opts
end

# adjust gems
%w(
  htmlentities test-unit
  sqlite3 jquery-rails
  rvm-capistrano activemerchant haml
).each do |name|
  gem name
end

if $rails_version =~ /^3\./
  gem 'will_paginate'
else
  gem 'kaminari'
end

if release =~ /^1\.8\./
  gem 'activemerchant', '~> 1.21.0'
  gem 'money', '~> 3.7.1'
end

if $rails_version =~ /^3\.0/
  gem 'mysql'
  gem 'activemerchant', '~> 1.10.0'
  gem 'haml', '~> 4.0'
  gem 'will_paginate', '>= 3.0.pre'
else
  gem 'mysql2'
  gem 'jquery-ui-rails'
end

unless $rails_version =~ /^3\./
  gem 'sass'
  gem 'puma'
  gem 'devise', '~> 3.1'
end

# checkout/update git repositories
gems.each do |lib, opts|
  next if lib == 'rails'

  if opts[:github]
    opts[:git] = "https://github.com/#{opts[:github]}.git" 
  end

  next unless opts[:git]
  print lib + ': '
  if not File.exist? File.join(HOME,'git',lib)
    Dir.chdir(File.join(HOME,'git')) do 
      system "git clone #{opts[:git]} #{lib}"
    end
  end
  Dir.chdir(File.join(HOME,'git',lib)) do 
    system "git checkout #{opts[:branch] || 'master'}"
    system 'git pull'
  end
end

# update gems
Dir.chdir File.join(PROFILE.source,WORK) do
  open('Gemfile','w') do |gemfile|
    gemfile.puts "source 'https://rubygems.org'"
    gems.sort.each do |gem, options|
      next if gem == 'gorp'

      # override with local clones
      if options[:git] or options[:github]
        path = File.join(HOME,'git',gem)
        if File.exist?(File.join(path, "/#{gem}.gemspec"))
          options = options.dup
          options.delete :git
          options.delete :github
          options.delete :branch
          options[:path] = path
        end
      end

      args = []
      args += options.delete(:version).map(&:inspect) if options[:version]

      options.each do |name, value|
        if release =~ /^1.8/
          args.push ":#{name} => #{value.inspect}"
        else
          args.push "#{name}: #{value.inspect}"
        end
      end

      gemfile.puts "gem '#{gem}'#{args.map{|s| ", #{s}"}.join}"
    end
  end
end

# update awdwr tests
Dir.chdir PROFILE.source
if PROFILE.source.include? 'svn'
  system 'svn up'
else
  print 'awdwr: '
  system 'git checkout -q master'
  system 'git pull origin'
end

# capture the old status
status_file = File.join(WORK, 'checkdepot.status')
if not File.exist?(status_file) and File.exist?(File.join(WORK, 'status'))
  File.rename File.join(WORK, 'status'), status_file
end
OLDSTAT = open(status_file) {|file| file.read} rescue ''
OLDSTAT.gsub! /, 0 (pendings|omissions|notifications)/, ''

# dead man's switch
system "rm -f #{WORK}/checkdepot.html"
at_exit do
  Dir.chdir PROFILE.source
  if not File.exist? "#{WORK}/checkdepot.html"
    open("#{WORK}/checkdepot.status", 'w') {|file| file.puts 'NO OUTPUT'}
  end
end

# select arguments to pass through
args = ARGV.grep(/^(\d+(\.\d+)?-\d+(\.\d+)?|\d+\.\d+?|save|restore)$/)
args << "--work=#{WORK}"

# select rvm or rbenv
if RVM.available?
  clerk = RVM.new
elsif RBenv.available?
  clerk = RBenv.new
else
  STDERR.puts "Either rvm or rbenv are required"
  exit 1
end

log "Updating ruby #{release}"

# update build definitions
clerk.update

# build a new ruby, if necessary
source=PROFILE.ruby['src']
version = if source
  clerk.install_from_source(source, release)
else
  clerk.install_latest(PROFILE.ruby['bin'])
end

unless version
  STDERR.puts "#{PROFILE.ruby['bin']} installation failed, exiting..."
  exit 1
end

version = File.basename(version)

# keep the last three, and anything built in a week; remove the rest
clerk.prune(PROFILE.ruby['bin'], 3, Time.now - 7 * 86400)

log "Updating gems"

if File.exist? File.join(WORK, 'Gemfile')
  install, bundler  = 'install', 'bundler'
  gemspec = File.join(HOME, 'git', 'rails', 'rails.gemspec')
  if File.exist?(gemspec)
    if not File.readlines(gemspec).grep(/bundler.*\.pre\./).empty?
      install = 'install --pre' 
      bundler = 'bundler.*pre'
    end
  end

  install = <<-EOF
    gem list -i ^bundler$ > /dev/null && gem update bundler || gem #{install} bundler
    (cd #{File.realpath WORK}; rm -rf Gemfile.lock vendor; bundle install)
  EOF

  ENV.delete 'BUNDLE_GEMFILE'
  ENV.delete 'BUNDLE_BIN_PATH'
  ENV.delete 'GEM_HOME'
  ENV.delete 'GEM_PATH'
  ENV.delete 'RUBYLIB'
  ENV.delete 'RUBYOPT'
else
  install = <<-EOF
    gem list rack | grep -q 1.1.3 || gem install rack -v 1.1.3
    gem list will_paginate | grep -q 2.3 || gem install will_paginate -v 2.3.11
    gem list activesupport | grep -q 3.0 && gem uninstall activesupport -I -a
  EOF
end

# run the script
clerk.run(version, install)

libs = gems.select {|gem, options| options[:git] || options[:github]}
ENV['RUBYLIB'] = libs.map {|lib, options| File.join(HOME,'git',lib,'lib')}.
  join(File::PATH_SEPARATOR)

cmd = "ruby #{PROFILE.script} #{$rails} #{args.join(' ')}"
system 'tty -s'
if $? == 0 or ENV['TERM']
  cmd += " 2>&1 | tee #{LOG}"
else
  cmd += " >> #{LOG} 2>&1"
end

clerk.run(version,  cmd)

status = $?

if File.exist?("#{WORK}/checkdepot.html")
  # parse and normalize checkdepot output
  body = open("#{WORK}/checkdepot.html").read
  body.gsub! "src='data", "src='../data"
  body.gsub! 'src="data', 'src="../data'
  eof = '#&lt;EOFError: end of file reached&gt;'
  body.gsub! eof, "<a href='makedepot.log'>#{eof}</a>"

  # dissect checkdepot output 
  sections = body.split(/^\s+<a class="toc" id="section-(.*?)">/)
  head=sections.shift
  toc = head.slice!(/^\s*<h2>Table of Contents<\/h2>.*/m)
  sections[-1], env = sections.last.split(/<a class="toc" id="env">/)
  style = head.slice(/<style.*?style>/m)
  head.sub!(/<style.*?style>/m, '<link rel="stylesheet" href="depot.css"/>')
  env = '<a class="toc" id="env">'+env
  tail = env.slice!(/^\s+<\/body>\s*<\/html>/)

  # split out the style, append style information for links
  style.sub! /<style.*\n/, ''
  style.sub! /\s*<\/style>/, ''
  unindent = style.gsub(/\n\s*\n/,"\n").scan(/^ */).map {|str| str.length}.min
  style.gsub! Regexp.new('^'.ljust(unindent+1)), ''
  style+="\n\n"
  style+=".prev_link:before {content: '#{[171].pack('U')} '}\n"
  style+=".next_link:after {content: ' #{[187].pack('U')}'}\n"
  style+=".next_link .prev_link {text-decoration: none}\n"
  style+=".next_link {float: right}\n"

  def page(section)
    "section-#{section}.html"
  end

  # determine the value for previous / next links
  headers=sections.map {|data| data.slice(/\A\s*<h2>.*/)}
  identity = [nil] + sections[0..-2]
  backward=[nil,nil] + identity[0..-3]
  forward=identity[2..-1] + [nil,nil]

  next_link = {sections[-2] => 
    '<a href="index.html" class="next_link">Table of Contents</a>'}
  prev_link = {sections[0] => 
    '<a href="index.html" class="prev_link">Table of Contents</a>'}

  headers.zip(identity,backward,forward).each do |header, this, before, after|
    next unless header
    header.sub!('</h2', '</a').strip!
    next_link[before] = header.sub('h2>', 
      "a href=#{page(this).inspect} class='next_link'>")
    prev_link[after] = header.sub('h2>', 
      "a href=#{page(this).inspect} class='prev_link'>")
  end

  # adjust todo links
  env.gsub! /<li>.*?<\/li>/m do |li|
    section = li.scan(/href="#(section-.*?)"/).flatten.first
    li.gsub('href="#', "href=\"#{section}.html#").gsub("##{section}\"", '"')
  end

  # hotlink commands in env section
  count = 0
  env.gsub!(/<pre class="stdin">.*<\/pre>/) do |line|
    count += 1
    line.sub('</', '</a></').sub('>',
      " id='cmd#{count}'><a href='#cmd#{count}'>")
  end

  # output the files
  system "rm -rf #{WORK}/checkdepot"
  system "mkdir -p #{WORK}/checkdepot"
  Dir.chdir "#{WORK}/checkdepot" do
    open('depot.css','w') {|file| file.write(style)}
    toc.gsub! /<a href="#(section-[\d\.]+)"/, '<a href="\1.html"'
    open('index.html','w') {|file| file.write(head+toc+env+tail)}
    head.sub! /(<h1.*h1>)/, '<a href="index.html">\1</a>'
    Hash[*sections].each do |section, body|
      links = "      #{next_link[section]}\n      #{prev_link[section]}\n"
      links = "    <p>\n#{links}    </p>\n"
      body = links + '    <a class="toc">'+ body + links

      # hotlink commands
      count = 0
      body.gsub!(/<pre class="stdin">.*<\/pre>/) do |line|
        count += 1
        line.sub('</', '</a></').sub('>',
          " id='cmd#{count}'><a href='#cmd#{count}'>")
      end

      if body =~ /<div class="traceback" title=".* Exception caught">/
        layout = 'actionpack/lib/action_dispatch/middleware/' +
          'templates/rescues/layout.erb'
        if File.exist? "#$rails/#{layout}"
          body += File.read("#$rails/#{layout}")[/<script>.*?<\/script>/m]
        end
      end

      open(page(section),'w') {|file| file.write(head+body+tail)}
    end
  end
end

# copy the log
system "mkdir -p #{WORK}/checkdepot"
system "cp #{LOG} #{WORK}/checkdepot/makedepot.log"

# restore git repositories to master
gems.each do |lib, opts|
  if opts[:branch] and opts[:branch] != 'master'
    Dir.chdir(File.join(HOME,'git',lib)) do
      print lib + ': '
      system 'git checkout master'
    end
  end
end

exit status.exitstatus

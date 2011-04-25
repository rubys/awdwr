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

# update libs
libs = %w(gorp)
gems = []

# add in any 'edge' gems
template = File.join(HOME,'git','rails',
  'railties/lib/rails/generators/rails/app/templates/Gemfile')
if File.exist? template
  base = File.join(HOME,'git','rails',
    'railties/lib/rails/generators/app_base.rb')
  if File.exist? base # Rails 3.1
    libs += File.read(base).scan(/^\s*gem ['"](\w+)['"],\s+:git/)
    gems += File.read(template).scan(/^\s*gem ['"]([-\w]+)['"](,.*)?/)

    release=PROFILE.rvm['bin'].split('-')[1]
    gems += [['json',nil]] if release < "1.9.2"
    gems += [['turn',', :require => false']] unless release < "1.9.2"
  else # Rails 3.0
    gemfile = open(template).read
    libs += gemfile[/edge\? -%>(.*?)<%/m,1].scan(/['"](\w+)['"],\s+:git/)
    gems += [['jquery-rails',nil]]
  end
  libs = libs.flatten.uniq - %w(rails)
end

libs.each do |lib|
  Dir.chdir(File.join(HOME,'git',lib)) { system 'git pull' }
end
ENV['RUBYLIB'] = libs.map {|lib| File.join(HOME,'git',lib,'lib')}.
  join(File::PATH_SEPARATOR)

# update gems
Dir.chdir File.join(PROFILE.source,WORK) do
  if File.exist? File.join($rails, 'Gemfile')
    open('Gemfile','w') do |gemfile|
      gemfile.puts "source 'http://gemcutter.org'"
      gemfile.puts "gem 'rails', :path => #{$rails.inspect}"
      ENV['RUBYLIB'].split(File::PATH_SEPARATOR).each do |path|
        path.sub! /\/lib$/, ''
        name = path.split(File::SEPARATOR).last
        if File.exist?(File.join(path, "/#{name}.gemspec"))
          gemfile.puts "gem #{name.inspect}, :path => #{path.inspect}"
        end
      end
      gems.each {|gem,opts| gemfile.puts "gem #{gem.first.inspect}#{opts}"}
      gemfile.puts "gem 'sqlite3'"
      gemfile.puts "gem 'mysql'"
      gemfile.puts "gem 'will_paginate', '>= 3.0.pre'"
      gemfile.puts "gem 'capistrano'"
      gemfile.puts "gem 'test-unit'"
      gemfile.puts "gem 'rdoc'"
      # begin
      #   require 'nokogiri'
      # rescue LoadError
        gemfile.puts "gem 'htmlentities'"
      # end

      gemfile.puts "gem 'activemerchant'" #, '~> 1.11.0'"
      gemfile.puts "gem 'haml'"
    end
  else
    system 'rm -f Gemfile'
  end
end

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
release=PROFILE.rvm['bin'].split('-')[1]
if source
  Dir.chdir("#{HOME}/.rvm/src") do
    rev = Dir.chdir(source) do
      system 'svn update'
      `svn info`.scan(/Last Changed Rev: (\d+)/).flatten.first
    end

    break if File.exist? "../bin/ruby-#{release}-r#{rev}"

    caches = Dir["#{HOME}/.rvm/gems/#{PROFILE.gems}/cache"]
    caches.reject! {|cache| cache =~ /[%:@]/}
    cache = caches.sort.last

    system "mkdir -p cache"
    system "rm -f cache/*"
    Dir.chdir(File.join(File.dirname(cache),'gems')) {Dir['*']}.each do |gem|
      system "cp #{cache}/#{gem}.gem cache"
    end
    
    bash %{
      cp -r #{source} ruby-#{release}-r#{rev}
      source #{HOME}/.rvm/scripts/rvm
      TERM=dumb rvm install ruby-#{release}-r#{rev}
      rvm #{release}-r#{rev}
      gem env path | cut -d ':' -f 1 | xargs chmod -R 0755
      gem install --no-ri --no-rdoc cache/*
    }

    # keep the last three, and anything built in a week; remove the rest
    horizon = Time.now - 7 * 86400
    keep    = 3

    Dir.chdir("#{HOME}/.rvm") do
      vms = Dir.chdir('rubies') { Dir["ruby-#{release}-r*"].sort }
      vms.slice! -keep..-1
      vms.delete_if {|vm| File.stat("rubies/#{vm}").mtime >= horizon}

      vms.each do |vm|
        system "find . -name #{vm} -exec rm -rf {} \\;"
      end

      gems = Dir.chdir('gems') { Dir["ruby-#{release}-r*"].sort }
      gems.slice! -keep*2..-1
      gems.delete_if {|gem| File.stat("gems/#{gem}").mtime >= horizon}

      gems.each do |gem|
        system "find . -name #{gem} -exec rm -rf {} \\;"
      end
    end
  end
else
  bash %{
    source #{HOME}/.rvm/scripts/rvm
    rvm ruby-#{release} || TERM=dumb rvm install ruby-#{release}
  }
end

# find the rvm
rvm = Dir[File.join(HOME,'.rvm','rubies',PROFILE.rvm['bin'])].sort.last
unless rvm
  puts "Unable to locate #{File.join(HOME,'.rvm','rubies',PROFILE.rvm['bin'])}"
  exit
end

if File.exist? File.join(WORK, 'Gemfile')
  install =  <<-EOF
    gem list bundler | grep -q bundler || gem install bundler
    cd #{WORK}; rm -f Gemfile.lock; bundle install; cd -
  EOF
else
  install = <<-EOF
    gem list rack | grep -q 1.1.0 || gem install rack -v 1.1.0
    gem list will_paginate | grep -q 2 || gem install will_paginate
    gem list activesupport | grep -q 3.0 && gem uninstall activesupport -I -a
  EOF
end

system "rm -f #{WORK}/checkdepot.html"

# run the script
bash %{
  source #{HOME}/.rvm/scripts/rvm
  rvm #{rvm.gsub(/.*\/ruby-/,'')}
  #{install}
  ruby #{PROFILE.script} #{$rails} #{args.join(' ')} > #{LOG} 2>&1
}

status = $?

if File.exist?("#{WORK}/checkdepot.html")
  # parse and normalize checkdepot output
  body = open("#{WORK}/checkdepot.html").read
  body.gsub! "src='data", "src='../data"
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
      open(page(section),'w') {|file| file.write(head+body+tail)}
    end
  end
else
  open(File.join(WORK, 'status'), 'w') {|file| file.puts 'NO OUTPUT'}
end

# copy the log
system "cp #{LOG} #{WORK}/checkdepot/makedepot.log"

# restore rails to master
Dir.chdir($rails) do
  system 'git checkout master' unless BRANCH=='master'
end

exit status.exitstatus

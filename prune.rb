#
# prune unneed gems
#
# Scans Gemfile.lock in each work directory to determine which versions of
# which gems are needed, and uninstalls everything else.
#

require 'rubygems'
require 'require_relative' unless Kernel.respond_to?(:require_relative)
require 'yaml'
require 'shellwords'
require_relative 'clerk'
require_relative 'environment'

# select rvm or rbenv
clerk = Clerk.select
unless clerk
  STDERR.puts "Either rvm or rbenv are required"
  exit 1
end

# load configuration
config = YAML.load_file(ARGV.first || clerk.find_dashboard)
testrails = YAML.load_file(config.delete('testrails'))

# determine a list of environments
environments = []
config['book'].each do |editions|
  editions.each do |book, book_info|
    book_info['env'].each do |info|
      environments << [book, info['rails'], info['ruby']]
    end
  end
end

# iterate over each version of ruby
environments.group_by(&:last).sort.each do |ruby, rows|
  puts ruby
  release = clerk.find(testrails, ruby)

  gems = []
  rows.each do |book, rails, ruby|
    args = [book, rails, ruby].map {|name| name.gsub('.','')}
    info = AWDWR::config(testrails, *args)
    path = info['source'] + '/' + info['work']
    if File.exist? "#{path}/Gemfile.lock"
      gemfile = File.read "#{path}/Gemfile.lock"
      gems += gemfile[/^GEM.*?\n\n/m].scan(/^    ([-\w]+) \(([.\w]+)\)/)
    end
  end
  gems = gems.group_by(&:first).sort.map do |name, versions|
    [name, versions.map(&:last).sort.uniq]
  end
  gems = Hash[gems]

  if RVM.available?
    clerk.run(release, 
      'rvm gemset list | grep -q global && rvm --force gemset delete global')
  end

  found = clerk.capture(release, 'gem list').scan(/([-\w]+) \((.*?)\)/)

  cmds = []
  found.each do |name, versions|
    next if name == 'rvm'
    next if name == 'rubygems-bundler'
    if ruby =~ /^2/
      next if %w(bigdecimal io-console minitest psych rake rdoc test-unit).
        include? name
    end

    versions = versions.split(/, /).sort

    # bundler won't be in Gemfile.lock, so select latest
    if name == 'bundler'
      gems[name] = [clerk.sort(versions).last]
    end

    if gems[name]
      # uninstall unused versions
      if versions != gems[name]
        (versions-gems[name]).each do |version|
          cmds << "gem uninstall --no-executables -I #{name} -v #{version}"
        end
      end
    else
      # uninstall entire gem
      cmds << "gem uninstall --executables -I #{name} --all"
    end
  end

  clerk.run(release, cmds) unless cmds.empty?
  puts
end

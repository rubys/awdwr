#!/usr/bin/ruby
#
# There are two main motivations for this script.
#
# First is bootstrapping.  If you have Rails installed, you have all the
# gems you need to run 'rails new app'.  Doing so creates a Gemfile.
# Running bundle install against that Gem ensures that you have everything
# you need.  The problem comes in when you have a new machine, or are
# testing a new, or even different, version of Rails.  You may not have
# what you need to get started.
#
# Then there is performance.  Bundle update or install when there is a
# source Gem repository involved is both time consuming and susceptible
# to network failures.  Ideally this is only done once per run, and all
# future operations are done with a commented out source line.
#
# Previously, there was a historical motivation, which was to deal with
# releases of Rails prior to Rails 3 which did not support bundler.
#
# output:
#   gems: required gems, possibly with version information
#   libs: repositories that need to be checked out locally, with branch info

def dependencies(rails, ruby)
  libs = %w(gorp)
  gems = []
  branches = []

  # add in any 'edge' gems
  template = File.join(rails, 
    'railties/lib/rails/generators/rails/app/templates/Gemfile')
  base = File.join(rails, 'railties/lib/rails/generators/app_base.rb')

  # grab app dependencies
  if File.exist? template
    gemfile = File.read(template)
    if File.exist? base # Rails 3.1
      app_base = File.read(base)
      app_base.gsub! '#{options[:javascript]}', 'jquery'
      libs += app_base.scan(/^\s*gem ['"]([-\w]+)['"],.*:git/)
      libs += app_base.scan(/^\s*gem ['"]([-\w]+)['"],\s+github:/)
      libs += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],.*:git/)
      gems += gemfile.scan(/^\s*gem ['"]([-\w]+)['"](,.*)?/)

      app_base.scan(/^\s*"?gem '([-\w]+)'(,.*)?"/).each do |gem, opts|
        next if %(rails turn therubyrhino).include? gem
        next if %(ruby-debug ruby-debug19 debugger).include? gem
        next if gems.find {|gname, gopts| gem == gname}
        if opts =~ / :?github(:|\s*=>)/
          libs << gem
        else
          gems << [gem, opts]
        end
      end

      branches = app_base.scan(
        /^\s*gem ['"]([-\w]+)['"],.*:git.*:branch => ['"]([-\w]+)['"]/)

      gems += [['json',nil]] if ruby < "1.9.2"
      if app_base.match(/gem ['"]turn['"]/)
        gems += [['turn',', :require => false']] unless ruby < "1.9.2"
        gems.last.last.sub!(',', ', "0.8.2",') if ruby == '1.9.2'
        gems.last.last.sub!(',', ', "0.8.3",') if ruby == '1.9.3'
      end
    else # Rails 3.0
      libs += gemfile[/edge\? -%>(.*?)<%/m,1].scan(/['"](\w+)['"],\s+:git/)
      gems += [['jquery-rails',', "~> 0.2.2"']]
    end
    libs = libs.flatten.uniq - %w(rails)
    gems.delete_if {|gem,opts| libs.include? gem}
  end

  # add Rails dependencies
  template = File.join(rails,'Gemfile')
  if File.exist? template
    gemfile = File.read(template)
    gemfile.sub! /platforms :jruby.*\nend/m, ''
    gemfile.sub! /group :doc.*\nend/m, ''

    branches += gemfile.scan(
      /^\s*gem ['"]([-\w]+)['"],.*:git.*:branch => ['"]([-\w]+)['"]/)
    libs += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],\s*github:/).flatten
  end

  branches = Hash[branches]
  libs.each {|lib| branches[lib] ||= 'master'}

  [gems, branches]
end

if __FILE__ == $0
  rails = File.join(ENV['HOME'], 'git', 'rails')
  ruby=`ruby -v`[/\d+\.\d+\.\d+/]

  puts "# Ruby #{ruby}"
  puts "# Rails #{File.read("#{rails}/RAILS_VERSION")}"

  gems, libs = dependencies(rails, ruby)

  puts "\ngems"
  gems.each do |gem, option|
    puts " * gem '#{gem}'#{option}"
  end

  puts "\nlibs"
  libs.each do |lib, branch|
    puts " * #{lib} => #{branch}"
  end
end

#!/usr/bin/ruby
#
# There are two main motivations for this script.
#
# First is bootstrapping.  If you have Rails installed, you have all the
# gems you need to run 'rails new app'.  Doing so creates a Gemfile.
# Running bundle install against that Gem ensures that you have everything
# you need.  The problem comes in when you have a new machine, or are
# testing a new, or even different, version of Rails.  You may not have
# what you need to get started.  For example, the ideal way would be to
# run a command like:
#
#  $RAILS/railties/bin/rails new dummy_app --skip-bundle --dev
#
# ... and then parse the generated Gemfile.  But to get this working with
# the current Rails, you need thread_safe, i18n, thor, ...  As I said,
# a bootstrapping problem.
#
# Then there is performance.  Bundle update or install when there is a
# source Gem repository involved is both time consuming and susceptible
# to network failures.  Ideally this is only done once per run, and all
# future operations are done with a commented out source line.
#
# Previously, there was a historical motivation, which was to deal with
# releases of Rails prior to Rails 3 which did not support bundler.
#
# Finally, this provides the ability to do 'fixups' on old releases.
# For example, there no longer is a 2-1-stable branch of sprockets-rails.

module AWDWR
  def self.config(config, *args)
    require 'yaml'
    config = YAML.load_file(config) if String === config
    args = args.first.split(' ') if args.length == 1

    profile = config['default'].dup

    profile.each do |key, value|
      if profile[key].instance_of? String
        profile[key] = value.sub /^\~\//, ENV['HOME'] + '/'
      end
    end

    config.each do |keyword,overrides|
      next unless args.include? keyword.to_s
      overrides.each do |key, value|
        if profile[key].respond_to? :push
          profile[key] += [value]
        else
          profile[key] = value
        end
      end
    end

    profile['work'] = 'work' +
      profile['output'].map {|token| '-'+token.gsub('.','')}.sort.join

    profile['ruby'] ||= profile['rvm'] || profile['rbenv']

    profile['log'] = config.
      find_all {|k,v| v['output'] if ARGV.include? k.to_s}.
      map {|k,v| k}.join('-')

    profile
  end

  def self.dependencies(rails, ruby)
    libs = %w(rails)
    gems = [['http-cookie']]
    branches = []
    repos = [['gorp', 'rubys/gorp']]

    # add in any 'edge' gems
    template = File.join(rails, 
      'railties/lib/rails/generators/rails/app/templates/Gemfile')
    base = File.join(rails, 'railties/lib/rails/generators/app_base.rb')

    if File.read(File.join(rails, 'RAILS_VERSION')) =~ /^[34]/
      gems << ['rack', ', "~> 1.6"']
    end

    # grab app dependencies
    if File.exist? template
      gemfile = File.read(template)
      if File.exist? base # Rails 3.1
        app_base = File.read(base)
        app_base.gsub! '#{options[:javascript]}', 'jquery'
        libs += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],.*:git/)
        gems += gemfile.scan(/^\s*gem ['"]([-\w]+)['"](,.*)?/)
        gems += gemfile.scan(/^\s*# gem ['"]([-\w]+)['"](, ['"].*)/)
        repos += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],\s*github: ['"](.*?)['"]/)

        exclude = %w(
          rails turn 
          therubyrhino therubyracer 
          ruby-debug ruby-debug19 debugger
          rubysl
        )

        # ignore dev-only instructions
        app_base.gsub! /^\s+if options\.dev\?\s+\[.*?\]/m, ''

        pattern = /GemfileEntry\.github[ (]['"]([-\w]+)['"],\s*['"]([-\/\w]+)['"]/
        app_base.scan(pattern) do |gem, repos|
          libs << gem
        end

        pattern = /GemfileEntry\.(new|version)[ (]['"]([-\w]+)['"], (nil)/
        app_base.scan(pattern) do |method, gem, version|
          next if exclude.include? gem
          gems << [gem, nil]
        end

        pattern = /GemfileEntry\.(new|version)[ (]['"]([-\w]+)['"],\s*['"]([^'"]+)['"]/
        app_base.scan(pattern) do |method, gem, opts|
          gems << [gem, ', ' + opts.inspect]
        end

        patterns = [
          /^\s*gem\s+'([-\w]+)'(,.*)?/,
          /^\s*"gem\s+'([-\w]+)'(,.*)"/
        ]

        patterns.each do |pattern|
          app_base.scan(pattern).each do |gem, opts|
            next if exclude.include? gem
            opts = $1 if opts =~ /\? "(.*?)" :/
            next if gems.find {|gname, gopts| gem == gname}
            if opts =~ / :?git(hub)?(:|\s*=>)/
              libs << gem
            else
              gems << [gem, opts]
            end
          end
        end

        branches = app_base.scan(
          /^\s*gem ['"]([-\w]+)['"],.*:git.*:branch => ['"]([-\w]+)['"]/)
        branches += app_base.scan(
          /^\s*gem ['"]([-\w]+)['"],.* github:.*branch: ['"]([-\w]+)['"]/)
        branches += app_base.scan(
          /GemfileEntry\.github[ (]['"]([-\w]+)['"],\s*['"][-\/\w]+['"], ['"](.*?)['"]/)

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
    end

    # add Rails dependencies
    template = File.join(rails,'Gemfile')
    if File.exist? template
      gemfile = File.read(template)
      gemfile.sub! /platforms :jruby.*\nend/m, ''
      gemfile.sub! /group :doc.*?\nend/m, ''
      gemfile.sub! /group :cable.*?\nend/m, ''

      gems += gemfile.scan(/^\s*gem ['"]([-\w]+)['"](,.*)?/)
      branches += gemfile.scan(
        /^\s*gem ['"]([-\w]+)['"],.*:git.*:branch => ['"]([-\w]+)['"]/)
      branches += gemfile.scan(
        /^\s*gem ['"]([-\w]+)['"],.*github:.*branch: ['"]([-\w]+)['"]/)
      repos += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],\s*github: ['"](.*?)['"]/)
      libs += gemfile.scan(/^\s*gem ['"]([-\w]+)['"],\s*github:/).flatten
    end

    # convert options into a hash
    gems = Hash[gems]
    gems.each do |gem, opts|
      hash = {}
      if opts and not opts.include? ':mswin'
        hash[:version] = []
        hash[:version] << eval($1) while opts.sub!(/^,\s*(".*?")/, '') 
        hash[:version] << eval($1) while opts.sub!(/^,\s*('.*?')/, '') 
        while opts.sub!(/(\w+)\s*=?>?:?\s*(.*?)(,\s*|$)/, '')  do
          hash[$1.to_sym] = eval($2)
        end
        opts.sub! /,\s*/, ''
      end
      gems[gem] = hash
    end

    # merge in lib, branches, repository information
    libs.flatten.uniq.each do |lib|
      gems[lib] ||= {}
      gems[lib][:github] ||= "rails/#{lib}"
    end

    branches.each do |lib, branch|
      gems[lib] ||= {}
      gems[lib][:branch] = branch
    end

    repos.each do |lib, repos|
      gems[lib] ||= {}
      gems[lib][:github] = repos
    end

    exclude.each do |lib|
      gems.delete(lib)
    end

    # avoid busted version of rubyprof
    if gems['ruby-prof']
      gems['ruby-prof'].delete :if
      gems['ruby-prof'] = {} if gems['ruby-prof'] == {version: ["~> 0.11.2"]}
    end

    if File.read("#{rails}/RAILS_VERSION") =~ /^[34]\./
      # avoid odd dependencies that don't work in the Gemfiles of so-called
      # 'stable' branches.  :-)
      gems['sprockets'] = {}
      gems['rack'] = {}
      gems['sass-rails'].delete(:github) if gems['sass-rails']
      gems['coffee-rails'].delete(:github) if gems['coffee-rails']
      gems.delete 'journey'

      if gems['sprockets-rails']
        if gems['sprockets-rails'][:branch] == "2-1-stable"
          gems['sprockets-rails'][:branch] = '2.x'
        end
      end
    else
      # include xml serializers
      gems['activemodel-serializers-xml'] = {}
    end

    # ensure gems are compatible with Ruby 1.9.x
    if ruby =~ /^1/
      gems['net-ssh'] = {version: ["~> 2.9"]}
      gems['activemerchant'] = {version: ["~> 1.55.0"]}
    end

    # no need for ibm_db
    gems.delete 'ibm_db'

    # wdm is only for windows
    gems.delete 'wdm'

    # ensure web-console is only run in development mode
    if gems['web-console']
      gems['web-console'][:group] = :development
    end

    # pin version of mysql
    if gems['mysql2']
      gems.delete 'mysql'
      if gems['mysql2'][:version].length == 1
        if gems['mysql2'][:version].first =~ /^>= 0\.3/
          gems['mysql2'][:version] << '< 0.4'
        end
      end
    end

    # branch was renamed
    if gems['sprockets-rails']
      if gems['sprockets-rails'][:branch] == "2-1-stable"
        gems['sprockets-rails'][:branch] = '2.x'
      end
    end

    # bcrypt replaces bcrypt-ruby
    if gems['bcrypt']
      gems.delete('bcrypt-ruby')
    end

    # https://github.com/collectiveidea/delayed_job_active_record/issues/137
    unless File.read("#{rails}/RAILS_VERSION") =~ /^[34]\.|^5\.0/
      gems.delete('delayed_job_active_record')
    end

    # load updates from configuration file
    if 
      File.exist? File.expand_path('~/.awdwr') and
      Dir.exist? File.expand_path('../../gorp', __FILE__)
    then
      require_relative '../gorp/lib/gorp/config'
      $rails = rails
      Gorp::Config.load('~/.awdwr')
      gems.merge! Gorp::Config['gems', {}]
    end

    gems
  end
end

if __FILE__ == $0
  rails = File.join(ENV['HOME'], 'git', 'rails')
  ruby=`ruby -v`[/\d+\.\d+\.\d+/]

  puts "# Ruby #{ruby}"
  puts "# Rails #{File.read("#{rails}/RAILS_VERSION")}"

  gems = AWDWR::dependencies(rails, ruby)

  gems.sort.each do |gem, options|
    next if gem == 'gorp'
    args = []
    if options[:version]
      version = options.delete(:version)
      args.push version.map(&:inspect).join(', ') unless version.empty?
    end
    options.delete :branch if options[:branch] == 'master'
    options.each do |name, value|
      if RUBY_VERSION =~ /^1.8/
        args.push ":#{name} => #{value.inspect}"
      else
        args.push "#{name}: #{value.inspect}"
      end
    end
    puts "gem '#{gem}'#{args.map{|s| ", #{s}"}.join}"
  end
end

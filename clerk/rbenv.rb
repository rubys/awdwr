#
# Note ruby-head does not work.  Prior efforts to make it work:
#
# * http://intertwingly.net/blog/2013/03/21/rbenv-first-impressions
# * https://twitter.com/sstephenson/status/314796965537910784
# * https://github.com/rbenv/ruby-build/issues/332
# * https://github.com/rbenv/ruby-build/pull/334
#

require 'fileutils'
require 'shellwords'
require_relative 'base'

class RBenv < Clerk
  # Is rbenv installed on this machine?
  def self.available?
    !!self.root or not `which rbenv`.empty?
  end

  # Where can RBENV be found
  def self.root
    [ENV['RBENV_ROOT'], File.expand_path('~/.rbenv'), '/usr/local/var/rbenv'].
      find {|path| path and File.exist? path}
  end

  # Update install recipes
  def update
    unless `which brew`.empty?
      system 'brew update'
      system 'brew upgrade rbenv' if `brew outdated`.include? 'rbenv'
      system 'brew upgrade ruby-build' if `brew outdated`.include? 'ruby-build'
    end
  end

  # install (if necessary) a release from source and return it
  def install_from_source(source, release)
    Dir.chdir ENV['RBENV_ROOT'] do
      ruby_source = "sources/#{source}/ruby-#{source}"
      rev = nil

      if File.exist? ruby_source
        Dir.chdir(ruby_source) { `git pull` }
        rev = "#{release}-r#{gitlog(ruby_source).svnid}"
        versions = `rbenv versions --bare`.lines.map(&:strip)
        return rev if versions.include? rev
      end

      system "rm -rf sources/#{source} versions/#{source}"
      system "rbenv global system"
      system "rbenv install -k #{source}"

      rev ||= "#{release}-r#{gitlog(ruby_source).svnid}"

      if File.exist? "versions/#{source}"
        system "mv versions/#{source} versions/#{rev}"
        system "ln -s #{rev} versions/#{source}"
      end

      rev
    end
  end

  # install (if necessary) the latest patch level of a release and return it
  def install_latest(pattern)
    bin = pattern.sub('ruby-',' ')
    release = `rbenv install --list | grep #{bin.sub(/\*$/,'\d').inspect}`.
      lines.sort(&RELEASE_COMPARE).last.strip
    unless `rbenv versions --bare`.lines.map(&:strip).include? release
      system "rbenv install #{release}"
    end
    release
  end

  # prune old releases
  def prune(pattern, keep, horizon)
    Dir.chdir("#{RBenv.root}/versions") do
      vers = Dir[pattern.sub('ruby-','')].sort(&RELEASE_COMPARE)
      vers.pop(keep)
      vers.delete_if {|ver| File.stat(ver).mtime >= horizon}

      vers.each do |ver|
        FileUtils.rm_rf ver if File.exist? ver
      end
    end
  end

  # run a series of commands against a specified ruby release
  def run(release, command)
    ENV['RBENV_VERSION'] = release
    shims = "#{RBenv.root}/shims"
    unless ENV['PATH'].split(':').first == shims
      ENV['PATH'] = "#{shims}:#{ENV['PATH']}"
    end
    command = command.join("\n") if command.respond_to? :join
    command.lines.each do |line|
      system line.chomp
    end
  end

  # find latest version for a given ruby release
  def find(testrails, ruby)
    bin = AWDWR::config(testrails, ruby.gsub('.',''))['ruby']['bin']
    pattern = Regexp.new(bin.sub(/^ruby-/,'').sub(/\*$/,'\d'))
    ruby = `rbenv versions --bare`.lines.map(&:strip).grep(pattern).
      sort(&RELEASE_COMPARE).last
  end

  # capture output from a command
  def capture(ruby, command)
    `bash -c #{Shellwords.escape "RBENV_VERSION=#{ruby} #{command}"}`
  end
end

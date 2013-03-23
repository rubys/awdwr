require 'fileutils'
require 'shellwords'
require_relative 'base'

class RVM < Clerk
  # Is RVM installed on this machine?
  def self.available?
    !!self.path
  end

  # Where can RVM be found
  def self.path
    @path ||= [ENV['rvm_path'], File.expand_path('~/.rvm'), '/usr/local/rvm'].
      find {|path| path and File.exist? path}
  end

  # Update install recipes
  def update
    unless File.read("#{RVM.path}/VERSION") == `curl -s #{RVM::STABLE}/VERSION`
      system "#{RVM.path}/bin/rvm get stable"

      # monkey patch
      # https://github.com/wayneeseguin/rvm/commit/f8e14c21feea12c5a40c444e78e9bd2afa68e7bd
      system "sed -i 's/=\"ruby_1/=\"ruby_${rvm_ruby_release_version:-1}/' " +
        "#{RVM.path}/scripts/functions/manage/base"
    end
  end

  # install (if necessary) a release from source
  def install_from_source(source, release)
    Dir.chdir("#{RVM.path}/src") do
      system "../bin/rvm fetch ruby-head" unless File.exist? "../repos/ruby"
      rev = Dir.chdir("#{RVM.path}/repos/ruby") do
        `git checkout #{source} 2>/dev/null`
        `git pull`
        log = `git log -n 1`
        if source == 'trunk'
          "n#{log[/git-svn-id: .*@(\d*)/,1]}"
        else
          "s#{log[/commit ([a-f0-9]{8})/,1]}-n#{log[/git-svn-id: .*@(\d*)/,1]}"
        end
      end

      release=PROFILE.rvm['bin'].split('-')[1]

      unless File.exist? "../bin/ruby-#{release}-#{rev}"
        shell "rvm install ruby-#{release}-#{rev}"
      end

      "ruby-#{release}-#{rev}"
    end
  end

  # install (if necessary) the latest patch level of a release and return it
  def install_latest(pattern)
    release = pattern[/^(ruby-)?(.*?)(-\w+\*)?$/,2]
    shell "rvm ruby-#{release} || rvm install #{release}"
    Dir[File.join(RVM.path,'rubies',pattern)].sort(&RELEASE_COMPARE).last
  end

  # prune old releases
  def prune(pattern, keep, horizon)
    Dir.chdir(RVM.path) do
      vms = Dir.chdir('rubies') { Dir[pattern].sort(&RELEASE_COMPARE) }
      vms.pop(keep)
      vms.delete_if {|vm| File.stat("rubies/#{vm}").mtime >= horizon}

      vms.each do |vm|
        dirs = `find . -name #{vm}`
        dirs += `find . -name #{vm}@global`
        dirs.chomp.split("\n").each do |dir|
          FileUtils.rm_rf dir
        end
      end
    end
  end

  # run a series of commands against a specified ruby release
  def run(release, command)
    command = command.join("\n") if command.respond_to? :join
    shell "rvm #{release}\n#{command}"
  end

protected

  # where to find the stable release
  STABLE = "https://raw.github.com/wayneeseguin/rvm/stable"

  # execute a series of commands in one shell invocation
  def shell cmd
    cmd = "source #{RVM.path}/scripts/rvm\n#{cmd}"
    cmd = cmd.strip.gsub(/^\s+/,'').gsub(/\n/,'; ')
    puts cmd
    system "bash -c #{Shellwords.escape cmd}"
  end
end

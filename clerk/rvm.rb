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
    end
  end

  # install (if necessary) a release from source
  def install_from_source(source, release)
    unless File.exist? "#{RVM.path}/repos/ruby"
      system "#{RVM.path}/bin/rvm fetch ruby-head" 
    end

    Dir.chdir("#{RVM.path}/repos/ruby") do
      `git checkout #{source} 2>/dev/null`
      `git pull`
    end

    log = gitlog("#{RVM.path}/repos/ruby")
    rev = if source == 'trunk'
      "n#{log.svnid}"
    else
      "s#{log.commit}-n#{log.svnid}"
    end

    release=PROFILE.rvm['bin'].split('-')[1]

    unless File.exist? "#{RVM.path}/bin/ruby-#{release}-#{rev}"
      shell "#{RVM.path}/bin/rvm --autolibs=read install ruby-#{release}-#{rev}"
      exit unless File.exist? "#{RVM.path}/bin/ruby-#{release}-#{rev}"
    end

    "ruby-#{release}-#{rev}"
  end

  # install (if necessary) the latest patch level of a release and return it
  def install_latest(pattern)
    release = pattern[/^(ruby-)?(.*?)(-\w+\*)?$/,2]
    shell "rvm ruby-#{release} || rvm --autolibs=read install #{release}"
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
          FileUtils.rm_rf dir if File.exist? dir
        end
      end
    end
  end

  # run a series of commands against a specified ruby release
  def run(release, command)
    command = command.join("\n") if command.respond_to? :join
    shell "rvm #{release}\n#{command}"
  end

  # capture output from a command
  def find(testrails, ruby)
    bin = AWDWR::config(testrails, ruby.gsub('.',''))['ruby']['bin']
    Dir.chdir "#{RVM.path}/rubies" do
      `ls -d #{bin}`.lines.map(&:strip).sort(&RELEASE_COMPARE).last
    end
  end

  # find latest version for a given ruby release
  def capture(ruby, command)
    command = "source #{RVM.path}/scripts/rvm; rvm #{ruby}; #{command}"
    `bash -c #{Shellwords.escape command}`
  end

protected

  # where to find the stable release
  STABLE = "https://raw.github.com/wayneeseguin/rvm/stable"

  # execute a series of commands in one shell invocation
  def shell cmd
    cmd = "source #{RVM.path}/scripts/rvm\n#{cmd}"
    cmd = cmd.strip.gsub(/^\s+/,'').gsub(/\n/,'; ')
    system "bash -c #{Shellwords.escape cmd}"
  end
end

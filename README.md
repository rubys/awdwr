Introduction
============

Agile Web Development with Rails (awdwr) is a test suite for the scenario
found in the
[book by the same name](https://pragprog.com/titles/rails6) published by Pragmatic Programmers.  It was originally developed out of self defence to keep up with the rapid pace of change in Rails itself, and has also proven valuable as a [system test](https://github.com/rails/rails/blob/master/RELEASING_RAILS.md#is-sam-ruby-happy--if-not-make-him-happy) for rails itself.

This code has been developed over a long period of time, and still has
accommodations for things like:

  * The days before puma was the default
  * The days before SCSS and CoffeeScript
  * The days before sprockets when images were placed in `public/images`
  * The days before bundler existed
  * Ruby 1.8.7's hash syntax and the requirement to require `rubygems` if
    you wanted to use it.

It works natively on Mac OS/X El Capitan and Ubuntu 14.04.  It works with
either `rbenv` or `rvm`.  The dashboard can be run as CGI under Apache httpd,
using Passenger on nginx, or simply with WebBrick.

Instructions are provided separately for usage under [vagrant](vagrant#readme)
and [cloud9](cloud9.md).  Or install
[Rails Dev Box](https://github.com/rails/rails-dev-box#readme), ssh into the vagrant machine and run the following command:

  eval "$(curl https://raw.githubusercontent.com/rubys/awdwr/master/rdb-setup)"

Control over directory locations and versions to be tested is provided by
[dashboard.yml](dashboard.yml) and [testrails.yml](testrails.yml).

Installation
============

Installation of all necessary dependencies from a fresh install of Ubuntu or
Mac OS/X:

    ruby setup.rb # see comments if dependencies aren't met

Execution instructions:

    ruby makedepot.rb [VERSION] [restore] [RANGE]... [save] --work=dir --port=n

Description of the options:

    "restore" - restore from snapshot before resuming execution

    "VERSION" specifies the Rails version to test.  Examples:
      edge
      _2.2.2_
      ~/git

    "RANGE" specifies a set of sections to execute.  Examples:
      6.2..6.5
      7.1-9.5
      16

    "save" - save snapshot after execution completes

    --work=dir: name of work directory to use (default: "work")

    --port=n: port number to use for the test (default: 3000)

Output will be produced as makedepot.html.

Tests against makedepot.html can also be run separately:

    ruby checkdepot.rb

Output will be produced as checkdepot.html.

Automation tools:

  * setup.rb:     initial setup and verification
  * testrails.rb: front end to makedepot that manages the environment
  * dashboard.rb: cgi to monitor status / start jobs

Sample configuration data:

  * testrails.yml: provides mappings for edition, rails, and ruby versions
  * dashboard.yml: lists test configurations

Sample output:

  http://intertwingly.net/projects/dashboard.html

=======

M1 mac setup:

```
brew install svn

brew install mysql
brew services restart mysql

brew install chromedriver
# install google chrome
# add to .zshrc:
# export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

brew install gpg

brew install postgresql

brew install zstd

brew install openjdk@11
sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

brew install node

brew install imagemagick

mkdir -p ~/git
cd ~/git
git clone git@github.com:rubys/awdwr.git
cd awdwr
ruby setup.rb
npm install

sudo launchctl load -w /System/Library/LaunchDaemons/org.apache.httpd.plist
```

Later, in work directory:

```
bundle config --local build.mysql2 "--with-ldflags=-L/opt/homebrew/Cellar/zstd/1.5.0/lib"

bundle config build.eventmachine --with-cppflags=-I$(brew --prefix openssl)/include

bundle install

rvm wrapper /Users/rubys/git/awdwr/rproxy.rb
cp ../awdwr.rproxy.plist ~/Library/LaunchAgents
launchctl load -w ~/Library/LaunchAgents/awdwr.rproxy.plist
```

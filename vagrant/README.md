Quick Start
===========

Install [vagrant](http://www.vagrantup.com/).

Tweak `awdwr/vagrant/Vagrantfile` if necessary, then run the following command
to install and configure everything needed to run the Agile Web Development
with Rails tests using Vagrant:

    cd awdwr/vagrant; vagrant up

Upon completion, the installation will report the address of the web
interface.

A complete run, including deployment, of the default versions of Ruby and
Rails can be accomplished with the following command:

    vagrant ssh -c "bin/testrails; source bin/work; ruby ../deploydepot.rb"

Using the Web Interface
=======================

At the bottom of the table is an input field.  Enter any combination of:

  - A one digit edition number for the book (currently only 4 is supported)
  - A two digit Rails version (e.g., 40 or 32)
  - A three digit Ruby version (e.g. 200 or 193)
 
For convenience, you can click on a column header to sort by that column, and
you can click on an individual time entry to pre-fill in the input field.  By
holding down the control key (command on Mac OS X) you can select multiple
builds to be executed sequentially.

Press submit.  Status will show up at the bottom.  The first time you run
this, it will take some time as it will install the necessary version of Ruby
and download gems and checkout repositories.  Once it begins running the
actual test you will be able to see what step it is running.

In the top right is a link to the `logs` directory, which can be useful when
things go wrong.

Using the Command interface
---------------------------

Before proceeding, a bit of knowledge as to how the directories are laid out
is in order.  As Rails is commonly used, one may have multiple applications
and each is largely self contained.  This test suite flips that around, one
has multiple copies of the application(s) and a single checked out copy of
each repository.

    vagrant ssh

The command run by the web interface is `testrails` and it can be run directly
from the command line.  This does all of the necessary setup, including
updating RVM, installing Ruby, updating bundler, and updating gems; steps that
generally do not need to be repeated.

More commonly, what is needed when running interactively is to make use of the
existing repositories and directories.  This involves a number of `git`
commands and a final `cd` command.  The `work` alias is set up to do this, and
will allow you to switch quickly and easily from one configuration to another.
Arguments to `work` are the same as to `testrails`, and default to whatever
the current release is.  At the moment, that is Book edition 4, Rails 40, and
Ruby 200.

From here, you can ruby `rails new` or `cd depot` and run `rails console` or
`rails server`.  Modify the application as you see fit, as it will be
recreated from scratch on the next test run.

Alternately, `depot` can be used to can run all or a subset of steps in the
scenario by identifying the starting and stopping section numbers.  For
example,

    depot 6.1-10.1

This can be used in combination with `git bisect`:

    cd ~/git/rails
    git bisect start
    git bisect bad
    git checkout <revision>
    git bisect good
    git bisect run depot 6.1-10.1

Other possibilities include pulling or directly applying changes to rails or
other dependencies and restarting the tests at any point.

Testing Deployment
------------------

Deployment using Apache, Phusion Passenger and Capistrano can be initiated
using the command line:

    work
    ruby ../deploydepot.rb

Results are self checking.  Output can be seen by refreshing the dashboard
and clicking on the `deploy` link in the top left.

The deployed application can be accessed by adding a `depot.pragprog.com`
entry in the `/etc/hosts` file on your host machine with the ip address
of your vagrant box.

Cleaning up
===========

The entire vm can be removed using the following command:

    vagrant destroy

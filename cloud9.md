Quick Start
===========

1. Sign up with [Cloud9](https://c9.io/).

2. Create a new workspace

   * Enter a workspace name (e.g., `awdwr`)

   * Specify `https://github.com/rubys/awdwr.git` as the clone URL

   * Chose the **Ruby** template (the one with the Rails logo)

   * Click `Create workspace`

3. In the bash pane at the bottom right enter the following command:
   `source c9setup`.  This will clone a few repositories, most notably
   `rails`, which will take a while.

4. In the same bash pane, enter the following command: `rake dashboard`.
   You should see a helpful alert in the top right of this pane telling
   you that your code is running.  Click on the link to see the dashboard.

Using the Web Interface
=======================

At the bottom of the table is an input field.  Enter any combination of:

  - A one digit edition number for the book (currently only 4 is supported)
  - A two digit Rails version (e.g., 40 or 32)
  - A three digit Ruby version (e.g. 200 or 193)
  - A range of sections to execute (e.g. 6.1-6.3)
 
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

There are three levels of commands, depending on what you want to accomplish.
All three are defined as bash aliases for your convenience.

1. `testrails`. This is actually what the dashboard shells out to.  You can
   pass it the same combination of numbers as the web interface supports.
   This will (as needed) install versions of Ruby, pull from git repositories, 
   and install gems.

2. `work`.  This changes your current working directory, changing the
   version of Ruby and checking out the appropriate branches as required.
   This is all done without any network interaction, so is fairly fast.  It
   takes the same parameters as `testrails` *except* for the range of
   sections.  From here you can enter `rails` commands (e.g. `rails
   db:migrate`).  Be sure to use the web IDE in the left and top panes to
   browse/edit files as your favorite text editor is not going to work.

3. `depot`.  This runs a range of sections using your current working
   directory.  In addition, you can pass `save` and `restore` to snapshot the
   state.  (Example: `depot 6.1-6.3 save` followed later by 
   `depot restore 6.4`).

Note that you don't actually have to be in the working directory to run the
depot command, you just have to have set it up with the `work` command.  This
is handy when you want to `git bisect` on the Rails repository: start by
running `work`, then `cd ~/git/rails`, then `git bisect start`.

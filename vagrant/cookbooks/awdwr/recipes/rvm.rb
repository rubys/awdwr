#
# Install curl and git
# Install rvm
# Install compiler dependencies for Ruby 2.0.0
#

package 'curl'
package 'git'

execute "install rvm" do
  user 'vagrant'
  group 'vagrant'
  environment 'HOME' => '/home/vagrant'
  command '\curl -L https://get.rvm.io | bash -s stable'
  creates '/home/vagrant/.rvm'
end

bash "install compiler dependencies" do
  environment 'rvm_path' => '/home/vagrant/.rvm'
  code %{
    source $rvm_path/scripts/rvm
    rvm --autolibs=enable requirements ruby-2.0.0
  }
end

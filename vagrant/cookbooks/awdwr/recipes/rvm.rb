#
# Install curl and git
# Install rvm
# Install compiler dependencies for Ruby 2.0.0
#

package 'curl'
package 'git'

bash "install rvm" do
  user 'vagrant'
  group 'vagrant'
  environment 'HOME' => '/home/vagrant'
  code %{
    if [[ -e /vagrant/cache/rvm-src ]]; then
      cd /vagrant/cache/rvm-src
      ./install
      if [[ $(curl -s https://raw.github.com/wayneeseguin/rvm/stable/VERSION) != $(cat /home/vagrant/.rvm/VERSION) ]]; then
        source /home/vagrant/.rvm/scripts/rvm
        rvm get stable
        cp -Lr /home/vagrant/.rvm/src/rvm /vagrant/cache/rvm-src
      fi
    else
      gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
      curl -sSL https://get.rvm.io | bash -s $1

      cp -Lr /home/vagrant/.rvm/src/rvm /vagrant/cache/rvm-src
      cp -Lr /home/vagrant/.rvm/archives /vagrant/cache/rvm-archives
    fi

    rm -rf /home/vagrant/.rvm/archives
    ln -s /vagrant/cache/rvm-archives /home/vagrant/.rvm/archives

    rm -rf /home/vagrant/.rvm/repos
    ln -s /vagrant/cache/rvm-repos /home/vagrant/.rvm/repos
  }
  creates '/home/vagrant/.rvm'
end

bash "install compiler dependencies" do
  environment 'rvm_path' => '/home/vagrant/.rvm'
  code %{
    source $rvm_path/scripts/rvm
    rvm requirements --autolibs=enable
  }
end

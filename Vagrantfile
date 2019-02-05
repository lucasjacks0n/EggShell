# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  # mount shared folder to test file upload/download with known hashes
  config.vm.synced_folder "test/victim_files", "/home/vagrant/my_files"

  # disable default file share
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "shell", inline: <<-SHELL
    # enable password auth (default vagrant:vagrant)
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    systemctl restart sshd

    # install python
    apt install -y python-minimal
  SHELL
end

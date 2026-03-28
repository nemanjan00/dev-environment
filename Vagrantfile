# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine319"
  config.vm.hostname = "dev"

  config.vm.provider :libvirt do |v|
    v.memory = 4096
    v.cpus = 2
    v.memorybacking :access, :mode => "shared"
    v.management_network_name = "vagrant-dev"
    v.management_network_address = "192.168.123.0/24"
  end

  # Share project directory into the VM (virtiofs — native libvirt mount)
  config.vm.synced_folder ".", "/vagrant", type: "virtiofs"

  # Mount external project to work on
  if ENV['PROJECT_DIR']
    config.vm.synced_folder ENV['PROJECT_DIR'], "/project", type: "virtiofs"
  end

  config.vm.provision "shell", inline: <<-SHELL
    # Use working Alpine mirrors
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

    # Install Docker
    apk update
    apk add docker
    rc-update add docker default
    service docker start

    # Allow vagrant user to use Docker
    addgroup vagrant docker 2>/dev/null || true

    # Wait for Docker to be ready
    while ! docker info > /dev/null 2>&1; do sleep 1; done

    # Pull the dev environment image
    docker pull nemanjan00/dev
  SHELL
end

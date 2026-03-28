# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine319"
  config.vm.hostname = "dev"

  config.vm.provider :libvirt do |v|
    v.memory = 4096
    v.cpus = 2
    v.memorybacking :access, :mode => "shared"
  end

  # Share project directory into the VM (virtiofs — native libvirt mount)
  config.vm.synced_folder ".", "/vagrant", type: "virtiofs"

  project_root = File.realpath(".")

  # Mount external project to work on (skip if same as project root to avoid duplicate virtiofs target)
  if ENV['PROJECT_DIR']
    project_dir = File.realpath(ENV['PROJECT_DIR'])
    if project_dir != project_root
      config.vm.synced_folder ENV['PROJECT_DIR'], "/project", type: "virtiofs"
    end
  end

  # Mount Claude config if it exists (skip if same as an already-mounted path)
  if ENV['CLAUDE_CONFIG_DIR']
    claude_dir = File.realpath(ENV['CLAUDE_CONFIG_DIR'])
    if claude_dir != project_root && (!ENV['PROJECT_DIR'] || claude_dir != File.realpath(ENV['PROJECT_DIR']))
      config.vm.synced_folder ENV['CLAUDE_CONFIG_DIR'], "/claude-config", type: "virtiofs"
    end
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

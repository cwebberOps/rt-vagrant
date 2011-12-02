# Request Tracker 4

This repo is intended as an easy way to get a test evironment going for RT 4 and as a starting point for a production install.

# Dependancies
This requires you to have Vagrant setup. Please see http://vagrantup.com for more details.

# Getting Started

Clone the repo and make it your working directory:
    git clone git://github.com/cwebberOps/rt-vagrant.git
    cd rt-vagrant

Bring up the new instance:
    vagrant up

Once everything is up browse to http://10.0.0.10/rt to get started.

# Misc Details
If you would rather use Ubuntu, change Vagrantfile to be symlinked to Vagrantfile.ubuntu

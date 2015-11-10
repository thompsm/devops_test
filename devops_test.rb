# devops_test.rb
require 'chef/provisioning/vagrant_driver'

# Define which Ubuntu image we're going to use and where to download
# it from
vagrant_box 'precise64' do
  url 'http://files.vagrantup.com/precise64.box'
end

# Tell provisioning we want to use Vagrant
with_driver 'vagrant'

# Tell provisioning to use the Ubuntu image
with_machine_options :vagrant_options => {
  'vm.box' => 'precise64'
}

# Define how many app servers we want to provision
num_appservers = 2

machine_batch do

  # Create appserver machines
  1.upto(num_appservers) do |i|
    machine "appserver#{i}" do
      # Tell the vagrant driver to add a private network address to give each machine a unique IP
      add_machine_options :vagrant_config => ["config.vm.network \"private_network\", ip: \"10.0.10.10#{i}\""].join("\n")

      # Define which Chef cookbook we want to run on the box
      # appserver will compile a Go file and then run it to respond to an http request
      run_list ['recipe[appserver::default]']
    end
  end

  # Create the front end web server
  machine 'webserver' do
    # Tell the vagrant driver to add a private network address to give the machine a unique IP
    # and to define a port forward so we can test the app
    add_machine_options :vagrant_config => ['config.vm.network "private_network", ip: "10.0.10.100"', 'config.vm.network :forwarded_port, guest: 80, host: 8080'].join("\n")

    # Pass an attribute to the webserver cookbook to to tell it how many app servers we will provision
    attribute ['devops_test', 'num_of_app_servers'], num_appservers

    # Define which Chef cookbook we want to run on the box
    # webserver will install nginx and configure it to load balance requests to the
    # defined number of app servers
    run_list ['recipe[webserver::default]']
  end

end

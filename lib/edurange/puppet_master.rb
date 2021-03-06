module Edurange
  class PuppetMaster
  
	# Returns or obtains? an external IP address using Amazon's API.
	# @return [String] the IP address?
    def self.puppetmaster_ip
      puts "Obtaining external ip"
      `curl ifconfig.me 2>/dev/null`
    end
	
	# Either returns our current SSH key or a newly generated one if no current SSH key found
	# @return [String] the SSH public key
    def self.get_our_ssh_key
      `ssh-keygen -t rsa -f #{ENV['HOME']}/.ssh/id_rsa -N '' -q` unless File.exists?("#{ENV['HOME']}/.ssh/id_rsa")
      file = File.open("#{ENV['HOME']}/.ssh/id_rsa.pub", "rb")
      contents = file.read
    end

	# Generates certificates so puppet can authenticate our client. The certificates and such are passed through securely using EC2's API
	# @return [Array<String>] UUID, SSL certificate, CA certificate, client SSH private key
    def self.gen_client_ssl_cert
	  # Generates a UUID
      uuid = `uuidgen`.chomp
	  # Creates certificate using puppet
      `sudo puppet cert --generate #{uuid}`
	  # Read the cert auth file
      ssl_cert = `sudo cat /var/lib/puppet/ssl/certs/#{uuid}.pem`.chomp
      ca_cert = `sudo cat /var/lib/puppet/ssl/certs/ca.pem`.chomp
	  # Read the private key generated for client
      private_key = `sudo cat /var/lib/puppet/ssl/private_keys/#{uuid}.pem`.chomp
      return [uuid, ssl_cert, ca_cert, private_key]
    end
	
	# Appends the given configuration string to the configuration script “my-user-script.sh”
	# @param conf [String] the desired configuration
    def self.append_to_config(conf)
      File.open("my-user-script.sh", 'a+') do |file|
        file.write(conf)
      end
    end
	
	# Creates a configuration file for the given instance using the given configuration string. Stored in /etc/puppet/manifests/#uuid.pp
	# @param instance_id [String] the ID of the desired instance
	# @param conf [String] the desired configuration
    def self.write_puppet_conf(instance_id, conf)
      File.open("#{ENV['HOME']}/edurange/derp.pp", "w") do |file|
        file.write(conf)
      end
      `sudo mv #{ENV['HOME']}/edurange/derp.pp /etc/puppet/manifests/#{instance_id}#{Time.now.to_s.gsub(' ','')}.pp`
    end
	
	# Generates a startup script for the given instance. Saved as “my-user-script.sh”
	# @param puppetmaster_ip [String]
	# @param certs [String]
	# @param puppet_conf [String]
	# @param facter_facts [String]
    def self.write_shell_config_file(puppetmaster_ip, certs, puppet_conf, facter_facts)
      # Things done in here include:
      # - Adding puppetmaster's (instructor's) ssh key to instance
      # - Installing puppet
      # - Move clientside puppet.conf file in place
      # - Setting puppet to be the IP of the puppetmaster in /etc/hosts (so ping puppet pings the puppetmaster)
      # - Creating a directory to store facts in (facts later referenced in puppet to install software. Essentially "tagging" our instances)
      # - Reloading puppet
      File.open("my-user-script.sh", 'w') do |file|
        file_contents = <<contents
#!/bin/sh
set -e
set -x
echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt

killall dpkg || true
sleep 5
dpkg --configure -a

apt-get update; apt-get upgrade -y

echo #{puppetmaster_ip.chomp} puppet >> /etc/hosts
apt-get -y install puppet

mkdir -p /var/lib/puppet/ssl/certs
mkdir -p /var/lib/puppet/ssl/private_keys
mkdir -p /etc/puppet

mkdir -p /etc/facts.d
echo '#{facter_facts}' >> "/etc/facts.d/facts.txt"

echo '#{certs[1]}' >> "/var/lib/puppet/ssl/certs/#{certs[0]}.pem"
echo '#{certs[2]}' >> "/var/lib/puppet/ssl/certs/ca.pem"
echo '#{certs[3]}' >> "/var/lib/puppet/ssl/private_keys/#{certs[0]}.pem"

echo '#{puppet_conf.chomp}' > /etc/puppet/puppet.conf

sed -i /etc/default/puppet -e 's/START=no/START=yes/'
service puppet restart

echo "Goodbye World.  The time is now $(date -R)!" >> /root/output.txt
contents
        file.write(file_contents)
      end
    end
	
	# Generates a puppet.conf file for the client.
	# @returns [String] the puppet.conf string
    def self.generate_puppet_conf(uuid)
      # Certname is the UUID generated by the puppetmaster earlier and passed in,
      # the cert itself authenticates the client ("puppet") with the puppetmaster.
  conf_file = <<conf
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
templatedir=$confdir/templates
prerun_command=/etc/puppet/etckeeper-commit-pre
postrun_command=/etc/puppet/etckeeper-commit-post
runinterval=60 # run every minute for debug TODO REMOVE
pluginsync=true

[master]
# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN 
ssl_client_verify_header = SSL_CLIENT_VERIFY

[agent]                                                                                                                                                                                          
certname=#{uuid}
conf
    end
  end
end

# There's a lot of stuff to do here, step by step.

#require 'net/ssh'

# Config

EC2_UTILS_PATH = "/home/ubuntu/ec2/bin/"

ami_id = "ami-e720ad8e"

vm_size = "t1.micro"

key_name = "petra" # ec2 key name, not file name

puppetmaster_ip = `curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`

#command = "ec2-run-instances #{ami_id} -t #{vm_size} --region us-east-1 --key #{key_name} --user-data-file combined-userdata.txt"
command = "ec2-run-instances #{ami_id} -t #{vm_size} --region us-east-1 --key #{key_name} --user-data-file my-user-script.sh"
#command = "ec2-run-instances #{ami_id} -t #{vm_size} --region us-east-1 --key #{key_name} -d 'wutloluhh'"

# Spin up some vms

def run(command)
  # runs an ec2 command with full path.
  command = EC2_UTILS_PATH + command
  `#{command}`
end

def get_our_ssh_key
  # make some ssh keys
  `ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -N '' -q` unless File.exists?("/home/ubuntu/.ssh/id_rsa")
  # return our public key
  file = File.open("/home/ubuntu/.ssh/id_rsa.pub", "rb")
  contents = file.read
end

def puppetmaster_setup

end

def gen_client_ssl_cert
  # We need to:
  # Generate unique name (UUIDgen)
  uuid = `uuidgen`.chomp
  puts uuid
  # Create cert for name on puppetmaster
  `sudo puppetca --generate #{uuid}`
  ssl_cert = `sudo cat /var/lib/puppet/ssl/certs/#{uuid}.pem`
  ca_cert = `sudo cat /var/lib/puppet/ssl/certs/ca.pem`
  private_key = `sudo cat /var/lib/puppet/ssl/private_keys/#{uuid}.pem`
  return [uuid, ssl_cert, ca_cert, private_key]

  # Ensure client has line in puppet.conf to use generated cert
end

#def init_crontab
  # set up crontab to refresh list of signable hosts
  # * * * * * ec2-describe-instances | grep ^INSTANCE | grep -v terminated | awk '{print $4}' > /etc/puppet/autosign.conf 
#end

def write_shell_config_file(ssh_key, puppetmaster_ip, certs)
  File.open("my-user-script.sh", 'w') do |file|
    file_contents = <<contents
#!/bin/sh
set -e
set -x
echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt' + "
apt-get update; apt-get upgrade -y

key='#{ssh_key.chomp}'
echo $key >> /home/ubuntu/.ssh/authorized_keys

echo #{puppetmaster_ip} puppet >> /etc/hosts "
apt-get -y install puppet

echo '#{certs[1]}' >> /var/lib/puppet/ssl/certs/#{certs[0]}.pem
echo '#{certs[2]}' >> /var/lib/puppet/ssl/certs/ca.pem
echo '#{certs[3]}' >> /var/lib/puppet/ssl/private_keys/#{certs[0]}.pem

sed -i /etc/default/puppet -e 's/START=no/START=yes/'
service puppet restart

echo "Goodbye World.  The time is now $(date -R)!" | tee /root/output.txt

contents
    file.write(file_contents)
  end
end

our_ssh_key = get_our_ssh_key()

certs = gen_client_ssl_cert()
write_shell_config_file(our_ssh_key,puppetmaster_ip, certs)

#run(command)

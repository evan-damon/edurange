# There's a lot of stuff to do here, step by step.

#require 'net/ssh'

# Config
EC2_UTILS_PATH = "/home/ubuntu/ec2/bin/"

ami_id = "ami-e720ad8e"

vm_size = "t1.micro"

key_name = "petra" # ec2 key name, not file name

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

def write_shell_config_file(ssh_key)
  File.open("my-user-script.sh", 'w') do |file|
    file.write("#!/bin/sh\n")
    file.write("set -e\nset -x\n")
    file.write('echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt' + "\n")
    file.write("apt-get update; apt-get upgrade -y\n")
    file.write("key='#{ssh_key.chomp}'")
    file.write("\necho $key >> /home/ubuntu/.ssh/authorized_keys\n")
    file.write('echo "Goodbye World.  The time is now $(date -R)!" | tee /root/output.txt' + "\n")
  end
end

our_ssh_key = get_our_ssh_key()
write_shell_config_file(our_ssh_key)

run(command)

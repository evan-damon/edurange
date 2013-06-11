module Edurange
  # Creates and spins up (starts) a new Amazon Machine Instance (AMI). The AMI is configured according to the specified attributes.
  # @attribute uuid [String] Returns the UUID associated with this instance.
  # @attribute ami_id [String] Returns the ID of the AMI.
  # @attribute key_name [String] Returns the name of the key-value pair associated with this instance.
  # @attribute vm_size [String] Returns the size of this instance's virtual machine (default is +t1.micro+).
  # @attribute ip_address [String] Returns the IP address given to this instance.
  # @attribute users [String] Returns a string containing the users associated with this instance.
  class EduMachine
    attr_reader :uuid, :ami_id, :key_name, :vm_size, :ip_address, :users

    EC2_UTILS_PATH = ENV['HOME'] + "/.ec2/bin/"

    # Initializes the AMI by defining its attributes.
    # @param uuid [String] the Universally Unique ID of the instance to be configured.
    # @param key_name [String] a key name for the AMI's key-value pair.
    # @param ami_id [String] an ID for the machine instance.
    # @param vm_size [String] the size of the virtual machine to be used.
    def initialize(uuid, key_name, ami_id, vm_size="t1.micro")
      @uuid = uuid
      @instance_id = nil
      @key_name = key_name
      @vm_size = vm_size
      @ami_id = ami_id
    end

    # Defines the initial users of this instance.
    # @param users [String] the list of users to be used as this instance's initial users.
    def initial_users(users)
      @users = users
    end

    # Runs an EC2 command using the {EduMachine::EC2_UTILS_PATH full path} of the EC2 bin file.
    def run(command)
      # runs an ec2 command with full path.
      # TODO this should be replaced, as well as places calling it, with AWS-SDK specific commands
      command = EC2_UTILS_PATH + command
      `#{command}`
    end

    def spin_up
      # Create & run instance, setting instance variables instance_id and IP to match the newly created ami
      puts "Creating instance (ami id: #{@ami_id}, size: #{@vm_size})"
      command = "ec2-run-instances #{@ami_id} -t #{@vm_size} --region us-east-1 --key #{@key_name} --user-data-file my-user-script.sh"
      self.run(command)
      @instance_id = self.get_last_instance_id()
      puts "Instance created."
      puts "Waiting for instance #{@instance_id} to spin up..."
      sleep(40)
      self.update_ec2_info()
      self
    end

    def update_ec2_info
      # Get connectivity information assuming we have instance ID
      command = "ec2-describe-instances | grep INSTANCE | grep '#{@instance_id}'"
      vm = self.run(command).split("\t")
      @ip_address = vm[17] # public ip
      @hostname = vm[3] # ec2 hostname
    end

    def get_last_instance_id
      # TODO When these commands are replaced with AWS-SDK we won't need this.
      # When we create an instance the "AWS way" it returns a hash with all of the variables we care about
      command = 'ec2-describe-instances | grep INSTANCE | tail -n 1'
      vm = self.run(command)
      return vm.split("\t")[1]
    end
  end
end

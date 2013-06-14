module Edurange

  # An EC2 instance.
  # @attr name [String] Returns the name given to this instance.
  # @attr ami_id [String] Returns the ID of the {http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html Amazon Machine Instance (AMI)} associated with this instance.
  # @attr ip_address [String] Returns the IP address given to this instance.
  # @attr key_pair [String] Returns the key pair given to this instance.
  # @attr running [Boolean] Returns true if the instance is currently running.
  # @attr startup_script [String] Returns the startup shell script used by this instance.
  # @attr instance_id [String] Returns the ID of this instance.
  # @attr subnet_id [String] Returns the ID of the subnet associated with this instance.
  class Instance
    attr_reader :name, :ami_id, :ip_address, :startup_script

    # Constructs an EC2 instance with the specified attributes. The instance is not started until {#startup} is called.
    def initialize(name, ami_id, ip_address, key_pair, startup_script, subnet_id)
      @name = name
      @ami_id = ami_id
      @ip_address = ip_address
      @key_pair = key_pair
      @running = false
      @startup_script = startup_script
      @instance_id = nil
      @subnet_id = subnet_id
    end

    # Spins up (starts) this instance by retrieving the appropriate subnet and creating the instance within that subnet. The instance is created with its {#ip_address IP address}, if one is specified.
    def startup
      # Get the subnet this instance should be a part of (does not actually create the subnet)
      subnet = AWS::EC2::Subnet.new @subnet_id

      puts "Spinning up instance at subnet #{@subnet_id} - #{@ip_address}"
      # Actually run the instance
      if @ip_address.nil?
        subnet.instances.create(image_id: @ami_id, key_pair: @key_pair, user_data: @startup_script, subnet: subnet)
      else
        subnet.instances.create(image_id: @ami_id, key_pair: @key_pair, user_data: @startup_script, private_ip_address: @ip_address, subnet: subnet)
      end
    end

    # Converts the instance to string format.
    def to_s
      "<Edurange::Instance name:#{@name} ami_id: #{@ami_id} ip: #{@ip_address} key: #{@key_pair} running: #{@running} instance_id: #{@instance_id}>"
    end


  end
end


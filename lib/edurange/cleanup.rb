require 'aws-sdk'

# Make new ec2 object
ec2 = AWS::EC2.new

# Make new ec2_client client object
ec2_client = AWS::EC2::Client.new

# Initialize arrays
vpc_ids = []

# Make an array of all vpc_ids and dhcp_option_ids
ec2_client.describe_vpcs[:vpc_set].each do |vpc|
  vpc_ids << vpc[:vpc_id]
end

# Heavy lifting using vpc_id to identify each vpc
vpc_ids.each do |vpc_id|
  vpc = AWS::EC2::VPCCollection.new[vpc_id]

  if vpc.instances
    vpc.instances.each do |instance|
      if instance.elastic_ip
        puts "Disassociating Elastic IP for #{instance}"
        instance.disassociate_elastic_ip
        ec2.elastic_ips.each { |ip| ip.delete if !ip.associated? }
      end
      instance.delete
      puts "Deleting instance #{instance}"
    end
  end  

  # Waiting 
  sleeptime = 60
  puts "Waiting #{sleeptime} seconds for instances to terminate"
  sleep(sleeptime)

  if vpc.security_groups
    vpc.security_groups.each do |security_group|
      unless security_group.name == "default"
        puts "Deleting security group #{security_group}"
        security_group.delete
      end
    end
  end

  if vpc.subnets
    vpc.subnets.each do |subnet|
      puts "Deleting subnet #{subnet}"  
      subnet.delete
    end
  end

  if vpc.route_tables
    vpc.route_tables.each do |route_table|
      unless route_table.main?
        puts "Deleting route table #{route_table}"
        route_table.delete
      end
    end
  end

  if vpc.network_interfaces
    vpc.network_interfaces.each do |network_interface|
      puts "Deleting network interface #{network_interface}"
      network_interface.delete
    end
  end

  if vpc.internet_gateway
    puts "Deleting internet gateway #{vpc.internet_gateway.internet_gateway_id}"
    vpc.internet_gateway.detach(vpc)
    vpc.internet_gateway.delete
  end

  if vpc.network_acls
    vpc.network_acls.each do |network_acl|
      unless network_acl.default?
        puts "Deleting network acl #{network_acl}"
        network_acl.delete
      end
    end
  end
  if vpc
    puts "Deleting VPC #{vpc}"
    vpc.delete
  end
end

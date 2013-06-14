module Edurange
  # Assists in the creation of the EC2 environment by handling the creation of users and the configuration of the instances via shell scripts.
  class Helper

    # Opens the user shell script which contains shell commands and some Puppet configuration. This is currently hardcoded as 'my-user-script.sh'.
    def self.startup_script
      File.open('my-user-script.sh', 'rb').read # If this changes, change the documentation above.
    end

    # Creates bash lines to create user accounts and create the relevant password files and/or passwords
    # @param users [String] the list of users to be added and configured via bash.
    def self.users_to_bash(users)
      puts "Got users in users to bash:"
      p users
      shell = ""
      users.each do |user|
        if user['password']
          shell += "\n"
          shell += "sudo useradd -m #{user['login']} -s /bin/bash\n"
          # Regex for alphanum only in password input
          shell += "echo #{user['login']}:#{user['password'].gsub(/[^a-zA-Z0-9]/, "")} | chpasswd\n" 
      # TODO - do something
        elsif user['pass_file']
          name = user['login']
          stuff = <<stuff
useradd -m #{name} -g admin -s /bin/bash
echo "#{name}:password" | chpasswd
mkdir -p /home/#{name}/.ssh

key='#{user['pass_file'].chomp}'
gen_pub='#{user["generated_pub"]}'
gen_priv='#{user["generated_priv"]}'

echo $gen_pub >> /home/#{name}/.ssh/authorized_keys
echo $gen_priv >> /home/#{name}/.ssh/id_rsa
echo $gen_pub >> /home/#{name}/.ssh/id_rsa.pub
chmod 600 /home/#{name}/.ssh/id_rsa
chmod 600 /home/#{name}/.ssh/authorized_keys
chmod 600 /home/#{name}/.ssh/id_rsa.pub
chown -R #{name} /home/#{name}/.ssh
stuff
          shell += stuff
        end
      end
      shell
    end
    # Prepares the {http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html Network Address Translation (NAT) instance}, which provides the private subnet with relevant (but not unlimited) internet access.
    # @param players [String] the list of players to be added to the NAT instance. An RSA key is generated for each player for SSH access.
    def self.prep_nat_instance(players)
      data = <<data
#!/bin/sh
set -e
set -x
echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt
curl http://ccdc.boesen.me/edurange.txt > /etc/motd
data

  # For each player, generate a new RSA key, add the user (adduser), and enable the user's RSA key for SSH use
  players.each do |player|
    # Generate an RSA key
    `rm id_rsa id_rsa.pub`
    `ssh-keygen -t rsa -f id_rsa -q -N ''`
    priv_key = File.open('id_rsa', 'rb').read
    pub_key = File.open('id_rsa.pub', 'rb').read

    # Save these keys
    player["generated_pub"] = pub_key
    player["generated_priv"] = pub_key # Probably a mistake -- ask Stefan

    # Add each user and grant them the RSA keys for SSH use
    data += <<data
adduser -m #{player["login"]}
mkdir -p /home/#{player["login"]}/.ssh
echo '#{player["pass_file"]}' >> /home/#{player["login"]}/.ssh/authorized_keys
echo '#{priv_key}' >> /home/#{player["login"]}/.ssh/id_rsa
echo '#{pub_key}' >> /home/#{player["login"]}/.ssh/id_rsa.pub
chmod 600 /home/#{player["login"]}/.ssh/id_rsa
chmod 600 /home/#{player["login"]}/.ssh/authorized_keys
chmod 600 /home/#{player["login"]}/.ssh/id_rsa.pub
chown -R #{player["login"]} /home/#{player["login"]}/.ssh
data
      end
      data
    end

  end
end


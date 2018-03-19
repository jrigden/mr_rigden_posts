# Setting Up a Basic Server with Ubuntu 16.04
![enter image description here](http://static.jasonrigden.com/img/misc/pexels-photo-51415.jpeg)

*This guide serves as the template for all my servers running Ubuntu 16.4. The default server installation needs additional configuration before being considered appropriate to use in production. Although it is popular to use automation tools nowadays, this guide does not. We will do everything by hand. This will be an artisanal server.*

## Prerequisites

This guide assumes that you this will be a remote server. This server should already have Ubuntu Server 16.04. This server needs to have an SSH server and  you need have root access.

We will be using `REMOTE_SERVER_IP` as placeholder for the IP address of the remote server. We `USER_NAME` as the placeholder for your serves user name.

## Remote Login

From your local computer connect to the remote server with ssh.

    ssh  root@REMOTE_SERVER_IP

## Update the Server

Update the software repositories.

    apt-get update

Install updated software

    apt-get upgrade

## Nano
Unless you have confidence with another terminal editor, you should use `nano`.  If nano is not already installed, you can install it easily. 

    apt-get install nano

## Create a User

Running as `root` is discouraged. Instead we will create a new user with `sudo` privileges.

    adduser USER_NAME

You will be asked to set the new user's password then a few other questions that can be left blank.

Now give this user sudo privileges. 

    usermod -aG sudo USER_NAME

## Generate SSH Keys
**If you already have SSH keys ready, skip this section.** 
On your **local machine** generate your pair of SSH keys. 

    ssh-keygen

You will be asked several questsion. Accept the default file location for the key. Answer the others as you wish. 

_Note: If you leave the passphrase blank, then your system will be less secure. Possession of the keys will be enough to gain access. Convenience is often the enemy of security._

## Copy the Public Key

On your **local machine** copy your public SSH key to the remote server. 

    ssh-copy-id USER_NAME@REMOTE_SERVER_IP

*Remember to use the password for the new user.*

After the key has been successfully copied, log into the remote server as `USER_NAME`.

    ssh USER_NAME@REMOTE_SERVER_IP

## Harden SSH
We are going to reconfigure our SSH server by editing `sshd_config`.

    sudo nano /etc/ssh/sshd_config

Check and make sure that public key authentication is enabled. Find the line that starts `PubkeyAuthentication`. Make sure it is set you `yes`.

    PubkeyAuthentication yes

We want to disable password authentication. Find the line that starts `PasswordAuthentication`. Set this to `no`.

    PasswordAuthentication no

We do not want root to be able to log in remotely. Find the line that starts `PermitRootLogin`. Set this to `no`

    PermitRootLogin no

Reload the SSH server. This may cause you to lose your SSH connection.

    sudo service ssh restart

If you would like a more info about securing SSH, please read my post  [Hardening SSH
](https://medium.com/p/hardening-ssh-1bcb99cd4cef). 

## Fail2Ban

Fail2Ban is great an intrusion prevention tool. It can watch the logs and temporarily IP address based on suspicions activity. We want fail2ban to watch our SSH logs. If an IP makes to many bad requests we will temporarily ban them. 

    sudo apt-get install fail2ban

Copy the configuration files.
 

    sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

Edit the `jail.local` and enable monitoring of SSH.

    sudo nano /etc/fail2ban/jail.local

Find the [ssh] section. Change enable to true.

    [ssh]
    
    enabled  = true
    port     = ssh
    filter   = sshd
    logpath  = /var/log/auth.log
    maxretry = 6 

Then restart the service.

    sudo systemctl restart fal2ban

## The Firewall

Install the Uncomplicated Firewall(UFW).

    sudo apt-get install ufw

Your firewall configuration will change as you add server programs. This guide only cares about the SSH server. 

    sudo ufw allow ssh

Then enable the firewall.

    sudo ufw enable

If you would like a more detailed guide to UFW check out my post, [A Guide to the Uncomplicated Firewall (UFW) for Linux](https://medium.com/@mr_rigden/a-guide-to-the-uncomplicated-firewall-ufw-for-linux-570c3774d7f4)

## Name Your Server
Generic server names can be confusing. In this guide we will name our server `seattle`. Let's change the hostname.

`sudo nano /etc/hostname`

Change it to `seattle`. Now edit the hosts files.
 `sudo nano /etc/hosts`

    127.0.0.1       localhost    
    # The following lines are desirable for IPv6 capable hosts
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters

And add you server name like so.

    127.0.0.1       localhost
    127.0.1.1       seattle
    
    # The following lines are desirable for IPv6 capable hosts
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters

Now reboot.

    sudo reboot

## Time
Set you sever on an appropriate timezone. For me that is Pacific time.

    sudo timedatectl set-timezone America/Los_Angeles

Then make sure the server is using the Network Time Protocol.

    sudo timedatectl set-ntp on

## Conclusion
If have followed this guide you will have a basic server that is just a bit more secure. 

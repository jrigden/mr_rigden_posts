
 ![](http://static.jasonrigden.com/img/hard_ssh/header.jpeg)

Keep your servers safe with a few extra steps. SSH is essential to server management. 

This post will walk you though some of the options available to harden OpenSSH. The instructions may work for other flavors of Linux but has been tested only on Ubuntu 16.04 LTS.

***Warning**: Messing with how SSH works can be dangerous. You can very easily lock yourself out of the server. Be careful.*

# OpenSSH Server Configuration

The settings file for OpenSSH on Ubuntu 16.04 is located at `/etc/ssh/sshd_config`. You will need to be `root` or use `sudo` to edit and control the SSH server.

## Backup Configuration File

It's always a good idea to make a backup of any configuration files before editing them.

    cp /etc/ssh/sshd_config /etc/ssh/backup.sshd_config

## Editing the Configuration File

I'm not fancy so, I use `nano` for configuration file edits.

    nano /etc/ssh/sshd_config

## SSH Configuration Test

After editing the configuration file you should test that it is valid before reloading the service.

    sshd -t

## Reload the Configuration File

Once you think your edits are good, reload the SSH daemon.

    sudo systemctl reload sshd

## Check the Protocol

Our very first edit will be very simple. It is really more of a double check than an edit. Open `/etc/ssh/sshd_config` and check the line that starts with Protocol. Make sure it is set to 2 and not 1. The current default is 2.

    Protocol 2

## Disable Root

Instead of using `root`, we should be using connecting as user with `sudo` permission. Make sure you have `sudo` setup properly before continuing. So let’s disable the ability of root to login using SSH. Inside the configuration file find the line:

    PermitRootLogin yes

Change that to no:

    PermitRootLogin no

## Disconnect Idle Sessions

Idle sessions can be dangerous. It is a good idea to log people out after a set amount of inactivity. The `ClientAliveInterval` is the amount of time in seconds before the server will send an alive message to the client after no data has been received. `ClientAliveCountMax` is the number of times it will check before disconnecting. In the example below, the server will check on the client after 5 minutes of inactivity. It will do this twice then disconnect.

    ClientAliveInterval 300
    ClientAliveCountMax 2

## Whitelist Users

We can limit the users that are allowed to log in SSH. This is a whitelist. Only users in this list will be allowed. **Everyone else will be denied.** Let’s say that I want to allow user `norton` to log in remotely through SSH. We will add the line:

    AllowUsers norton

Don’t forget to add your username to the `AllowUser` list.

## Change Ports

My second least favorite way of hardening SSH is changing the default port. Normally SSH runs on port 22. The idea is that most script kiddies are only going to target that port. If you change you default port, maybe your attacks will decrease. I don’t do this or recommend it. But, maybe you disagree. In the configuration file find the line:

    Port 22

Then change it to another available like maybe 2222.

    Port 2222

## SSH Keys

By default you log into the system through SSH with a username and a password. These can be brute forced. People will try an enormous amount of username and password combinations until they find one works. So, instead of using passwords we should use SSH keys.

## Generating a Key Pair

*If you already have a key pair, skip ahead.*
We are going to make some public key encryption keys. They come in pairs. Private and public. If you are not familiar with this system of encryption, than check out my video, [A Very Brief Introduction to Public-key Cryptography](https://youtu.be/Zcptr4BlpuQ). 

Run the following command to generate your keys on the **client machine**. Do not run this command with `sudo`. It will ask you for a passphrase to protect the key. You can keep this blank but I do not recommend that. A private SSH key with no passphrase protection can be used by anyone with possession of that key to access the server.

    ssh-keygen

## Share Your Public Key

Use ssh-copy-id to send you public key to the server.

    ssh-copy-id jason@192.168.1.1

Now try logging in. You may be asked for your passphrase.

    ssh jason@192.168.1.1

You should get a message back that looks similar too:

    The authenticity of host '192.168.1.1 (192.168.1.1)' can't be established.
    ECDSA key fingerprint is ff:fd:d5:f9:66:fe:73:84:e1:56:cf:d6:ff:ff.
    Are you sure you want to continue connecting (yes/no)?

Say yes and you should be logged in without a password.

## Disable Password Authentication

If we have SSH keys working we can just disable all password authentication. Find the line:

    PasswordAuthentication yes

And change that to no.

    PasswordAuthentication no

## Disable X11Forwarding

This guide is intended for use with remote servers. Generally speaking, there is no reason to use a GUI for a remote server. So disable X11 forwarding. Find the line:

    X11Forwarding yes

and change that to no.

    X11Forwarding no

## Fail2Ban

This is a great program that can scan logs and ban temporarily ban IPs based on possible malicious activity. You will need to install Fail2ban.

    apt-get install fail2ban

Once installed, we copy the fail2ban configuration file.

    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

Open the `/etc/fail2ban/jail.local` files and find the spot that starts `[sshd]`. Edit it like so, adding `enabled = true`:

    [sshd]
    enabled  = true
    port    = ssh
    logpath = %(sshd_log)s

Then restart fail2ban

    service fail2ban restart

Fail2ban will monitor your SSH logs for possible malicious activity and then temporarily ban the source IP.

## Multi-Factor Authentication

We can also user TOTP (Time-Based One-Time Passwords) to harden our SSH security. In this example we will be using [Google Authenticator](https://en.wikipedia.org/wiki/Google_Authenticator). When we attempt to log into the system we will be challenged to provide a verification code. We will use the Google Authenticator app to generate that code. First we need to install some software.

    sudo apt-get install libpam-google-authenticator

Then run the initialization

    google-authenticator

It will ask: `Do you want authentication tokens to be time-based (y/n)` and we need to say yes. Then it will print out the QR code and ask if want to update our `.google_authenticator` file. We do.
 ![Don’t worry this code was never used and the server no longer exists.](http://static.jasonrigden.com/img/hard_ssh/qr.png)

***Don’t worry this code was never used and the server no longer exists.***

Scan that code into the Google Authenticator app and **save those emergency codes**! You will next be asked a few more question. We will answer them all with yes.

    Do you want to disallow multiple uses of the same authentication token? This restricts you to one login about every 30s, but it increases your chances to notice or even prevent man-in-the-middle attacks (y/n) y
    
    By default, tokens are good for 30 seconds and in order to compensate for possible time-skew between the client and the server, we allow an extra token before and after the current time. If you experience problems with poor time synchronization, you can increase the window from its default size of 1:30min to about 4min. Do you want to do so (y/n) y

    If the computer that you are logging into isn't hardened against brute-force login attempts, you can enable rate-limiting for the authentication module. By default, this limits attackers to no more than 3 login attempts every 30s. Do you want to enable rate-limiting (y/n) y)

Edit the PAM rule file `/etc/pam.d/sshdadding` the follow at the end:

    auth required pam_google_authenticator.so

Edit the ssh configuration file.

    UsePAM yes
    
    ChallengeResponseAuthentication yes

And restart the SSH server. The system will now require a verification code when you log into the server.

## Banners and MOTD

My least favorite way of hardening SSH is adding legal mumbo jumbo to the ssh banner and MOTD. Usually some redundant statement saying “unauthorized access is prohibited”. This is security theater. The advice is usually given by the same armchair lawyers who add “confidentiality notices” at the end of emails. If an actual US lawyer says that you need this to be protected by the [CFAA](https://en.wikipedia.org/wiki/Computer_Fraud_and_Abuse_Act), you need a new lawyer. I think this myth originated from a poor understanding of the [UK’s Computer Misuse Act 1990](https://en.wikipedia.org/wiki/Computer_Misuse_Act_1990.) and basic legal jurisdiction. *Also if you ask an undercover cop if they are a cop, they don’t have to say yes.*

## Banner

Often people will talk about the banner leaking system info. They will leave out the fact that the Banner is disabled by default in Ubuntu 16.04. Let us enable it to see what happens. This banner is sent out before authentication. Everyone attempting to connect through SSH will see this banner. You may need to enable PasswordAuthentication to see the banner.
Edit the SSH configuration file then find and uncomment:

    #Banner /etc/issue.net

Now try to connect to the server with a fake user:

    ssh fake_user@192.168.1.1

We receive back.

    Ubuntu 16.04.3 LTS
    fake_user@192.168.1.1’s password:

As you can see the system has announced some system info.

We can edit this message by editing `/etc/issue.net`. I am going to add a little ascii art bunny to welcome my “guests”.

    ______________________
    |                    |
    | Welcome Leet Haxor |
    |____________________|
           ||
    (\_/)  ||
    ( *,*) ||
    (")_(")

Now try to connect to the server with a fake user:
ssh fake_user@192.168.1.1
And get the banner message greeting:

    ______________________
    |                    |
    | Welcome Leet Haxor |
    |____________________|
           ||
    (\_/)  ||
    ( *,*) ||
    (")_(")
    fake_user@192.168.1.1's password:

Those hacker now will think twice before messing with us.

## MOTD

After logging in users are show the message of the day (MOTD). It will look something like this:

    Welcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.13.17-x86_64-linode69 x86_64)
    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/advantage
    Last login: Mon Feb 19 16:01:33 2018 from 192.168.1.1

Ubuntu 16.04 uses a dynamic MOTD. We will just be editing the header of the message. Before we change the anything, let’s make a backup of that original header.

    cp /etc/update-motd.d/00-header /etc/update-motd.d/backup.00-header

Open `/etc/update-motd.d/00-header` add the following to the end of the file:

    figlet "No Trespassing"

Now when we connect we get:

    Welcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.14.17-x86_64-linode99 x86_64)
    _   _         _____                                  _             
    | \ | | ___   |_   _| __ ___  ___ _ __   __ _ ___ ___(_)_ __   __ _ 
    |  \| |/ _ \    | || '__/ _ \/ __| '_ \ / _` / __/ __| | '_ \ / _` |
    | |\  | (_) |   | || | |  __/\__ \ |_) | (_| \__ \__ \ | | | | (_| |
    |_| \_|\___/    |_||_|  \___||___/ .__/ \__,_|___/___/_|_| |_|\__, |
                                     |_|                          |___/
    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/advantage

*Now we are in compliance with the laws of make believe.*

## SSH Audit

So far we have been covering the basics. Now we move into some more advanced SSH hardening. [SSH Audit](https://github.com/arthepsy/ssh-audit) is a Python script that will scan your SSH server for some security issues. Download it and run it like any other python script, just point it at your target SSH server.

    python ssh-audit.py labs.seattlebot.net

Then we get a rather large report.

 ![](http://static.jasonrigden.com/img/hard_ssh/report1.png)

This report gives us a peek behind the SSH curtain. This is a report on the ciphers and algorithms used by your SSH server to secure communications with the client. If you have done work with OpenSSL some things might look familiar. As you may have learned using OpenSSL, not all ciphers and algorithms are equal. Some are strong and some are weak. Eliminating the weak ones can help harden your system.

## HeadingChange Hostkey Preference

We will be following the advice of [stribika](https://stribika.github.io/2015/01/04/secure-secure-shell.html), [mozilla](https://infosec.mozilla.org/guidelines/openssh), and the SSH audit report. We will change our HostKey preferences. Remove the current HosyKey entries in the ssh configuration file. Replace them with the following.

    HostKey /etc/ssh/ssh_host_ed25519_key
    HostKey /etc/ssh/ssh_host_rsa_key

## HeadingChange Default Ciphers and Algorithms
Continuing to follow the advice of stribika, mozilla, and the SSH audit report. We change our Key exchange algorithms, symmetric ciphers and, message authentication codes. Add or replace the following to the ssh configuration file.

    KexAlgorithms curve25519-sha256@libssh.org
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

## Rerun the Audit

Let us see if our changes made the SSH audit happy.

    python ssh-audit.py 173.255.250.98

![](http://static.jasonrigden.com/img/hard_ssh/report2.png)
 
Green is good. That is looking better.

## Regenerate Moduli

The `/etc/ssh/moduli` file contains prime numbers and generators used by the SSH server for the Diffie-Hellman key exchange. Your current `/etc/ssh/moduli` is probably not unique. Generating a new file may harden your server. Generating these file might take awhile.

    ssh-keygen -G moduli-2048.candidates -b 2048
    ssh-keygen -T moduli-2048 -f moduli-2048.candidates
    cp moduli-2048 /etc/ssh/moduli
    rm moduli-2048

## Conclusion

Hopefully you have found this useful and your server will now be just a bit more hard to break into now. There is much more to learn about OpenSSH. Good Luck.

# Credits
Let's start with where credit is due. This project combines several open source projects
to create a powerful router.

Project Name | Project Website | Project Git Repo | Project Function
--- | --- | --- | ---
Pi-hole | https://pi-hole.net | https://github.com/pi-hole/pi-hole | DNS + DHCP + Adblocker
Firehol | http://firehol.org | https://github.com/firehol/firehol | Firewall
Salt | https://saltstack.com | https://github.com/saltstack/salt | Configuration Management

# Configuration
### [pillar/settings.sls](pillar/settings.sls)
This is a one-stop shop for all necessary configuration settings.
> *NOTE:* To see where configuration files live on the operating system, see [Filesystem Architecture](https://github.com/Fauxsys/Erratum/wiki/Filesystem-Architecture).

### [anaconda-ks.cfg](anaconda-ks.cfg)
This is an example kickstart configuration file. The `router` user account
will be created with the password `this_is_only_an_example_password_please_change_me`. The password can be changed on [line 25](anaconda-ks.cfg#L25).
If you generate your own kickstart file, copy [lines 49-67](anaconda-ks.cfg#L49-L67) 
to ensure the Erratum repository files are placed in their appropriate directories. This will also install the Salt Master and Salt Minion which are required to deploy the codebase.


### [states/files/authorized_keys](states/files/authorized_keys)
Add SSH public keys to this file to grant SSH access into the server. Each key should be separated by a newline.

# Installation
### [unattended.sh](unattended.sh)
This will take an existing [`anaconda-ks.cfg`](anaconda-ks.cfg) and create a
CentOS 7 ISO capable of unattended install. The newly generated ISO named will be placed
in the repository directory. This script is tested on Mac & Linux and requires sudo privileges.

Linux Dependencies | Mac Dependencies (installed via [homebrew](https://brew.sh/))
--- | ---
wget | wget
rsync | rsync
xorriso | xorriso
sed  | gnu-sed


# Post-Install
On the newly installed system, run `salt-call state.apply router` and the router will build itself based on the specified
configurations. Upon successful completion, the following URLs will be available:

URL | Description |
--- | --- |
| http://IP-ADDRESS/admin/ | Pi-hole dashboard |
| http://IP-ADDRESS:19999 | Netdata dashboard |
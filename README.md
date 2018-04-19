# Credits
Let's start with where credit is due. This project combines several open source projects
to create a minimalistic router.

Project Name | Project Website | Project Github | Project Function
--- | --- | --- | ---
Pi-hole | https://pi-hole.net | https://github.com/pi-hole/pi-hole | DNS + DHCP + Adblocker
Firehol | http://firehol.org | https://github.com/firehol/firehol | Firewall
Salt | https://saltstack.com/ | https://github.com/saltstack/salt | Configuration Management

# Configuration
### [anaconda-ks.cfg](anaconda-ks.cfg)
This is an example kickstart configuration file. The `root` and `linuxuser` accounts
will be created with the password `password`. This can be changed in their appropriate fields.
If you generate your own kickstart file, be sure to copy [lines 49-72](anaconda-ks.cfg#L49-L71) 
to ensure the erratum repository files are placed in their appropriate directories.


### [errata/files/authorized_keys](errata/files/authorized_keys)
Each public key should be separated by a newline.

### [errata/files/firehol.conf](errata/files/firehol.conf)
This is the Firehol configuration file. Change interface names and IP addresses to match your environment.

* internal_servers: These are the protocols your router will serve to your LAN
* internal_clients: These are the protocols your router will request from the WAN
> **NOTE:** `ens33` is connected to the WAN and `ens34` is connected to the LAN

### [errata/files/setupVars.conf](errata/files/setupVars.conf)
This is the Pi-hole configuration file. Change DHCP, DNS, and interface name settings to match your environment.
> **NOTE:** WEBPASSWORD is the SHA256 hash of "password".
This can be changed after installation by running `pihole -a -p "insert new password here"`.

>Additionally, if any changes are manually made to setupVars.conf after installation, run `pihole -r`
and select `Repair (This will retain existing settings)` for the changes to take effect.

### [errata/router/setup.sls](errata/router/setup.sls)
Change all instances of `linuxuser` to your desired username.

Pay particular attention to the `modify_wan_dns` and `apply_wan_dns` states.
These `nmcli` commands should target your WAN interface but the use case may not be relevant to your environment.

# Installation
### [unattended.sh](unattended.sh)
This will take an existing [`anaconda-ks.cfg`](anaconda-ks.cfg) located in the repository directory and transform it into a
CentOS 7 ISO capable of unattended install. The newly generated ISO named `centos-7-custom.iso` will be placed
in the same directory. This script is tested on Mac & Linux and requires sudo privileges.

Linux Dependencies | Mac Dependencies (installed via [homebrew](https://brew.sh/))
--- | ---
wget | wget
rsync | rsync
xorriso | xorriso
sed  | gsed


# Post-Install
On the newly installed system, run `salt-call state.apply router` and the router will build itself based on the
configurations above. Once completed, the following URLs will be available for Pi-hole and Netdata respectively:

* http://IP-ADDRESS/admin/
* http://IP-ADDRESS:19999

# Future Features 
* [ ] VLAN Support
* [ ] DNSCrypt Support
* [ ] VPN Support
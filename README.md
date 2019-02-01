# Credits
Let's start with where credit is due. This project combines several open source projects
to create a powerful router.

Project Name | Project Website | Project Git Repo | Project Function
--- | --- | --- | ---
Pi-hole | https://pi-hole.net | https://github.com/pi-hole/pi-hole | DNS + DHCP + Adblocker
Firehol | http://firehol.org | https://github.com/firehol/firehol | Firewall
Salt | https://saltstack.com | https://github.com/saltstack/salt | Configuration Management
WireGuard | https://wireguard.io | https://git.zx2c4.com/WireGuard | VPN
ROCK NSM | https://rocknsm.io | https://github.com/rocknsm/rock | Network Security Monitor

# Configuration
### [errata/pillar/settings.sls](errata/pillar/settings.sls)
This is a one-stop shop for all necessary configuration settings.

### [anaconda-ks.cfg](anaconda-ks.cfg)
This is an example kickstart configuration file. The `router` user account
will be created with the password `password`. This can be changed on [line 25](anaconda-ks.cfg#L25).
If you generate your own kickstart file, copy [lines 49-67](anaconda-ks.cfg#L49-L67) 
to ensure the Erratum repository files are placed in their appropriate directories.


### [errata/files/authorized_keys](errata/files/authorized_keys)
Each public key should be separated by a newline.

### [errata/files/firehol.conf](errata/files/firehol.conf)
This is the Firehol configuration file. 

* internal_servers: These are the protocols your router will serve to your LAN
* internal_clients: These are the protocols your router will request from the WAN

### [errata/files/setupVars.conf](errata/files/setupVars.conf)
This is the Pi-hole configuration file.

> **NOTE:** If any changes are manually made to setupVars.conf after installation, run `pihole -r`
and select `Repair (This will retain existing settings)` for the changes to take effect.

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
configurations above. Once completed, the following URLs will be available for Pi-hole, Netdata, Kibana, and Docket respectfully:

* http://IP-ADDRESS/admin/ - Pi-hole dashboard
* http://IP-ADDRESS:19999  - Netdata dashboard

If you chose to build your ISO with ROCK NSM, these additional URLs will be available:
* https://localhost - Kibana web interface - After deploy, the created creds are in the home directory of the user created upon install as KIBANA_CREDS.README
* https://localhost:8443 - Docket - (If enabled) The web interface for pulling PCAP from the sensor

> localhost = IP of the management interface of the box

# Future Features 
* [ ] VLAN Support
* [ ] DNSCrypt Support
* [ ] VPN Support

# Hardware Requirements
- 5 MB x 12 hours x 100 Mbps = 6 GB per day.
- 6 GB x 7 days a week = 42 GB per week.
- 42 x 4 weeks a month = 164 GB per month.
- https://guide.sunnyvalley.io/sensei/getting-started/getting-ready
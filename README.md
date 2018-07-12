# minecraft-dnsrotator
Minecraft TXT TCP rotator.
This script will check one domain and, if _minecraft._tcp.DOMAIN is blocked, it will change that SRV content.

# Language:
Shell script

# Operate systems:
*nix systems.

# Features:
- Change Dns TXT records on cloudflare
- Verify if subdomain is blocked

# What we not support yet
- Multiple _minecraft._tcp.DOMAIN records
- Multiple domains as parameters of this script

# Features that we want ASAP
- no-ip / DDNS integration to create and remove subdomains automatically

# Software requirements:

Ubuntu and Debian based systems:

```bash
apt update
apt -y install jq
```

Centos and Redhat based systems:

```bash
yum install epel-release
yum install jq
```

# How to use

1. Clone this git.

```bash
git clone https://github.com/franciscopaniskaseker/minecraft-dnsrotator.git
# or
git clone git@github.com:franciscopaniskaseker/minecraft-dnsrotator.git
```

2. Install, as root, this script.

```bash
cd minecraft-dnsrotator
bash install.sh
```
3. Edit "/etc/minecraftdnsrotator/conf/credentials-cloudflare.conf" and insert your Cloudflare credentials. "#" is only used to comment lines. Do not write any spaces.

```bash
# add credentials (auth key), e-mail (auth) and domains separated with semicolon without spaces
# example:
# 09je0923j9032je90dadsadasdasadasdds32je90;admin@domain.com;domain.com
```

4. Edit "/etc/minecraftdnsrotator/conf/domains-unused.conf" and insert domains that will be used in the future. "#" is only used to comment lines. Do not write any spaces.
```bash
# add unused subdomains and set which domain will be used separated with semicolon without spaces
# example:
# 12345.ddns.net;mc.domain.com
# 67890.ddns.net;mc.domain.com
# 13579.ddns.net;play.domain.com
# 24680.ddns.net;play.domain.com
```
5. Type "minecraft-dnsrotator.sh domain.com" to execute block check and eventually SRV record update.


# How to update your Minecraft DNS Rotator script

1. Update your git
2. bash update.sh

# Do you need any help with Minecraft Server Linux Sysadmin? DDoS attacks? Backups? We can talk ;)
1. mail apterix at gmail dot com
2. skype apterix

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

TODO

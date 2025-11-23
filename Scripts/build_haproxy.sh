#!/bin/bash

SUSEConnect --product sle-module-basesystem/15.7/x86_64
SUSEConnect --product sle-module-server-applications/15.7/x86_64
SUSEConnect --product sle-ha/15.7/x86_64 -r (add reg code for HA Extension)

cat << EOF >> /etc/sysconfig/network/ifcfg-eth0
IPADDR='10.10.12.202/22'
GATEWAY='10.10.12.1'
EOF
sed -i -e 's/dhcp4/static/g' /etc/sysconfig/network/ifcfg-eth0
echo "default 10.10.12.1 - eth0" > /etc/sysconfig/network/ifroute-eth0

cp /etc/sysconfig/network/config /etc/sysconfig/network/config.orig
sed -i -e 's/NETCONFIG_DNS_STATIC_SEARCHLIST=""/NETCONFIG_DNS_STATIC_SEARCHLIST="kubernerdes.lab"/g' /etc/sysconfig/network/config
sed -i -e 's/NETCONFIG_DNS_STATIC_SERVERS=""/NETCONFIG_DNS_STATIC_SERVERS="10.10.12.8 10.10.12.9 8.8.8.8"/g' /etc/sysconfig/network/config
sed -i -e 's/NETCONFIG_NTP_STATIC_SERVERS=""/NETCONFIG_NTP_STATIC_SERVERS="0.pool.suse.ntp.org 1.pool.suse.ntp.org 2.pool.suse.ntp.org"/g' /etc/sysconfig/network/config
sdiff /etc/sysconfig/network/config.orig /etc/sysconfig/network/config


# using Keepalived for floating/VIP (and to future proof)
zypper -n in haproxy keepalived

# Allow keepalive to attach before interface is up/available
echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee -a /etc/sysctl.d/20_keepalive.conf

cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER           # On backup servers, set to BACKUP
    interface eth0         # Change to your network interface
    virtual_router_id 100  # Must be unique per VIP
    priority 101           # Higher on master, lower on backup
    authentication {
        auth_type PASS
        auth_pass yourpassword
    }
    virtual_ipaddress {
        10.10.12.120/22   # Your VIP and subnet
    }
}
EOF

sudo systemctl enable keepalived --now
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.$(uuidgen | tr -d '-' | head -c 6)
curl -o /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/jradtke-suse/rancher.kubernerdes.lab/refs/heads/main/Files/etc_haproxy_haproxy.cfg
curl -o /etc/sysctl.d/10-haproxy.cfg https://raw.githubusercontent.com/jradtke-suse/rancher.kubernerdes.lab/refs/heads/main/Files/etc_sysctl.d_10-haproxy.conf
sudo systemctl enable haproxy --now


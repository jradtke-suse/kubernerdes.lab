#!/bin/bash

SUSEConnect -e <reg_email> -r <reg_code>
SUSEConnect --product sle-module-basesystem/15.7/x86_64
SUSEConnect --product sle-module-server-applications/15.7/x86_64
SUSEConnect --product sle-ha/15.7/x86_64 -r (add reg code for HA Extension)

# Task: configure static IP address
case $(uname -n) in 
  harvester-dc-lb) IPADDR='10.10.12.92/22';;
  harvester-dc-edge) IPADDR='10.10.12.92/22';;
esac

cat << EOF >> /etc/sysconfig/network/ifcfg-eth0
IPADDR=$IPADDR
GATEWAY='10.10.12.1'
EOF
sed -i -e 's/dhcp4/static/g' /etc/sysconfig/network/ifcfg-eth0
echo "default 10.10.12.1 - eth0" > /etc/sysconfig/network/ifroute-eth0

# Task: configure DNS and NTP settings
cp /etc/sysconfig/network/config /etc/sysconfig/network/config.orig
sed -i -e 's/NETCONFIG_DNS_STATIC_SEARCHLIST=""/NETCONFIG_DNS_STATIC_SEARCHLIST="kubernerdes.lab"/g' /etc/sysconfig/network/config
sed -i -e 's/NETCONFIG_DNS_STATIC_SERVERS=""/NETCONFIG_DNS_STATIC_SERVERS="10.10.12.8 10.10.12.9 8.8.8.8"/g' /etc/sysconfig/network/config
sed -i -e 's/NETCONFIG_NTP_STATIC_SERVERS=""/NETCONFIG_NTP_STATIC_SERVERS="0.pool.suse.ntp.org 1.pool.suse.ntp.org 2.pool.suse.ntp.org"/g' /etc/sysconfig/network/config
sdiff /etc/sysconfig/network/config.orig /etc/sysconfig/network/config

# using Keepalived for floating/VIP (and to future proof)
zypper -n in haproxy keepalived

# Allow keepalive to attach before interface is up/available
echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee -a /etc/sysctl.d/20_keepalive.conf
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.orig
curl -o  /etc/keepalived/keepalived.conf https://raw.githubusercontent.com/jradtke-suse/kubernerdes.lab/refs/heads/main/Files/etc_keepalived_keepalived-$(uname -n).conf 


sudo systemctl enable keepalived --now
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.$(uuidgen | tr -d '-' | head -c 6)
curl -o /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/jradtke-suse/rancher.kubernerdes.lab/refs/heads/main/Files/etc_haproxy_haproxy.cfg
curl -o /etc/sysctl.d/10-haproxy.cfg https://raw.githubusercontent.com/jradtke-suse/rancher.kubernerdes.lab/refs/heads/main/Files/etc_sysctl.d_10-haproxy.conf
sudo systemctl enable haproxy --now


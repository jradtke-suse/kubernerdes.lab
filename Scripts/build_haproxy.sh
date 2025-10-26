#!/bin/bash

SUSEConnect --product sle-module-basesystem/15.7/x86_64
SUSEConnect --product sle-module-server-applications/15.7/x86_64
SUSEConnect --product sle-ha/15.7/x86_64 -r (add reg code for HA Extension)


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


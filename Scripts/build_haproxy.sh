

# using Keepalived for floating/VIP (and to future proof)
zypper in haproxy keepalived

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

sudo systemctl enable keepalived
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.$(uuidgen | tr -d '-' | head -c 6)"
curl -O /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/jradtke-suse/rancher.kubernerdes.lab/refs/heads/main/Files/etc_haproxy_haproxy.cfg

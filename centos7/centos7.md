# Install and Configure OpenContrail 2.0 on CentOS 7

This installation of OpenContrail is based on CentOS 7.0.1406 host installed from `CentOS-7.0-1406-x86_64-Minimal.iso`.
```
Linux vm201 3.10.0-123.el7.x86_64 #1 SMP Mon Jun 30 12:09:22 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
CentOS Linux release 7.0.1406 (Core) 
```

## 1 Pre-installation
The following prerequisites are required before installing OpenContrail.
* Configure network interface.
* Update `/etc/hostname` with the hostname.
* Update `/etc/hosts` with the IP address and hostname, so hostname will be resolved properly.
* Update `/etc/sysconfig/selinux` or `/etc/selinux/config` to disable SELinux (for example, to allow haproxy bind on front-end ports).
* Disable firewall.
```
# systemctl stop firewalld
# systemctl disable firewalld
```

## 2 Install OpenContrail
Copy contrail-2.0-22.tgz, local-repo.tgz and utils.tgz to /opt and unpack them.
```
# cd /opt
# tar xzf contrail-2.0-22.tgz
# tar xzf local-repo.tgz
# tar xzf utils.tgz
```
Setup local repository.
```
# cd /opt/utils
# ./local-repo-setup.sh
```
Update parameters in `contrail.params`.
On controller node, run `contrail-setup.sh controller`.
On compute node, run `contrail-setup.sh compute`.
```
# cd /opt/utils
# ./contrail-setup.sh controller
# ./contrail-setup.sh compute
```
After installation completed, reboot.
```
# reboot
```

## 3 Post-provisioning OpenContrail
* Add tenant, control node and compute node into configuration.
```
# cd /opt/utils/opencontrail-config
# ./config add tenant admin
# ./config add bgp-router <controller hostname> --asn <ASN> --vendor <vendor name> --address <controller IP address> --control
# ./config add vrouter <compute node hostname> --address <compute node IP address>
```
Open http://<controller IP>:8080 to access Web UI. Username is "admin". Password is "contrail123".

## 4 Docker
Copy docker.tgz to /opt.
```
# cd /opt
# tar xzf docker.tgz
# tar xzf utils.tgz
# yum localinstall /opt/docker/docker-1.2.0-1.8.el7.centos.x86_64.rpm
# systemctl enable docker
# systemctl start docker
# docker load -i /opt/docker/centos.tar
```

##4 Example
Create virtual networks and network policy.
```
# cd /opt/utils/opencontrail-config/opencontrail_config
# ./config add ipam ipam-default
# ./config add policy policy-default
# ./config add network red --ipam ipam-default --policy policy-default --subnet 192.168.1.0/24
# ./config add network green --ipam ipam-default --policy policy-default --subnet 192.168.2.0/24
```
Create two Docker containers. Use Ctrl-p and Ctrl-q to exit container to keep container running.
```
# docker run -i -t --net="none" centos /bin/sh
# docker run -i -t --net="none" centos /bin/sh
```
Connect containers to virtual networks.
```
# cd /opt/utils/opencontrail-netns/opencontrail_netns
# mkdir -p /var/run/netns
# python docker.py -s <host IP> -n red --project default-domain:admin --start <container ID>
# python docker.py -s <host IP> -n green --project default-domain:admin --start <container ID>
```
To verify connection, attach to a container, check network configuration, then ping another container.



## Build Contrail compute node on RHEL 6.6

* Disable Puppet
`crontab -e` then comment out the line of Puppet.

* Disable SELinux
`sestatus` check the SELinux status.
`setenforce 0` set current mode to permissive.

* Delete the bridge created by libvirt.
```
# virsh net-destroy default
# virsh net-undefine default
```

* Copy the following packages to compute node.
  * contrail_vrouter_packages_rhel66.tgz
  * opencontrail-vrouter-netns.tgz
  * requests-2.5.1.tar.gz
  * unittest2-0.8.0.tar.gz

* Put files in place.
```
# cd /opt
# mkdir contrail
# cd contrail
# mkdir vrouter-repo
# cd vrouter-repo
# tar xzf /path/to/contrail_vrouter_packages_rhel66.tgz
```

* Add repo for vRouter and local EPEL.
/etc/yum.repos/contrail.repo
```
[vrouter-repo]
name=vrouter-repo
baseurl=file:///opt/contrail/vrouter-repo/
enabled=1
priority=1
gpgcheck=0
```
`yum repolist` to check all repos.

* Install packages.
# yum install contrail-setup contrail-utils contrail-vrouter contrail-vrouter-init contrail-vrouter-utils contrail-nodemgr contrail-nova-vif contrail-openstack-vrouter

```
Installed:
  contrail-nodemgr.x86_64 0:2.0-22.el6
  contrail-nova-vif.x86_64 0:2.0-22.el6
  contrail-openstack-vrouter.noarch 0:2.0-22.el6
  contrail-setup.noarch 0:2.0-22.el6
  contrail-utils.x86_64 0:2.0-22.el6
  contrail-vrouter.x86_64 0:2.0-22.el6
  contrail-vrouter-init.x86_64 0:2.0-22.el6
  contrail-vrouter-utils.x86_64 0:2.0-22.el6

Dependency Installed:
  abrt.x86_64 0:2.0.8-26.el6
  abrt-libs.x86_64 0:2.0.8-26.el6
  btparser.x86_64 0:0.17-2.el6
  cloog-ppl.x86_64 0:0.15.7-1.2.el6
  contrail-lib.x86_64 0:2.0-22.el6
  contrail-vrouter-agent.x86_64 0:2.0-22.el6
  cpp.x86_64 0:4.4.7-11.el6
  gcc.x86_64 0:4.4.7-11.el6
  gdb.x86_64 0:7.2-75.el6
  glibc-devel.x86_64 0:2.12-1.149.el6_6.5
  glibc-headers.x86_64 0:2.12-1.149.el6_6.5
  kernel-headers.x86_64 0:2.6.32-504.3.3.el6
  libproxy.x86_64 0:0.3.0-10.el6
  libproxy-bin.x86_64 0:0.3.0-10.el6
  libproxy-python.x86_64 0:0.3.0-10.el6
  librabbitmq.x86_64 0:0.5.2-1.el6
  libreport.x86_64 0:2.0.9-21.el6
  libreport-compat.x86_64 0:2.0.9-21.el6
  libreport-plugin-mailx.x86_64 0:2.0.9-21.el6
  libreport-plugin-reportuploader.x86_64 0:2.0.9-21.el6
  libreport-plugin-rhtsupport.x86_64 0:2.0.9-21.el6
  libreport-python.x86_64 0:2.0.9-21.el6
  libtar.x86_64 0:1.2.11-17.el6_4.1
  mpfr.x86_64 0:2.4.1-6.el6
  ppl.x86_64 0:0.10.2-11.el6
  python-bitarray.x86_64 0:0.8.0-0contrail.el6
  python-bottle.noarch 0:0.11.6-0contrail.el6
  python-contrail.x86_64 0:2.0-22.el6
  python-contrail-vrouter-api.x86_64 0:2.0-22.el6
  python-devel.x86_64 0:2.6.6-52.el6
  python-gevent.x86_64 0:0.13.8-3.el6
  python-meld3.x86_64 0:0.6.7-1.el6
  python-netifaces.x86_64 0:0.5-1.el6
  python-pip.noarch 0:1.3.1-4.el6
  python-pycassa.noarch 0:1.10.0-0contrail.el6
  python-thrift.x86_64 0:0.9.1-0contrail.el6
  python-zope-filesystem.x86_64 0:1-5.el6
  python-zope-interface.x86_64 0:3.5.2-2.1.el6
  supervisor.noarch 0:2.1-9.el6
  xmltodict.noarch 0:0.7.0-0contrail.el6

Dependency Updated:
  python-lxml.x86_64 0:2.3.3-1.0contrail
```

* Install required Python packages.
```
# cd /opt/contrail/python_packages
# pip install Fabric-1.7.0.tar.gz
# pip install paramiko-1.11.0.tar.gz
# pip install pycrypto-2.6.tar.gz 
```

* Configure IP on network interface and restart interface.
Fab script needs to know the interface based on given IP address.

* Patch `/usr/lib/python2.6/site-packages/contrail_provisioning/compute/network.py`
```
+ import re
```

* Update `testbed.py` with compute nodes info on the builder.

* Run `fab` command on the builder to setup vRouter on the compute node.
```
# cd /opt/contrail/utils
# fab setup_vrouter_node:root@<compute node IP>
```

* Install packages for SNAT.
```
yum install python-docker-py
pip install requests-2.5.1.tar.gz
pip install unittest2-0.8.0.tar.gz
pip install opencontrail-vrouter-netns.tgz
```



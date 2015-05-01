# Install and Configure OpenContrail from PPA

## 1 Overview

This installation of OpenContrail is based on Ubuntu Trusty 14.04.1. Kernel version is 3.13.0-32-generic.


## 2 Pre-Installation

* Ubuntu repository.
* Set hostname and ensure it's resolvable.
* Enabled NTP server.
* Set repositories.
```
# apt-get install software-properties-common
# apt-add-repository ppa:opencontrail/ppa
# apt-add-repository ppa:opencontrail/release-2.01-juno
# curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
# echo "deb http://debian.datastax.com/community/ stable main" >> /etc/apt/sources.list.d/datastax.list
# apt-get update
```


## 3 Database

Install Packages.
```
$ sudo apt-get install cassandra
```

No additional configuration is required for single-node setup. Service is added into boot process and brought up by installation. By default, Cassandra listens to 127.0.0.1:9160 only.

Check status and listening port.
```
# nodetool status
# netstat -lan | egrep -e '9160.*LISTEN'
```


## 4 Message Bus

Install Packages.
```
$ sudo apt-get install rabbitmq-server
```

No additional Configuration is required for single-node setup. Service is added into boot process and brought up by installation.

Check status.
```
# service rabbitmq-server status
# rabbitmqctl status
```


## 5 Configuration Node

Install Packages.
```
# mkdir -p /etc/contrail
# apt-get install zookeeper ifmap-server haproxy
# apt-get install contrail-utils
# apt-get install contrail-config
```

### 5.1 Zookeeper

No additional Configuration is required for single-node setup. Copy [zookeeper.conf](setup/etc/init/zookeeper.conf) to `/etc/init/` and start service.
```
# service zookeeper start
```

### 5.2 IF-MAP Server
No additional Configuration is required for single-node setup. Service is added into boot process and brought up by installation.

Add username and password for the user of control.
```
$ echo "control:control" | sudo tee -a /etc/ifmap-server/basicauthusers.properties
$ sudo service ifmap-server restart
```

### 5.3 HAProxy

* Copy [haproxy.cfg](setup/etc/haproxy/haproxy.cfg) to `/etc/haproxy/`.
* Enable the service in `/etc/init.d/haproxy`.
* Create `/var/run/haproxy` directory.
* Start service.

### 5.4 Configuration API Server
No additional Configuration is required.

Create `/etc/contrail/debs_list.txt`.
```
$ echo "contrail-config" | sudo tee -a /etc/contrail/debs_list.txt
```

Restart service.
```
$ sudo supervisorctl -s unix:///tmp/supervisord_config.sock restart contrail-api:0
```

It takes a bit time for API server to initialize for the first run. Then it should start working.
```
$ curl http://127.0.0.1:8082/projects | python -mjson.tool
```

### 5.5 Schema Transformer

No additional Configuration is required.

### 5.6 Service Monitor

No additional Configuration is required.

### 5.7 Discovery

No additional Configuration is required.

Check the status.
```
$ sudo supervisorctl -s unix:///tmp/supervisord_config.sock status contrail-discovery:0
```

Check the services registered on discovery service.
```
$ curl http://127.0.0.1:5998/services
$ curl http://127.0.0.1:5998/clients
```


## 6 Analytics

Install Packages
```
$ sudo apt-get install redis-server
$ sudo apt-get install contrail-analytics
```

### 6.1 Redis Server

No additional Configuration is required.

### 6.2 Collector

Update discovery and Redis settings in /etc/contrail/contrail-collector.conf.
```
[DISCOVERY]
port=5998
server=127.0.0.1

[REDIS]
port=6379
server=127.0.0.1
```

Restart collector.
```
$ sudo service contrail-collector restart
```

### 6.3 Query Engine

Update discovery and Redis settings in /etc/contrail/contrail-query-engine.conf.
```
[DISCOVERY]
port=5998
server=127.0.0.1

[REDIS]
port=6379
server=127.0.0.1
```

Restart query engine.
```
$ sudo service contrail-query-engine restart
```

### 6.4 Analytics API Server

Update Redis settings in /etc/contrail/contrail-analytics-api.conf.
```
[REDIS]
server=127.0.0.1
redis_server_port=6381
redis_query_port=6381
```

Restart analytics API server.
```
$ sudo service contrail-analytics-api restart
```

This shall show the list of generators.
```
$ curl http://127.0.0.1:8081/analytics/generators | python -mjson.tool
```

This shall show some logs.
```
$ contrail-logs
```


## 7 Control

Install Packages
```
$ sudo apt-get install contrail-control
```

### 7.1 Control (BGP)

Update [DISCOVERY] and [IFMAP] settings in /etc/contrail/control-node.conf.
```
[DISCOVERY]
port=5998
server=127.0.0.1 # discovery_server IP address

[IFMAP]
password=control
user=control
```

Restart control.
```
$ sudo service contrail-control restart
```


## 8 Compute (vRouter)

Install Packages
```
$ sudo apt-get install contrail-vrouter-agent
$
$ sudo modprobe vrouter
$ echo "vrouter" | sudo tee -a /etc/modules
```

### 8.1 vRouter Agent

Update /etc/contrail/contrail-vrouter-agent.conf.
```
# IP address of discovery server
server=10.8.1.10

[VIRTUAL-HOST-INTERFACE]
# Everything in this section is mandatory

# name of virtual host interface
name=vhost0

# IP address and prefix in ip/prefix_len format
ip=10.8.1.11/24

# Gateway IP address for virtual host
gateway=10.8.1.254

# Physical interface name to which virtual host interface maps to
physical_interface=eth1
```

Update /etc/network/interfaces.
```
auto eth1
iface eth1 inet manual
        up ifconfig eth1 up
        down ifconfig eth1 down

auto vhost0
iface vhost0 inet static
        pre-up vif --create vhost0 --mac $(cat /sys/class/net/eth1/address)
        pre-up vif --add eth1 --mac $(cat /sys/class/net/eth1/address) --vrf 0 --vhost-phys --type physical
        pre-up vif --add vhost0 --mac $(cat /sys/class/net/eth1/address) --vrf 0 --type vhost --xconnect eth1
        address 10.8.1.11
        netmask 255.255.255.0
        gateway 10.8.1.254
        #network 10.8.1.0
        #broadcast 10.8.1.255
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers 8.8.8.8
```

Reboot compute node!
```
$ sudo reboot now
```




# Integrate Contrail with OpenStack Juno on Ubuntu 14.04

## 1 Overview

This is the guide to build a 3-node Contrail cluster and integrate it with Canonical OpenStack (Juno) on Ubuntu 14.04 (Trusty).

## 2 Requirements

### 2.1 OpenStack Cluster

The Canonical OpenStack cluster is already built.

### 2.2 Contrail Controller Resource

In production deployment, Contrail controller requires certain amount of hardware resources. Each controller includes services of configuration, database, analytics and control, not vRouter.

Controller can be either physical server or virtual machine. In case of VM, each controller has to be on a separate physical server, preferably on separate racks too. This is for HA purpose. Each VM runs on libvirt/KVM directly, can't be launched by OpenStack.

* CPU
  16 vCPUs/HTs

* Memory
  64 GB

* Storage
  600 GB

Due to the Cassandra database for configuration and analytics, at least 64GB is required for configuration database, and 300GB for holding analytics data for 48 hours (48-hour TTL is the default). More disk space is required for longer holding period. By default, database files are in /home/Cassandra directory. That's total 364 GB at minimum.

Here is an example of layout of partition with minimum required space.
/: 64GB
/var: 64GB
/home: 364GB

The layout could be changed, but the required space in each directory has to be met. For example, in case of single partition, 500GB is required.

Plus boot and swap partitions, the total disk space should be at least 600GB.

### 2.3 Contrail Controller Environment

* Networking
* NTP
* Resolvable host name


## 3 Build Contrail Controller

Copy the following files to each server.
* contrail-install-packages_2.10-39~ubuntu-14-04juno_all.deb
* setup.tgz

Login to the server.
```
$ sudo dpkg -i /path/to/contrail-install-packages_2.10-39~ubuntu-14-04juno_all.deb
$ cd /opt/contrail
$ tar xzf /path/to/setup.tgz
$ cd setup
$ cp host.params.template host.params
$ # Update parameters in host.params.
$ sudo ./install.sh controller
$ sudo ./setup.sh controller
```

## 4 Build Compute node

Steps are the same as building controller, except for running `install.sh` and `setup.sh`.

```
$ sudo ./install.sh compute
$ sudo ./setup.sh compute
```

## 5 Integrate

* Update Nova controller and Nova compute to use Neutron service provided by Contrail controller.
* Update Neutron service endpoing in Keystone pointing to Contrail controller.


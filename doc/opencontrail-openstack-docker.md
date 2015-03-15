
## Install docker.

```
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
$ echo "deb https://get.docker.io/ubuntu docker main" | sudo tee -a /etc/apt/sources.list.d/docker.list
$ sudo apt-get update
$ sudo apt-get install lxc-docker
```

## Add image to Glance
* Update /etc/glance/glance-api.conf.
```
 # Supported values for the 'container_format' image attribute
-#container_formats=ami,ari,aki,bare,ovf
+container_formats=ami,ari,aki,bare,ovf,docker
```

* Restart Glance API service.
```
$ sudo service glance-api restart
```

* Download Docker image and add into Glance.
```
$ sudo docker pull ubuntu
$ source /etc/contrail/openstackrc
$ sudo docker save ubuntu | glance image-create --name ubuntu --container-format=docker --disk-format=raw --is-public True
```
Note, the image name in Glance and Docker have to be the same.

* In order for Nova to communicate with Docker over its local socket, add *nova* to the *docker* group and restart the compute service to pick up the change.
```
$ sudo usermod -G libvirtd,docker nova
```

## Install nova-docker
This is the fork from nova-docker, in addition with OpenContrail VIF driver and some fixes.
```
$ git clone https://github.com/tonyliu0592/nova-docker.git
$ cd nova-docker
$ python setup.py build
$ sudo python setup.py install
$ sudo cp etc/nova/rootwrap.d/docker.filters /etc/nova/rootwrap.d/
```

## Update Nova compute configuration
On compute node, update /etc/nova/nova-compute.conf to set Nova driver and Docker VIF driver.
```
-compute_driver = libvirt.LibvirtDriver
+compute_driver = novadocker.virt.docker.DockerDriver
+
+[docker]
+vif_driver = novadocker.virt.docker.opencontrail.OpenContrailVIFDriver
``` 
When Nova calls `driver.spawn()` in `_build_and_run_instance()` in `nova/compute/manager.py`, `DockerDriver.spawn` in `novadocker/virt/docker/driver.py` is invoked.

Restart Nova compute service to apply all changes.
```
$ sudo service nova-compute restart
```

## Launch Docker container
Now, Docker container can be launched by either Nova client or OpenStack Web UI, as the same as launching VM.


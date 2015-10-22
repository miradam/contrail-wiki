VCP has two interfaces, management and internal.
* Management interface is mapped to fxp0 and connected to "external" bridge.
* Internal interface is connected to internal bridge for connecting to VFP.

VFP, other than management and internal interfaces, also has data interfaces.
* Management interface is connected to "external" bridge.
* Internal interface is connected to internal bridge for connecting to VCP.
* Data interface (ge-0/0/*) can connect to a NIC or a bridge.

```
     TAP             internal    management   data        data
     interface       bridge      bridge       interface   interface
                       |            |         /bridge     /bridge
VCP  vcp_int-vmx1 ---->|            |            |           |
     vcp_ext-vmx1 -----+----------->|            |           |
                       |            |            |           |
VFP  vfp_int-vmx1 ---->|            |            |           |
     vfp_ext-vmx1 -----+----------->|            |           |
     ge-0/0/0-vmx1 ----------------------------->|           |
     ge-0/0/1-vmx1 ----------------------------------------->|
```

```
bridge name     bridge id               STP enabled     interfaces
br-int-vmx1     8000.52540007fbaa       yes             br-int-vmx1-nic
                                                        vcp_int-vmx1
                                                        vfp_int-vmx1
br-mgmt         8000.52540076a52b       yes             br-mgmt-nic
                                                        eth1
                                                        vcp_ext-vmx1
                                                        vfp_ext-vmx1
virbr0          8000.fe060a0efff1       yes             ge-0.0.0-vmx1
                                                        ge-0.0.1-vmx1
```
```
##############################################################
#
#  vmx.conf
#  Config file for vmx on the hypervisor.
#  Uses YAML syntax. 
#  Leave a space after ":" to specify the parameter value.
#
##############################################################

--- 
#Configuration on the host side - management interface, VM images etc.
HOST:
    identifier                : vmx1   # Maximum 4 characters
    host-management-interface : eth1
    routing-engine-image      : "/root/vmx-14.1R5.4-1/images/jinstall64-vmx-14.1R5.4-domestic.img"
    routing-engine-hdd        : "/root/vmx-14.1R5.4-1/images/vmxhdd.img"
    forwarding-engine-image   : "/root/vmx-14.1R5.4-1/images/vPFE-lite-20150707.img"

---
# External bridge for management interfaces.
BRIDGES:
    - type  : external
      name  : br-mgmt                  # Max 10 characters

--- 
# vRE VM parameters
CONTROL_PLANE:
    vcpus       : 1
    memory-mb   : 1024 
    console_port: 8601

    # Management interface, map to fxp0.
    interfaces  :
      - type      : static
        ipaddr    : 10.84.29.98
        macaddr   : "0A:00:DD:C0:DE:0E"

--- 
# vPFE VM parameters
FORWARDING_PLANE:
    memory-mb   : 6144 
    vcpus       : 3
    console_port: 8602
    device-type : virtio 

    # Management interface, map to eth0.
    interfaces  :
      - type      : static
        ipaddr    : 10.84.29.99
        macaddr   : "0A:00:DD:C0:DE:10"

--- 
# Data interfaces on forwarding plane.
JUNOS_DEVICES:
   - interface            : ge-0/0/0
     mac-address          : "02:06:0A:0E:FF:F0"
     description          : "ge-0/0/0 interface"
   
   - interface            : ge-0/0/1
     mac-address          : "02:06:0A:0E:FF:F1"
     description          : "ge-0/0/0 interface"
```

```
<domain type='kvm' id='2'>
  <name>vcp-vmx1</name>
  <uuid>d6b35b94-a4ae-4cb0-9631-7b163c5bdb81</uuid>
  <memory unit='KiB'>1000448</memory>
  <currentMemory unit='KiB'>1000000</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <cputune>
    <vcpupin vcpu='0' cpuset='0'/>
  </cputune>
  <resource>
    <partition>/machine</partition>
  </resource>
  <sysinfo type='smbios'>
    <bios>
      <entry name='vendor'>Juniper</entry>
    </bios>
    <system>
      <entry name='manufacturer'>Juniper</entry>
      <entry name='product'>VM-vcp_vmx1-161-re-0</entry>
      <entry name='version'>0.1.0</entry>
    </system>
  </sysinfo>
  <os>
    <type arch='x86_64' machine='pc-0.13'>hvm</type>
    <boot dev='hd'/>
    <smbios mode='sysinfo'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode='host-model'>
    <model fallback='forbid'/>
    <topology sockets='1' cores='1' threads='1'/>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='directsync'/>
      <source file='/root/vmx-14.1R5.4-1/build/vmx1/images/jinstall64-vmx-14.1R5.4-domestic.img'/>
      <target dev='hda' bus='ide'/>
      <alias name='ide0-0-0'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='directsync'/>
      <source file='/root/vmx-14.1R5.4-1/build/vmx1/images/vmxhdd.img'/>
      <target dev='hdb' bus='ide'/>
      <alias name='ide0-0-1'/>
      <address type='drive' controller='0' bus='0' target='0' unit='1'/>
    </disk>
    <controller type='usb' index='0'>
      <alias name='usb0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <interface type='bridge'>
      <mac address='0a:00:dd:c0:de:0e'/>
      <source bridge='br-mgmt'/>
      <target dev='vcp_ext-vmx1'/>
      <model type='e1000'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:39:cc:4f'/>
      <source bridge='br-int-vmx1'/>
      <target dev='vcp_int-vmx1'/>
      <model type='virtio'/>
      <alias name='net1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </interface>
    <serial type='tcp'>
      <source mode='bind' host='127.0.0.1' service='8601'/>
      <protocol type='telnet'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='tcp'>
      <source mode='bind' host='127.0.0.1' service='8601'/>
      <protocol type='telnet'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='tablet' bus='usb'>
      <alias name='input0'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='5900' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <sound model='ac97'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </sound>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='apparmor' relabel='yes'>
    <label>libvirt-d6b35b94-a4ae-4cb0-9631-7b163c5bdb81</label>
    <imagelabel>libvirt-d6b35b94-a4ae-4cb0-9631-7b163c5bdb81</imagelabel>
  </seclabel>
</domain>
```

```
<domain type='kvm' id='3'>
  <name>vfp-vmx1</name>
  <uuid>bf80dbd9-da78-442a-8135-028a58196acf</uuid>
  <memory unit='KiB'>6000640</memory>
  <currentMemory unit='KiB'>6000000</currentMemory>
  <memoryBacking>
    <hugepages/>
    <nosharepages/>
  </memoryBacking>
  <vcpu placement='static'>3</vcpu>
  <numatune>
    <memory mode='strict' nodeset='0'/>
  </numatune>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
  </features>
  <cpu mode='host-model'>
    <model fallback='forbid'/>
    <topology sockets='1' cores='3' threads='1'/>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw' cache='directsync'/>
      <source file='/root/vmx-14.1R5.4-1/build/vmx1/images/vPFE-lite-20150707.img'/>
      <target dev='hda' bus='ide'/>
      <alias name='ide0-0-0'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='usb' index='0'>
      <alias name='usb0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <mac address='0a:00:dd:c0:de:10'/>
      <source bridge='br-mgmt'/>
      <target dev='vfp_ext-vmx1'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:42:30:42'/>
      <source bridge='br-int-vmx1'/>
      <target dev='vfp_int-vmx1'/>
      <model type='virtio'/>
      <alias name='net1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:76:a5:1b'/>
      <source network='default'/>
      <target dev='ge-0.0.0-vmx1'/>
      <model type='virtio'/>
      <alias name='net2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:72:68:91'/>
      <source network='default'/>
      <target dev='ge-0.0.1-vmx1'/>
      <model type='virtio'/>
      <alias name='net3'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </interface>
    <serial type='tcp'>
      <source mode='bind' host='127.0.0.1' service='8602'/>
      <protocol type='telnet'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='tcp'>
      <source mode='bind' host='127.0.0.1' service='8602'/>
      <protocol type='telnet'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='tablet' bus='usb'>
      <alias name='input0'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='5901' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <sound model='ac97'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </sound>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='apparmor' relabel='yes'>
    <label>libvirt-bf80dbd9-da78-442a-8135-028a58196acf</label>
    <imagelabel>libvirt-bf80dbd9-da78-442a-8135-028a58196acf</imagelabel>
  </seclabel>
</domain>
```


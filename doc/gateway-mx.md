# MX as the gateway

## 1 Configuration Block

### 1.1 Interface/Address
There is interface on control plane connecting to control nodes and running BGP. There is also interface on data plane connecting to vrouters and running data traffic in tunnel.

In case separate interfaces are used for control and data planes, the address of control interface will be used as the next-hop, when MX advertises route. To resolve this issue, a loopback interface can be used for both control and data planes.

### 1.2 BGP

* The interface with IP address running BGP.
```
interfaces {
    ge-0/0/1 {
        description "Cluster-1";
        unit 0 {
            family inet {
                address 10.1.1.254/24;
            }
        }
    }
}
```

* The gateway ASN and BGP protocol.
IBGP
```
routing-options {
    autonomous-system 64512;
}
protocols {
    bgp {
        group cluster-1 {
            type internal;
            local-address 10.1.1.254;
            keep all;
            family inet-vpn {
                unicast;
            }
            allow 10.1.1.0/24;
            neighbor 10.1.1.200;
            neighbor 10.1.1.201;
        }
    }
}
```

EBGP
```
routing-options {
    autonomous-system 64512;
}
protocols {
    bgp {
        group cluster-1 {
            type external;
            multihop;
            local-address 10.84.63.168;
            keep all;
            family inet-vpn {
                unicast;
            }
            peer-as 64520;
            allow 10.84.29.0/24;
            neighbor 10.84.29.96;
        }
    }
}
```
If gateway ASN is the same as OpenContrail control ASN, iBGP is used and BGP type is "internal". Otherwise, eBGP is used and BGP type is "external". In case of eBGP, "peer-as" has to be configured. OpenContrail control is able to automatically select between iBGP and eBGP based on local and peer ASNs.

"local-address" is the address of loopback interface, in case contrail plane and data plane have separate interfaces. Otherwise, it's the address of interface. shared by both control and data planes.

"family" is "inet-vpn" for BGP L3VPN, "evpn" for BGP EVPN.

Family "route-target" is for optimization purpose. When it's configured, MX and OpenContrail control have to receive the route-target route from the peer before advertizing requested routes. In case separate interfaces on control and data planes, MX receives route-target route from Contrail control node. The next-hop of RT route is control node address (on control plane). MX tries to resolve the next-hop in MPLS table (inet.3) that is on data plane, and fails. So that RT route is not applied and hidden. That results MX doesn't advertise routes. A static route can be added into inet.3 to make the next-hop of control interface resolvable. Then MX applies the RT route and advertise routes. OpenContrail doesn't have such issue, because it doesn't try to resolve the next-hop.


### 1.3 Dynamic GRE Tunnel
For L3VPN, when BGP gets a route, it looks for a path for that route. In case of MPLSoMPLS, it looks for LSP. If there is no LSP, and dynamic tunnel is configured, then BGP will get a GRE interface for GRE tunnel dynamically.
```
routing-options {
    dynamic-tunnels {
        cluster-1 {
            source-address 10.1.1.254;
            gre;
            destination-networks {
                10.1.1.0/24;
            }
        }
    }
}
```
"source-address" is the loopback address in case control and data planes have separate interfaces.


### 1.4 Logical Tunnel
Logical tunnel is for connection master routing instances and virtual network routing instance. This is optional depending on use case.
```
chassis {
    fpc 4 {
        pic 0 {
            tunnel-services;
        }
    }
}
interfaces {
    lt-4/0/0 {
        unit 101 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 201;
            family inet;
        }
        unit 201 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 101
            family inet;
        }
    }
}
routing-options {
    static {                            
        route 10.1.100.0/24 next-hop lt-4/0/0.101;
    }
}
```
An alternative is to use routing instance as the next-hop. In that case, one additional routing instance is required to avoid routing loop between master RI and virtual network RI.


### 1.5 Virtual Network Routing Instance
Routes are propagated between virtual network routing instance on gateway and virtual network in OpenContrail who have the same routing target. This is how virtual network is extended from overlay to underlay/external network.
```
routing-instances {
    cluster-1-public {
        instance-type vrf;
        interface lt-4/0/0.201;
        route-distinguisher 64512:10001;
        vrf-target target:64512:10001;
        vrf-table-label;
        routing-options {
            static {
                route 0.0.0.0/0 next-hop lt-4/0/0.201;
            }
        }
    }
}
```


## 2 Mulitple Clusters
One gateway can support multiple clusters who should have different ASN.

* One ASN for the gateway.
* Clusters have different private ASNs.
* iBGP among control nodes within each cluster.
* eBGP between gateway and control nodes of each cluster.
* Multiple BGP groups can share the same interface connecting to different set of neighbors.
* One dynamic tunnel groups for each cluster if they are in separate networks.
* Each cluster should have separate public address space. Since no address collision, one VRF routing instance can be shared by multiple clusters. And the public virtual network in all clusters have to have the same routing target. As a result, public route from one cluster will be leaked to another cluster.
 

## 3 Separate Control and Data Planes


## 4 Route Target Filtering


Appendix


# MX as the gateway

## 1 Configuration Block

### 1.1 BGP
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
protocols {
    bgp {
        group cluster-1 {
            type internal;
            local-address 10.1.1.254;
            keep all;
            family inet-vpn {
                unicast;
            }
            peer-as 64512;
            local-as 64512;
            allow 10.1.1.0/24;
            neighbor 10.1.1.200;
            neighbor 10.1.1.201;
        }
    }
}
```

### 1.2 Dynamic Tunnel
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

### 1.3 Logical Tunnel
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

### 1.4 Route-Target


### 1.5 Multi-cluster


### 1.6 Multi-AS


## 2 Examples

### 2.1 Single Cluster

### 2.2 Multi-Cluster


chassis {
    fpc 4 {
        pic 0 {
            tunnel-services;
        }
    }
}
interfaces {
    ge-0/0/1 {
        description "Cluster-1";
        unit 0 {
            family inet {
                address 10.1.1.254/24;
            }
        }
    }
    ge-0/0/2 {                          
        description "Cluster-2";
        unit 0 {
            family inet {
                address 10.1.2.254/24;
            }
        }
    }
    lt-4/0/0 {
        unit 101 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 201;
            family inet;
        }
        unit 102 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 202;
            family inet;
        }
        unit 201 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 101
            family inet;
        }
        unit 202 {
            encapsulation frame-relay;
            dlci 1;
            peer-unit 102;
            family inet;
        }
    }
}
routing-options {
    static {                            
        route 0.0.0.0/0 next-hop 10.227.6.1;
        route 10.1.100.0/24 next-hop lt-4/0/0.101;
        route 10.1.200.0/24 next-hop lt-4/0/0.102;
    }
    dynamic-tunnels {
        cluster-1 {
            source-address 10.1.1.254;
            gre;
            destination-networks {
                10.1.1.0/24;
            }
        }
        cluster-2 {
            source-address 10.1.2.254;
            gre;
            destination-networks {
                10.1.2.0/24;
            }
        }
    }
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
            peer-as 64512;
            local-as 64512;
            allow 10.1.1.0/24;
            neighbor 10.1.1.200;
            neighbor 10.1.1.201;
        }
        group cluster-2 {
            type internal;
            local-address 10.1.2.254;
            keep all;
            family inet-vpn {
                unicast;
            }
            peer-as 64512;
            local-as 64512;
            allow 10.1.2.0/24;
            neighbor 10.1.2.200;
            neighbor 10.1.2.201;
        }
    }
}
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
    cluster-2-public {
        instance-type vrf;
        interface lt-4/0/0.202;
        route-distinguisher 64512:20001;
        vrf-target target:64512:20001;
        vrf-table-label;
        routing-options {
            static {
                route 0.0.0.0/0 next-hop lt-4/0/0.202;
            }
        }
    }
}


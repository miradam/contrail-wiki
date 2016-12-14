1. Deploy OpenStack and Contrail with contrail-install-packages_3.0.2.0-51~ubuntu-14-04liberty_all.deb.

## 1 Keystone
2. Check Keystone v2 and v3.
```
curl -s http://localhost:35357/v3 | python -m json.tool
curl -s http://localhost:35357/v2.0 | python -m json.tool 
```

3. Grant user `admin` to domain `default` with role `admin`.

* Get admin token from /etc/keystone/keystone.conf.

* Get the ID of user `admin`.
```
curl -s \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/users \
    | python -m json.tool
```

* Get the ID of role `admin`.
```
curl -s \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/roles \
    | python -m json.tool
```

* Grant user `admin` to domain `default` with role `admin`.
```
curl -s \
    -X PUT \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/domains/default/users/82e4bcb9077446fca46426defdbe3d21/roles/ccddea88ad3b4c53a06c50b4c269c18a
```

4. Create /etc/contrail/openstackrc_v3.
```
export OS_USERNAME=admin
export OS_PASSWORD=contrail123
export OS_AUTH_URL=http://10.87.64.166:5000/v3
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=RegionOne
export OS_NO_CACHE=1
```

5. Check Keystone v3 with openstack CLI.
```
source /etc/contrail/openstackrc_v3
openstack user list
openstack image list
openstack network list
```

6. Test.
* Create a domain.
* Create an user.
* Grant the user to access domain as role `admin`.
* Create a project/tenant.
* Grant the user to project.


## 2 Contrail

1. /etc/contrail/contrail-keystone-auth.conf
```
[KEYSTONE]
auth_url=http://10.87.64.166:35357/v3
auth_host=10.87.64.166
auth_protocol=http
auth_port=35357
admin_user=admin
admin_password=contrail123
admin_tenant_name=admin
memcache_servers=127.0.0.1:11211
insecure=False
```

2. Restart configuration services.
```
service supervisor-config restart
```


## 3 Neutron

1. /etc/neutron/neutron.conf
```
[keystone_authtoken]
# Public identity API endpoint.
auth_uri = http://10.87.64.166:35357/v3/
# Admin identity API endpoint.
identity_uri = http://10.87.64.166:5000
admin_tenant_name = service
admin_user = neutron
admin_password = contrail123
auth_host = 10.87.64.166
auth_protocol = http
```

2. Restart Neutron service.
```
service neutron-server restart
```


## 4 Nova

1. Update /etc/nova/nova.conf for both Nova API on controller and Nova compute on compute node.
```
#neutron_admin_tenant_name = service
#neutron_admin_username = neutron
#neutron_admin_password = contrail123
#neutron_admin_auth_url = http://10.87.64.166:35357/v2.0/
#neutron_url = http://10.87.64.166:9696/
#neutron_url_timeout = 300

[keystone_authtoken]
auth_url = http://10.87.64.166:35357/v3/
admin_tenant_name = service
admin_user = nova
admin_password = contrail123
auth_host = 10.87.64.166
auth_protocol = http
signing_dir = /tmp/keystone-signing-nova

[neutron]
auth_plugin = password
auth_url = http://10.87.64.166:35357/v3/
username = neutron
password = contrail123
project_name = service
user_domain_name = Default
project_domain_name = Default
url = http://10.87.64.166:9696/
url_timeout = 300
service_metadata_proxy = True
```

2. Restart Nova API on controller and Nova compute on compute node.
```
service nova-api restart
```
```
service nova-compute restart
```


Compute endpoint requires tenant ID. Keystone v3 auth needs either tenant or domain, not both.
```
unset OS_DOMAIN_NAME
openstack --os-project-id 88b08be53b824c61b90d198b8cde969e server list
```

Get token and catalog with scope of project. The catalog contains compute endpoints. With scope of domain (not specify project), compute endpoints will be empty.
```
curl -s -i -X POST -H "Content-Type: application/json" -d '
{"auth": {
  "scope": {
    "project": {"id": "88b08be53b824c61b90d198b8cde969e"}
  },
  "identity": {
    "methods": ["password"],
    "password": {
      "user": {
        "name": "admin",
        "domain": {"name": "Default"},
        "password": "contrail123"
      }
    }
  }
}
}'   http://localhost:35357/v3/auth/tokens
```


## 5 Dashboard

1. Update /etc/openstack-dashboard/local_settings.py.
```
OPENSTACK_API_VERSIONS = {
    "identity": 3,
}
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'
```

2. Restart the service.
```
service apache2 restart
service memcached restart
```

3. Test.
User of non-default domain is able to login.




# Appendix

* scoped token request
```
curl -s -i -X POST -H "Content-Type: application/json" -d '
{"auth": {
  "scope": {
    "domain": {"name": "Default"}
  },
  "identity": {
    "methods": ["password"],
    "password": {
      "user": {
        "name": "admin",
        "domain": {"name": "Default"},
        "password": "contrail123"
      }
    }
  }
}
}'   http://localhost:35357/v3/auth/tokens
```
```
curl -s -i -X POST -H "Content-Type: application/json" -d '
{"auth": {
  "scope": {
    "project": {"id": "88b08be53b824c61b90d198b8cde969e"}
  },
  "identity": {
    "methods": ["password"],
    "password": {
      "user": {
        "name": "admin",
        "domain": {"name": "Default"},
        "password": "contrail123"
      }
    }
  }
}
}'   http://localhost:35357/v3/auth/tokens
```

* unscoped token request
```
curl -s -i -X POST -H "Content-Type: application/json" -d '
{"auth": {
  "identity": {
    "methods": ["password"],
    "password": {
      "user": {
        "name": "admin",
        "domain": {"name": "Default"},
        "password": "contrail123"
      }
    }
  }
}
}' http://localhost:35357/v3/auth/tokens
```

* create domain
```
curl -X POST -H "X-Auth-Token: 2ecd20be919ac3c5cc98" -H "Content-Type: application/json" -d '
{
    "domain": {
        "description": "Cloud domain",
        "enabled": true,
        "name": "domain-cloud"
    }
}' http://localhost:35357/v3/domains
```

* disable domain
```
curl -X PATCH -H "X-Auth-Token: 2ecd20be919ac3c5cc98" -H "Content-Type: application/json" -d '
{
    "domain": {
        "enabled": false
    }
}' http://localhost:5000/v3/domains/c7e715f9a2d8460bb7004c60c5b830e6
```

* delete domain
```
curl -s \
    -X DELETE \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    http://localhost:5000/v3/domains/c7e715f9a2d8460bb7004c60c5b830e6
```

* create user
```
curl -X POST -H "X-Auth-Token: 2ecd20be919ac3c5cc98" -H "Content-Type: application/json" -d '
{
    "user": {
        "description": "Cloud administrator",
        "domain_id": "0ae132585fc54bbf8255975d6acd8003",
        "enabled": true,
        "name": "admin-cloud",
        "password": "contrail123"
    }
}' http://localhost:35357/v3/users
```
```
curl -s \
    -X PUT \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/domains/0ae132585fc54bbf8255975d6acd8003/users/9cf918df2d6f4bc48fc293fb7e420027/roles/ccddea88ad3b4c53a06c50b4c269c18a
```
```
curl -X POST -H "X-Auth-Token: 2ecd20be919ac3c5cc98" -H "Content-Type: application/json" -d '
{
    "project": {
        "enabled": true,
        "domain_id": "0ae132585fc54bbf8255975d6acd8003",
        "name": "demo"
    }
}' http://localhost:35357/v3/projects
```
```
curl -s \
    -X PUT \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/projects/d8823c749c4d472a82d5d9e42d395e46/users/9cf918df2d6f4bc48fc293fb7e420027/roles/ccddea88ad3b4c53a06c50b4c269c18a
```

* delete role assignment
```
curl -s \
    -X DELETE \
    -H "X-Auth-Token: 2ecd20be919ac3c5cc98" \
    -H "Content-Type: application/json" \
    http://localhost:5000/v3/domains/c7e715f9a2d8460bb7004c60c5b830e6/users/82e4bcb9077446fca46426defdbe3d21/roles/ccddea88ad3b4c53a06c50b4c269c18a
```


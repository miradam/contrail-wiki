#!/bin/bash

source ./contrail.params

src_etc=/opt/contrail/etc

contrail_repo_install()
{
    echo "Install contrail repo"

    cat << __EOT__ > /etc/yum.repos.d/contrail-install.repo
[contrail-install-repo]
name=contrail-install-repo
baseurl=file:///opt/contrail/contrail_install_repo/
enabled=1
priority=1
gpgcheck=0
__EOT__
}

controller_install()
{
    echo "Install controller..."

    # Pre-install
    cp $src_etc/rc.d/init.d/ifmap /etc/rc.d/init.d
    mkdir -p /etc/contrail

    # Install packages
    package_list="
        net-tools
        python-kazoo
        python-ncclient
        python-netifaces
        python-paramiko
        tcpdump
        zookeeper
        ifmap-server
        rabbitmq-server
        haproxy
        contrail-config
        contrail-database
        contrail-analytics
        contrail-control
        contrail-dns
        contrail-web-core
        contrail-web-controller
        contrail-utils
        contrail-nodemgr"

    yum -y install $package_list

    echo "Install controller is completed."
}

controller_provision()
{
    echo "Provisioning controller..."

    sed -i 's/-Xss180k/-Xss256k/' /etc/cassandra/conf/cassandra-env.sh

    cat << __EOT__ >> /etc/ifmap-server/basicauthusers.properties
api-server:api-server
schema-transformer:schema-transformer
control-user:control-user-passwd
$host_ip.dns:$host_ip.dns
__EOT__

    rm -f /etc/haproxy/haproxy.cfg
    sed "s/__HOST_IP__/$host_ip/g" $src_etc/haproxy/haproxy.cfg.template > /etc/haproxy/haproxy.cfg

    cp $src_etc/rc.d/init.d/zookeeper /etc/rc.d/init.d

    sed -i "s/bind 127.0.0.1/#bind 127.0.0.1/" /etc/redis.conf

    sed -i "/config.orchestration.Manager/ c\
        config.orchestration.Manager = 'none'" \
        /etc/contrail/config.global.js

    sed -i "/config.getDomainsFromApiServer/ a\
        \\\n\
        config.multi_tenancy = {};\\n\
        config.multi_tenancy.enabled = false;" \
        /etc/contrail/config.global.js

    config_file_list="
        contrail-api.conf
        contrail-schema.conf
        contrail-discovery.conf
        contrail-analytics-api.conf
        contrail-collector.conf
        contrail-query-engine.conf
        contrail-control.conf
        contrail-dns.conf
        contrail-database-nodemgr.conf"
    for f in $config_file_list
    do
        rm -f /etc/contrail/$f
        sed -e "s/__HOST_IP__/$host_ip/g" -e "s/__HOST_NAME__/$host_name/g" $src_etc/contrail/$f.template > /etc/contrail/$f
    done

    copy_file_list="
        rpm_list.txt
        supervisord_config_files/contrail-nodemgr-config.ini
        supervisord_config_files/ifmap.ini
        supervisord_config_files/rabbitmq-server.ini
        supervisord_analytics_files/contrail-nodemgr-analytics.ini
        supervisord_control_files/contrail-nodemgr-control.ini"

    mkdir -p $dst/supervisord_config_files
    mkdir -p $dst/supervisord_analytics_files
    mkdir -p $dst/supervisord_control_files

    for f in $copy_file_list
    do
        cp $src_etc/contrail/$f /etc/contrail/$f
    done

    systemctl enable redis haproxy rabbitmq-server
    chkconfig --add supervisor-analytics
    chkconfig --add supervisor-config
    chkconfig --add supervisor-control
    chkconfig --add supervisor-database
    chkconfig --add supervisor-webui
    chkconfig --add zookeeper

    echo "Provisioning controller is comleted."
}

compute_install()
{
    echo "Install compute..."

    # Pre-install
    mkdir -p /etc/contrail
    cat /sys/class/net/$nic/address > /etc/contrail/default_if
    cat /sys/class/net/$nic/address > /etc/contrail/default_pmac

    # Install packages
    package_list="
        net-tools
        contrail-vrouter
        contrail-vrouter-init
        contrail-utils
        contrail-nodemgr"

    yum -y install $package_list

    echo "Install compute is completed."
}

compute_provision()
{
    echo "Provisioning compute..."

    /opt/contrail/bin/vnagent_param_setup.sh $(uname -r)
    sed "s/__DEVICE__/$nic/" /etc/contrail/agent_param.tmpl > /etc/contrail/agent_param
    rm -f /etc/contrail/agent_param.tmpl

    rm -f /etc/contrail/contrail-vrouter-agent.conf
    sed -e "s/__DEVICE__/$nic/g" -e "s/__HOST_IP__/$host_ip/g" -e "s/__HOST_IP_PREFIX__/$host_ip_prefix/g" -e "s/__GATEWAY__/$gateway/g" -e "s/__CONTROL__/$controller/g" $src_etc/contrail/contrail-vrouter-agent.conf.template > /etc/contrail/contrail-vrouter-agent.conf

    cp $src_etc/contrail/rpm_list.txt /etc/contrail

    chkconfig --add supervisor-vrouter

    # Create ifcfg-vhost0 and update ifcfg-$nic
    nic_path=/etc/sysconfig/network-scripts
    if [ ! -f $nic_path/ifcfg-$nic.orig ]; then
        cp $nic_path/ifcfg-$nic $nic_path/ifcfg-$nic.orig
    fi

    cat << __EOT__ > $nic_path/ifcfg-vhost0
DEVICE=vhost0
ONBOOT=yes
NM_CONTROLLED=no
#NETWORK MANAGER BUG WORKAROUND
SUBCHANNELS=1,2,3
BOOTPROTO=none
__EOT__

    sed -n '/IPADDR/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0
    sed -n '/NETMASK/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0
    sed -n '/NETWORK/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0
    sed -n '/BROADCAST/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0
    sed -n '/GATEWAY/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0
    sed -n '/DNS/ p' $nic_path/ifcfg-$nic >> $nic_path/ifcfg-vhost0

    sed -i -e '/IPADDR/ d' -e '/NETMASK/ d' -e '/NETWORK/ d' -e '/GATEWAY/ d' -e '/DNS/ d' -e '/BOOTPROTO/ d' $nic_path/ifcfg-$nic

    echo "Provisioning compute is completed"
}

if [ ! -e /etc/yum.repos.d/contrail-install.repo ]
then
    contrail_repo_install
fi

if [ $1 == "controller" ]
then
    controller_install
    controller_provision
elif [ $1 == "compute" ]
then
    compute_install
    compute_provision
else
    echo "$1 is invalid."
fi


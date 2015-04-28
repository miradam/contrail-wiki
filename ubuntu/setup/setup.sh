#! /bin/bash

setup_dir=/opt/contrail/setup

if [ -e host.params ]
then
    source host.params
else
    echo "host.params doesn't exist!"
    exit
fi


set_conf()
{
    sudo sed \
        -e "s/__host_ip__/${host_ip[$host_index]}/g" \
        -e "s/__host_ip_prefix__/$host_ip_prefix/g" \
        -e "s/__hostname__/${hostname[$host_index]}/g" \
        -e "s/__auth_host__/$auth_host/g" \
        -e "s/__admin_user__/$admin_user/g" \
        -e "s/__admin_password__/$admin_password/g" \
        -e "s/__admin_tenant__/$admin_tenant/g" \
        -e "s/__admin_token__/$admin_token/g" \
        -e "s/__host1_ip__/${host_ip[1]}/g" \
        -e "s/__host1_name__/${hostname[1]}/g" \
        -e "s/__host2_ip__/${host_ip[2]}/g" \
        -e "s/__host2_name__/${hostname[2]}/g" \
        -e "s/__host3_ip__/${host_ip[3]}/g" \
        -e "s/__host3_name__/${hostname[3]}/g" \
        -e "s/__external_vip__/$external_vip/g" \
        -e "s/__external_vip_name__/${external_vip//./_}/" \
        -e "s/__external_vip_prefix__/$external_vip_prefix/" \
        -e "s/__external_dev__/$external_dev/" \
        -e "s/__internal_vip__/$internal_vip/g" \
        -e "s/__internal_vip_name__/${internal_vip//./_}/" \
        -e "s/__internal_vip_prefix__/$internal_vip_prefix/" \
        -e "s/__internal_gw__/$internal_gw/" \
        -e "s/__internal_dev__/$internal_dev/" \
        -e "s/__data_ip__/$data_ip/" \
        -e "s/__data_ip_prefix__/$data_ip_prefix/" \
        -e "s/__data_gw__/$data_gw/" \
        -e "s/__data_dev__/$data_dev/" \
        -e "s/__compute_host__/$compute_host/g" \
        -e "s/__image_host__/$image_host/g" \
        -e "s/__storage_host__/$storage_host/g" \
        $setup_dir/$file > /$file
}

set_conf_list()
{
    for file in $file_list
    do
        set_conf
    done
}

disable_services()
{
    echo "Disable services..."

    service_list="
        #jujud-machine.*conf
        #jujud-unit-ubuntu.*conf
        #jujud-unit-nova-compute.*conf
        #jujud-unit-ubuntu-compute.*conf
        #jujud-unit-landscape.*conf
        neutron-ovs-cleanup.conf
        neutron-plugin-openvswitch-agent.conf
        openvswitch-force-reload-kmod.conf
        openvswitch-switch.conf
        ufw.conf"

    for service in $service_list
    do
        aa=`ls /etc/init | grep $service`
        if [ $aa ]
        then
            sudo service ${aa%.conf} stop
            sudo echo manual > /etc/init/${aa%.conf}.override
        fi
    done

    echo "Done."
}

setup_update_limits()
{
    echo "Setup update limits..."

    file=/etc/security/limits.conf
    if ! grep -q "root soft nofile 65535" $file
    then
        echo "root soft nofile 65535" >> $file
        echo "root hard nofile 65535" >> $file
        echo "* hard nofile 65535" >> $file
        echo "* soft nofile 65535" >> $file
        echo "* hard nproc 65535" >> $file
        echo "* soft nofile 65535" >> $file
    fi

    file=/etc/sysctl.conf
    if ! grep -q "fs.file-max = 65535" $file
    then
        echo "kernel.core_pattern = /var/crashes/core.%e.%p.%h.%t" >> $file
        echo "net.ipv4.tcp_keepalive_time = 5" >> $file
        echo "net.ipv4.tcp_keepalive_probes = 5" >> $file
        echo "net.ipv4.tcp_keepalive_intvl = 1" >> $file
        echo "fs.file-max = 65535" >> $file
        sudo sysctl -p
    fi


    echo "Done."
}

setup_ha()
{
    echo "Setup HA..."

    file_list="
        etc/keepalived/keepalived.conf
        etc/haproxy/haproxy.cfg"
    set_conf_list

    echo "Done."
}

setup_rabbitmq()
{
    echo "Setup RabbitMQ..."

    sudo rm -rf /var/lib/rabbitmq/mnesia

    file=/etc/hosts
    if ! grep -q ${hostname[1]}-ctrl $file
    then
        sudo echo "${host_ip[1]} ${hostname[1]} ${hostname[1]}-ctrl" >> $file
        sudo echo "${host_ip[2]} ${hostname[2]} ${hostname[2]}-ctrl" >> $file
        sudo echo "${host_ip[3]} ${hostname[3]} ${hostname[3]}-ctrl" >> $file
    fi

    file_list="
        etc/rabbitmq/rabbitmq-env.conf
        etc/rabbitmq/rabbitmq.config"
    set_conf_list

    file=/var/lib/rabbitmq/.erlang.cookie
    sudo echo '24304e46-cd1a-4c72-8c88-e3e5c9889937' > $file
    sudo chmod 400 $file
    sudo chown rabbitmq:rabbitmq $file

    sudo cp -r $setup_dir/etc/contrail/supervisord_support* /etc/contrail

    echo "Done."
}

setup_database()
{
    echo "Setup database..."

    sudo rm -f /etc/init/supervisor-database.override

    file_list="
        etc/cassandra/cassandra.yaml
        etc/cassandra/cassandra-env.sh
        etc/zookeeper/conf/zoo.cfg
        etc/zookeeper/conf/environment
        etc/zookeeper/conf/log4j.properties
        etc/contrail/contrail-database-nodemgr.conf"
    set_conf_list

    file=/etc/zookeeper/conf/myid
    sudo echo $host_index > $file

    sudo cp -r $setup_dir/etc/contrail/supervisord_database* /etc/contrail

    echo "Done."
}

setup_config()
{
    echo "Setup config"

    sudo rm -f /etc/init/supervisor-config.override
    sudo rm -f /etc/init/neutron-server.override

    file_list="
        etc/ifmap-server/log4j.properties
        etc/ifmap-server/basicauthusers.properties
        etc/ifmap-server/publisher.properties
        etc/default/neutron-server
        etc/neutron/neutron.conf
        etc/neutron/plugins/opencontrail/ContrailPlugin.ini
        etc/contrail/contrail-keystone-auth.conf
        etc/contrail/contrail-api.conf
        etc/contrail/contrail-schema.conf
        etc/contrail/contrail-svc-monitor.conf
        etc/contrail/contrail-discovery.conf
        etc/contrail/contrail-device-manager.conf
        etc/contrail/ctrl-details
        etc/contrail/vnc_api_lib.ini
        etc/contrail/openstackrc"
    set_conf_list

    sudo cp -r $setup_dir/etc/contrail/supervisord_config* /etc/contrail

    file=etc/sudoers.d/contrail_sudoers
    sudo cp $setup_dir/$file /$file

    echo "Done."
}

setup_analytics()
{
    echo "Setup analytics..."

    sudo rm -f /etc/init/supervisor-analytics.override

    file_list="
        etc/redis/redis.conf
        etc/contrail/contrail-collector.conf
        etc/contrail/contrail-query-engine.conf
        etc/contrail/contrail-analytics-api.conf"
    set_conf_list

    sudo cp -r $setup_dir/etc/contrail/supervisord_analytics* /etc/contrail

    echo "Done."
}

setup_control()
{
    echo "Setup control..."

    sudo rm -f /etc/init/supervisor-control.override
    sudo rm -f /etc/init/supervisor-dns.override

    file_list="
        etc/contrail/contrail-control.conf
        etc/contrail/contrail-dns.conf"
    set_conf_list

    sudo cp -r $setup_dir/etc/contrail/dns /etc/contrail
    sudo cp -r $setup_dir/etc/contrail/supervisord_control* /etc/contrail

    echo "Done."
}

setup_webui()
{
    echo "Setup Web UI..."

    sudo rm -f /etc/init/supervisor-webui.override

    file_list="
        etc/contrail/config.global.js
        etc/contrail/contrail-webui-userauth.js"
    set_conf_list

    sudo cp -r $setup_dir/etc/contrail/supervisord_webui* /etc/contrail

    echo "Done."
}

setup_controller()
{
    disable_services
    setup_update_limits
    setup_ha
    setup_rabbitmq
    setup_database
    setup_config
    setup_analytics
    setup_control
    setup_webui

    #sudo service keepalived restart
    #sudo service haproxy restart
    #sudo service supervisor-support-service restart
    #sudo service rabbitmq-server restart
    #sudo service zookeeper restart
    #sudo service supervisor-database restart
    #sudo service supervisor-config restart
    #sudo service redis-server restart
    #sudo service supervisor-analytics restart
    #sudo service supervisor-control restart
    #sudo service supervisor-webui restart
}

update_nova()
{
    sudo sed -i \
        -e "s/^libvirt_vif_driver.*/libvirt_vif_driver = nova_contrail_vif.contrailvif.VRouterVIFDriver/" \
        -e "s/^network_api_class.*/network_api_class = nova_contrail_vif.contrailvif.ContrailNetworkAPI/" \
        -e "s/^neutron_url.*/neutron_url = http:\/\/$internal_vip:9696/" \
        /etc/nova/nova.conf
    service nova-compute restart
}

setup_compute()
{
    echo "Setup vRouter..."

    sudo rm -f /etc/init/supervisor-vrouter.override

    file_list="
        etc/contrail/agent_param
        etc/contrail/contrail-vrouter-agent.conf
        etc/contrail/ctrl-details
        etc/contrail/vrouter_nodemgr_param
        etc/contrail/rpm_agent.conf
        etc/contrail/contrail_reboot"
    set_conf_list

    file=etc/contrail/default_pmac
    sudo cat /sys/class/net/$data_dev/address > /$file

    sudo cp -r $setup_dir/etc/contrail/supervisord_vrouter* /etc/contrail

    echo "Done."
}


if [[ $1 == "controller" ]]
then
    setup_controller
elif [[ $1 == "compute" ]]
then
    setup_compute
    update_nova
elif [[ $1 == "disable-services" ]]
then
    disable_services
else
    echo "Usage: $0 controller | compute"
fi


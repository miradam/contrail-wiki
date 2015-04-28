#! /bin/bash

apt_get_install()
{
    DEBIAN_FRONTEND=noninteractive sudo apt-get -y --force-yes --allow-unauthenticated install $pkg_list
}

build_contrail_repo()
{
    echo "Build Contrail local repo..."

    mkdir -p /opt/contrail/bin

    # Unpack packages.
    mkdir -p /opt/contrail/contrail_install_repo
    cd /opt/contrail/contrail_install_repo
    tar xvzf /opt/contrail/contrail_packages/contrail_debs.tgz

    # Install packages for building local repo.
    cd /opt/contrail/contrail_install_repo
    pkg_list="
        binutils_2.24-5ubuntu3_amd64.deb
        make_3.81-8.2ubuntu3_amd64.deb
        libdpkg-perl_1.17.5ubuntu5.3_all.deb
        dpkg-dev_1.17.5ubuntu5.3_all.deb
        patch_2.7.1-4ubuntu1_amd64.deb
        python3-pycurl_7.19.3-0ubuntu3_amd64.deb
        python3-software-properties_0.92.37.1_all.deb
        software-properties-common_0.92.37.1_all.deb
        unattended-upgrades_0.82.1ubuntu2_all.deb"
    DEBIAN_FRONTEND=noninteractive sudo dpkg -i $pkg_list

    # Scan packages in local repo and create Packages.gz.
    echo "Scan packages..."
    cd /opt/contrail/contrail_install_repo
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

    # Backup origial source list and create new list with only local repo.
    cd /etc/apt/
    datetime_string=`date +%Y_%m_%d__%H_%M_%S`
    sudo cp sources.list sources.list.$datetime_string
    sudo echo "deb file:/opt/contrail/contrail_install_repo ./" > sources.list

    # Allow unauthenticated pacakges to get installed.
    # Do not over-write apt.conf. Instead just append what is necessary
    # retaining other useful configurations such as http::proxy info.
    apt_auth="APT::Get::AllowUnauthenticated \"true\";"
    if [ -f /etc/apt/apt.conf ]; then
        if sudo grep -q "$apt_auth" /etc/apt/apt.conf
        then
            sudo echo $apt_auth >> /etc/apt/apt.conf
        fi
    else
        sudo echo $apt_auth > /etc/apt/apt.conf
    fi

    # Install local repo preferences.
    sudo cp /opt/contrail/contrail_packages/preferences /etc/apt/

    sudo apt-get update
    echo "Done."
}

install_base_packages()
{
    echo "Install base packages..."

    pkg_list="
        python-pip
        python-pkg-resources
        python-setuptools
        python-crypto
        python-netaddr
        python-paramiko
        contrail-fabric-utils
        contrail-setup
        curl"
    apt_get_install

    sudo pip install --upgrade --no-deps --index-url='' /opt/contrail/python_packages/ecdsa-0.10.tar.gz
    sudo pip install --upgrade --no-deps --index-url='' /opt/contrail/python_packages/Fabric-1.7.0.tar.gz
    echo "Done."
}

disable_java_prompt()
{
    echo "Disable Java prompt..."

    echo 'sun-java6-plugin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections
    echo 'sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections
    echo 'sun-java6-jre shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections
    echo 'debconf shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections
    echo 'debconf shared/accepted-oracle-license-v1-1 seen true' | sudo debconf-set-selections
    echo "Done."
}

install_database()
{
    echo "Install database..."

    # Install the required version of tzdata.
    pkg_list="tzdata=2014e-0ubuntu0.14.04"
    apt_get_install

    sudo echo "manual" > /etc/init/supervisor-database.override
    pkg_list="contrail-openstack-database"
    apt_get_install

    echo "Done."
}

install_config()
{
    echo "Install config..."

    sudo echo "manual" > /etc/init/supervisor-config.override
    sudo echo "manual" > /etc/init/neutron-server.override
    pkg_list="contrail-openstack-config"
    apt_get_install

    echo "Done."
}

install_analytics()
{
    echo "Install analytics..."

    sudo echo "manual" > /etc/init/supervisor-analytics.override
    pkg_list="contrail-openstack-analytics"
    apt_get_install

    echo "Done."
}

install_webui()
{
    echo "Install Web UI..."

    sudo echo "manual" > /etc/init/supervisor-webui.override
    pkg_list="contrail-openstack-webui"
    apt_get_install

    echo "Done."
}

install_control()
{
    echo "Install control..."

    sudo echo "manual" > /etc/init/supervisor-control.override
    sudo echo "manual" > /etc/init/supervisor-dns.override
    pkg_list="contrail-openstack-control"
    apt_get_install

    echo "Done."
}

install_vrouter()
{
    echo "Install vRouter..."

    sudo echo "manual" > /etc/init/supervisor-vrouter.override

    pkg_list="
        libelf1=0.158-0ubuntu5.1
        kexec-tools"
    apt_get_install

    pkg_list="
        contrail-vrouter-dkms
        contrail-vrouter-common"
    apt_get_install

    echo "Done."
}


install_controller()
{
    build_contrail_repo
    install_base_packages

    disable_java_prompt
    install_database
    install_config
    install_analytics
    install_control
    install_webui
}

install_compute()
{
    build_contrail_repo
    install_base_packages

    install_vrouter
}

if [[ $1 == "controller" ]]
then
    install_controller
elif [[ $1 == "compute" ]]
then
    install_compute
else
    echo "Usage: $0 controller | compute"
fi



#
# Cookbook Name:: nsm_cookbook
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute "apt_update" do
  command "apt-get update"
end

execute "apt_dependencies" do
  command "apt-get install -y libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libmagic-dev libcap-ng-dev libjansson-dev pkg-config git python-software-properties cmake make gcc g++ flex bison libssl-dev python-dev swig libgeoip-dev libcurl4-openssl-dev"
end

# Version 2.0.8 as of 6/11/2015
remote_file "/tmp/suricata-2.0.8.tar.gz" do
  action :create
  source "http://www.openinfosecfoundation.org/download/suricata-2.0.8.tar.gz"
end

# Version 2.4 as of 6/11/2015
remote_file "/tmp/bro-2.4.tar.gz" do
  action :create
  source "https://www.bro.org/downloads/release/bro-2.4.tar.gz"
end

execute "untar_suricata" do
  command "tar -xvf suricata-2.0.8.tar.gz"
  cwd "/tmp/"
end

execute "untar_bro" do
  command "tar -xvf bro-2.4.tar.gz"
  cwd "/tmp/"
end

execute "config_suricata" do
  command "./configure --prefix=/usr/ --sysconfdir=/etc/ --localstatedir=/var/"
  cwd "/tmp/suricata-2.0.8/"
end

execute "make_suricata" do
  command "make"
  cwd "/tmp/suricata-2.0.8/"
end

execute "build_suricata" do
  command "make install-full"
  cwd "/tmp/suricata-2.0.8/"
end

# cookbook_file "suricata" do
#   path "/etc/init.d/suricata"
#   action :create
#   mode "0755"
# end

# execute "run_suricata" do
#   command "./suricata start"
#   cwd "/etc/init.d/"
# end

execute "config_bro" do
  command "./configure"
  cwd "/tmp/bro-2.4/"
end

execute "make_bro" do
  command "make"
  cwd "/tmp/bro-2.4/"
end

execute "build_bro" do
  command "make install"
  cwd "/tmp/bro-2.4/"
end

execute "config_broctl" do
  command "./broctl install"
  cwd "/usr/local/bro/bin/"
end

cookbook_file "node.cfg" do
  path "/usr/local/bro/etc/node.cfg"
  action :create
  mode "0755"
end

# cookbook_file "bro" do
#   path "/etc/init.d/bro"
#   action :create
#   mode "0755"
# end

cookbook_file "suricata.yaml" do
  path "/etc/suricata/suricata.yaml"
  action :create
  mode "0600"
end

bash "update_rc.local" do
  cwd "/etc/"
  code 'sed -i -e \'s/^exit 0$/sh suricata -D -i eth1 -c \/etc\/suricata\/suricata.yml echo "Suricata started!"\nsh \/usr\/local\/bro\/bin\/broctl start echo "Bro-IDS started!"\nexit 0/\' /etc/rc.local'
end

bash "start_bro" do
  code "/usr/local/bro/bin/broctl start"
end
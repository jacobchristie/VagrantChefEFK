#
# Cookbook Name:: elastic_cookbook
# Recipe:: ELK Stack
#
# Copyright 2015, Jacob Christie
# jacobchristie@kpmg.com
#
# All rights reserved - Do Not Redistribute
#

#package 'python-software-properties' do
#  action :install
#end

#package 'software-properties-common' do
#  action :install
#end

#execute "add_oracle_repo" do
#  command "add-apt-repository -y ppa:webupd8team/java"
#end

execute "apt_update" do
  command "apt-get update"
end

package 'git'

#Pull down JRE
package 'openjdk-7-jre-headless'

## Enable silent install
#execute "accept_oracle_license" do
#  command "echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections"
#end
#
#execute "see_oracle_license" do
#  command "echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections"
#end
#
## Moving over to Oracle Java 8
#package 'oracle-java8-installer' do
#  action :install
#end
#
#package 'oracle-java8-set-default' do
#  action :install
#end


#Set up folders
execute "build_folders" do
  command "mkdir /opt/elasticsearch/ && mkdir /opt/logstash/ && mkdir /opt/kibana/"
  cwd "/"
end

#Elasticsearch
#Version 1.5.2 as of 05/11/2015
remote_file "/tmp/elasticsearch-1.5.2.tar.gz" do
  action :create
  source "https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.5.2.tar.gz"
end

execute "extract_es" do
  command "tar xvzf elasticsearch-1.5.2.tar.gz && mv /tmp/elasticsearch-1.5.2/* /opt/elasticsearch/"
  cwd "/tmp/"
end

#
# Deprecating the use of Logstash
#
#Logstash
#Version 1.4.2 as of 05/11/2015
remote_file "/tmp/logstash-1.4.2.tar.gz" do
  action :create
  source "https://download.elastic.co/logstash/logstash/logstash-1.4.2.tar.gz"
end

execute "extract_logstash" do
  command "tar xvzf logstash-1.4.2.tar.gz && mv /tmp/logstash-1.4.2/* /opt/logstash/"
  cwd "/tmp/"
end

execute "logstash_contrib_plugins" do
  command "bin/plugin install contrib"
  cwd "/tmp/"
end

#Kibana
#Version 4.0.2 as of 05/11/2015
remote_file "/tmp/kibana-4.0.2-linux-x64.tar.gz" do
  action :create
  source "https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz"
end

#Symlink files to make:
#	a) execution of bins easier
#	b) modification of config yml's easier
execute "extract_kibana" do
  command "tar xvzf kibana-4.0.2-linux-x64.tar.gz && mv /tmp/kibana-4.0.2-linux-x64/* /opt/kibana/"
  cwd "/tmp/"
end

#execute "link elastic bin" do
#	command "ln -s /opt/elasticsearch/bin/elasticsearch /usr/bin/elasticsearch"
#end

#execute "link kibana bin" do
#	command "ln -s /opt/kibana/bin/kibana /usr/bin/kibana"
#end

execute "link elastic yml" do
	command "ln -s /opt/elasticsearch/config/elasticsearch.yml /etc/elasticsearch.yml"
end

execute "link logging yml" do
	command "ln -s /opt/elasticsearch/config/logging.yml /etc/logging.yml"
end

execute "link kibana yml" do
	command "ln -s /opt/kibana/config/kibana.yml /etc/kibana.yml"
end


#Modify config files
#Based on https://michaelkueller.wordpress.com/2012/09/27/chef-how-to-insert-or-append-a-line-to-a-file/
#File operators include:
#	insert_line_if_no_match
#	search_file_delete
#	search_file_delete_line
#	search_file_replace
#	search_file_replace_line

minMem = "4G"
maxMem = minMem
dataDir = "/data/data/"
logDir = "/data/logs/"
hostIP = node['ipaddress']

ruby_block "insert_ES_MIN" do
  block do
    file = Chef::Util::FileEdit.new("/etc/elasticsearch.yml")
    file.insert_line_if_no_match("/ES_MIN_MEM/", "ES_MIN_MEM: #{minMem}")
    file.write_file
  end
end

ruby_block "insert_ES_MAX" do
  block do
    file = Chef::Util::FileEdit.new("/etc/elasticsearch.yml")
    file.insert_line_if_no_match("/ES_MAX_MEM/", "ES_MAX_MEM: #{maxMem}")
    file.write_file
  end
end

ruby_block "update_Data_Dir" do
  block do
    file = Chef::Util::FileEdit.new("/etc/elasticsearch.yml")
    file.insert_line_if_no_match("/path.data:\ \/path\/to\/data$/", "path.data: #{dataDir}")
    file.write_file
  end
end

ruby_block "update_Log_Dir" do
  block do
    file = Chef::Util::FileEdit.new("/etc/elasticsearch.yml")
    file.insert_line_if_no_match("/path.data:\ \/path\/to\/logs$/", "path.logs: #{logDir}")
    file.write_file
  end
end

ruby_block "update_kibana_host" do
  block do
    file = Chef::Util::FileEdit.new("/etc/kibana.yml")
    file.insert_line_if_no_match("/host:\ \"0\.0\.0\.0\"$/", "host: \"#{hostIP}\"")
    file.write_file
  end
end

cookbook_file "elasticsearch" do
  path "/etc/init.d/elasticsearch"
  action :create
  mode "0755"
end

cookbook_file "kibana" do
  path "/etc/init.d/kibana"
  action :create
  mode "0755"
end

bash "update_rc.local" do
  cwd "/etc/"
  code 'sed -i -e \'s/^exit 0$/sh \/etc\/init.d\/elasticsearch start echo "Elasticsearch started!"\nsh \/etc\/init.d\/kibana start echo "Kiabana started!"\nexit 0/\' /etc/rc.local'
end

####
# Bring up ES and Kibana
####
execute "es_up" do
	command "/etc/init.d/elasticsearch start"
end

execute "kibana_up" do
	command "/etc/init.d/kibana start"
end

# Copy over any ES index templates
remote_directory "templates" do
  path "/home/vagrant/templates/"
  action :create_if_missing
end

execute "make_logstash_conf_dirs" do
  command "mkdir /etc/logstash/"
end

# Copy over Logstash confs
remote_directory "logstash_conf" do
  path "/etc/logstash/"
  action :create_if_missing
end

execute "curl_templates" do
  command "for i in *.json; do curl -s -XPOST localhost:9200/_template/template-$i -d @$i &> /dev/null; done"
  cwd "/home/vagrant/templates/"
end

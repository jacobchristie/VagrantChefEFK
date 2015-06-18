#
# Cookbook Name:: fluentd_ui_cookbook
# Recipe:: Fluentd Agent and UI
#
# Copyright 2015, Jacob Christie
# jacobchristie@kpmg.com
#
# All rights reserved - Do Not Redistribute
#

execute "apt_update" do
  command "apt-get update"
end

execute "apt_install_packages" do
  command "apt-get install -y build-essential libssl-dev ruby-dev git"
end

execute "change-hard-file" do
  command "echo 'root hard nofile 65536' >> /etc/security/limits.conf"
end

execute "change-soft-file" do
  command "echo 'root soft nofile 65536' >> /etc/security/limits.conf"
end

execute "change-hard-file2" do
  command "echo '* hard nofile 65536' >> /etc/security/limits.conf"
end

execute "change-soft-file2" do
  command "echo '* soft nofile 65536' >> /etc/security/limits.conf"
end

execute "install_bundler" do
  command "gem install bundler"
end

execute "download_td_agent" do
  command "curl -L https://td-toolbelt.herokuapp.com/sh/install-debian-wheezy-td-agent2.sh | sh"
end

execute "pull_fluentd_plugin_reformer" do
  command "/opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-record-reformer"
end

execute "pull_fluentd_plugin_modifier" do
  command "/opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-record-modifier"
end

execute "pull_fluentd_plugin_es" do
  command "/opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-elasticsearch"
end

execute "pull_fluentd_plugin_rewrite" do
  command "/opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-rewrite"
end

execute "pull_fluentd_plugin_exclude" do
  command "/opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-exclude-filter"
end

#install and run with rake instead
#execute "download_fluentd_ui" do
#  command "gem install -V fluentd-ui"
#end

execute "git_fluentd-ui" do
  command "git clone https://github.com/treasure-data/fluentd-ui"
  cwd "/opt/"
end

execute "install_fluentd-ui" do
  command "bundle install"
  cwd "/opt/fluentd-ui/"
end

cookbook_file "fluentdui" do
  path "/etc/init.d/fluentdui"
  action :create
  mode "0755"
end

#Move over base l2t conf file
cookbook_file "td-agent.conf" do
  path "/etc/td-agent/td-agent.conf"
  action :create
end

bash "update_rc.local" do
  cwd "/etc/"
  code 'sed -i -e \'s/^exit 0$/sh \/etc\/init.d\/fluentdui start echo "Fluentd-UI started!"\nexit 0/\' /etc/rc.local'
end

execute "start_fluentd_ui" do
  command "bundle exec rails s -b 0.0.0.0 -p 9292 -d"
  cwd "/opt/fluentd-ui/"
end
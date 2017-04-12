
unless node['k8s']['airgap_install']
	# Presumably your airgap installation will have its own
	# definition of yum repositories.
	# You may define those in your own cookbook before running
	# this cookbook
	include_recipe "#{cookbook_name}::_kube_repos"
end

package "docker-engine" do
	version "1.11.2-1.el7.centos"
	action :install
	notifies :restart, "service[docker]", :delayed
end

template "/usr/lib/systemd/system/docker.service" do
	source "systemd/docker.service.erb"
	mode "0644"
	group "root"
	owner "root"
	notifies :run, "execute[reload systemctl]", :immediately
end

execute "reload systemctl" do
	command "systemctl daemon-reload"
	action :nothing
end

service "docker" do
	action [ :enable, :start ]
end

unless node['k8s']['airgap_install']
	# Presumably your airgap installation will have its own
	# definition of yum repositories.
	# You may define those in your own cookbook before running
	# this cookbook
	include_recipe "#{cookbook_name}::_kube_repos"
end

package "docker-engine" do
	version "1.12.6-1.el7.centos"
	action :install
	notifies :restart, "service[docker]", :immediately
end

execute "reload systemctl" do
	command "systemctl daemon-reload"
	action :nothing
end

service "docker" do
	action [ :enable, :start ]
end	

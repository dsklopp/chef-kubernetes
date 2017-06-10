include_recipe "#{cookbook_name}::_kube_docker"

[ 	
	"/etc/kubernetes", 
	"/etc/kubernetes/manifests", 
	"/etc/kubernetes/ssl", 
	"/etc/cni/", 
	"/etc/cni/net.d/",
	"/opt/cni", 
	"/opt/cni/bin" ].each do |dir|
	directory dir do
		owner 'root'
		group 'root'
		mode '0755'
	end
end

if node['k8s']['airgap_install']
	include_recipe "#{cookbook_name}::_install_airgap"
	package "bridge-utils"
	package "bcf-cni"
	# We will replace this with our own version
	file "/lib/systemd/system/bcf-agent-etcd.service" do
		action :delete
	end
else
	include_recipe "#{cookbook_name}::_install"
	package "bridge-utils"
end

execute "systemctl daemon-reload" do
	command "systemctl daemon-reload"
	action :nothing
end

template "/etc/systemd/system/kube-proxy.service" do
	source "systemd/kube-proxy.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:master => node['k8s']['masters']['cname'],
		:image => node['k8s']['images']['kube-proxy'],
		:service_cidr => node['k8s']['service_network']['cidr']
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

if node['k8s']['sdn']['solution'] == "bcf"
	include_recipe "#{cookbook_name}::_sdn_bsn"
elsif node['k8s']['sdn']['solution'] == "flannel"
	include_recipe "#{cookbook_name}::_sdn_flannel"
else
	Chef::Application.fatal("Unknown SDN solution " + node['k8s']['sdn']['solution'])
end


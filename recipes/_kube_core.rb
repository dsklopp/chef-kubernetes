include_recipe "#{cookbook_name}::_kube_docker"
include_recipe "sysctl::default"

sysctl_param "net.bridge.bridge-nf-call-iptables" do
	value 1
end

sysctl_param "net.bridge.bridge-nf-call-ip6tables" do
	value 1
end

sysctl_param "net.bridge.bridge-nf-call-arptables" do
	value 1
end

sysctl_param "kernel.sem" do
	value "250 32000 32 256"
end

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

# Implementing service tokens, auth, and ssl
# By default disabled until properly tested
if node['k8s']['new_features']
	template "/etc/kubernetes/admin.conf" do
		source "configs/generic.conf.erb"
		mode "0644"
		group "root"
		owner "root"
		variables ({
			:email => "kubernetes-admin@kubernetes",
			:user => "kubernetes-admin",
			:master_cname => "https://#{node['k8s']['masters']['cname']}:6443",
			:cert_auth_data => "asdf",
			:client_cert_data => "asdf",
			:client_key_data => "asdf"
			})
	end
	template "/etc/kubernetes/scheduler.conf" do
		source "configs/generic.conf.erb"
		mode "0644"
		group "root"
		owner "root"
		variables ({
			:email => "system:kube-scheduler@kubernetes",
			:user => "system:kube-scheduler",
			:master_cname => "https://#{node['k8s']['masters']['cname']}:6443",
			:cert_auth_data => "asdf",
			:client_cert_data => "asdf",
			:client_key_data => "asdf"
			})
	end
	template "/etc/kubernetes/kubelet.conf" do
		source "configs/generic.conf.erb"
		mode "0644"
		group "root"
		owner "root"
		variables ({
			:email => "system:node:k8s-master@kubernetes",
			:user => "system:node:k8s-master",
			:master_cname => "https://#{node['k8s']['masters']['cname']}:6443",
			:cert_auth_data => "asdf",
			:client_cert_data => "asdf",
			:client_key_data => "asdf"
			})
	end
	template "/etc/kubernetes/controller-manager.conf" do
		source "configs/generic.conf.erb"
		mode "0644"
		group "root"
		owner "root"
		variables ({
			:email => "system:kube-controller-manager@kubernetes",
			:user => "system:kube-controller-manager",
			:master_cname => "https://#{node['k8s']['masters']['cname']}:6443",
			:cert_auth_data => "asdf",
			:client_cert_data => "asdf",
			:client_key_data => "asdf"
			})
	end
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


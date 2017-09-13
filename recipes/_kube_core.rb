include_recipe "#{cookbook_name}::_kube_docker"
include_recipe "sysctl::default"

template "/etc/sysctl.d/01-kubernetes.conf" do
	source "sysctl/01-kubernetes.conf"
	group "root"
	owner "root"
	mode 0644
	notifies :run, 'execute[reload sysctl]', :immediately
end

execute "reload sysctl" do
	command "sysctl --system"
	action :nothing
end

template "/etc/security/limits.d/kubernetes.conf" do
	source "sysconfig/kubernetes.conf.erb"
	owner "root"
	group "root"
	mode 0644
end

service "NetworkManager" do
	action [ :disable, :stop ]
end

[ 	
	"/etc/kubernetes", 
	"/etc/kubernetes/manifests", 
	"/etc/kubernetes/pki", 
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
	package "bcf-cni" do
		action :upgrade
	end
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
			:cert_auth => "/etc/kubernetes/pki/ca.crt",
			:client_cert => "/etc/kubernetes/pki/kubernetes-admin.crt",
			:client_key => "/etc/kubernetes/pki/kubernetes-admin.key"
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
			:cert_auth => "/etc/kubernetes/pki/ca.crt",
			:client_cert => "/etc/kubernetes/pki/kube-scheduler.crt",
			:client_key => "/etc/kubernetes/pki/kube-scheduler.key"
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
			:cert_auth => "/etc/kubernetes/pki/ca.crt",
			:client_cert => "/etc/kubernetes/pki/k8s-master.crt",
			:client_key => "/etc/kubernetes/pki/k8s-master.key"
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
			:cert_auth => "/etc/kubernetes/pki/ca.crt",
			:client_cert => "/etc/kubernetes/pki/kube-controller-manager.crt",
			:client_key => "/etc/kubernetes/pki/kube-controller-manager.key"
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


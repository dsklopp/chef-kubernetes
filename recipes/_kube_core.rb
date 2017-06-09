include_recipe "#{cookbook_name}::_kube_docker"

bcf_etcd_masters=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	bcf_etcd_masters += server['ip']['node-port'] + ":9121,"
end
bcf_etcd_masters.chomp(',')

master_ips=[]
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	master_ips << server['ip']['node-port']
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

dl_url = node['k8s']['kube-binaries']['url']
cni_dl_url = node['k8s']['cni-binaries']['url']
k8s_version = node['k8s']['kubernetes']['version']
cni_version = node['k8s']['cni-binaries']['version']

if node['k8s']['airgap_install']
	[ 	
		"kubelet", 
		"kubeadm",
		"kubectl",
		"kube-proxy" ].each do |binary|
		remote_file "/usr/bin/#{binary}" do
			source "#{dl_url}/#{k8s_version}/#{binary}"
			owner "root"
			group "root"
			mode "0755"
			action :create
		end
	end
	[ "bridge", "cnitool", "dhcp", "flannel", "host-local", "ipvlan",
		"loopback", "macvlan", "noop", "ptp", "tuning" ].each do |binary|
		remote_file "/opt/cni/bin/#{binary}" do
			source "#{cni_dl_url}/#{cni_version}/#{binary}"
			owner "root"
			group "root"
			mode "0755"
			action :create
		end
	end
else
	directory "/tmp/cni" do
		action :create
	end
	remote_file "/opt/kubernetes-server-linux-amd64-#{k8s_version}.tar.gz" do
		source "https://dl.k8s.io/v#{k8s_version}/kubernetes-server-linux-amd64.tar.gz"
		owner "root"
		group "root"
		action :create
		notifies :run, 'execute[extract k8s tools]', :immediately
	end
	execute "extract k8s tools" do
		command "tar -xf /opt/kubernetes-server-linux-amd64-#{k8s_version}.tar.gz -C /tmp/"
		action :nothing
	end
	[ 	
		"kubelet", 
		"kubeadm",
		"kubectl",
		"kube-proxy" ].each do |binary|
		remote_file "/usr/bin/#{binary}" do
			source "file:///tmp/kubernetes/server/bin/#{binary}"
			owner "root"
			group "root"
			mode "0755"
			action :create
		end
	end
	remote_file "/opt/cni-amd64-v#{cni_version}.tgz" do
		source "https://github.com/containernetworking/cni/releases/download/v#{cni_version}/cni-amd64-v#{cni_version}.tgz"
		owner "root"
		group "root"
		action :create
		notifies :run, 'execute[extract cni plugins]', :immediately
	end

	execute "extract cni plugins" do
		command "tar -xf /opt/cni-amd64-v#{cni_version}.tgz -C /tmp/cni"
		action :nothing
	end
	[ "bridge", "cnitool", "dhcp", "flannel", "host-local", "ipvlan",
		"loopback", "macvlan", "noop", "ptp", "tuning" ].each do |binary|
		remote_file "/opt/cni/bin/#{binary}" do
			source "file:///tmp/cni/#{binary}"
			owner "root"
			group "root"
			mode "0755"
			action :create
		end
	end
end

package "bridge-utils"
package "bcf-cni"

# We will replace this with our own version
file "/lib/systemd/system/bcf-agent-etcd.service" do
	action :delete
end

# This only runs on masters but needs to run on agents too
# Suggest moving kubelet version to master
# Keep kube-proxy service in kubernetes workers
#template "/etc/kubernetes/manifests/kube-proxy.yaml" do
#	owner 'root'
#	group 'root'
#	mode '0644'
#	source "manifests/kube-proxy.yaml.erb"
#	variables ({
#		:image => node['k8s']['images']['kube-proxy'],
#		:master => node['k8s']['masters']['ipaddr']['kube-master-1'],
#		:service_cidr => node['k8s']['service_network']['cidr']
#		})
#end

template "/etc/cni/net.d/bcf.conf" do
	source "sdn/bcf.conf.erb"
	group "root"
	owner "root"
	mode "0644"
	variables({
		:etcd_masters => bcf_etcd_masters
		})
end

execute "systemctl daemon-reload" do
	command "systemctl daemon-reload"
	action :nothing
end

template "/etc/sysconfig/ivs" do
	source "sysconfig/ivs-client.erb"
	mode "0644"
	owner "root"
	group "root"
	variables({
		:interfaces => node['k8s']['sdn']['interfaces']
		})
end

template "/etc/sysconfig/network-scripts/ifcfg-node-port" do
	source "sysconfig/ifcfg-node-port.erb"
	mode "0644"
	owner "root"
	group "root"
	variables ({
		:ipaddr => node['k8s']['nodes'][node['macaddress']]['ip']['node-port'],
		:netmask => node['k8s']['node-ports']['netmask']
		})
end

execute "create route table node-port" do
	command 'echo "1 node-port" >> /etc/iproute2/rt_tables'
end

template "/etc/sysconfig/network-scripts/rule-node-port" do
	source "sysconfig/rule-node-port.erb"
	owner "root"
	group "root"
	mode "0755"
	variables ({
		:ipaddr => node['k8s']['nodes'][node['macaddress']]['ip']['node-port']
		})
end

template "/etc/sysconfig/network-scripts/route-node-port" do
	source "sysconfig/route-node-port.erb"
	owner "root"
	group "root"
	mode "0755"
	variables({
		:ipaddr => node['k8s']['nodes'][node['macaddress']]['ip']['node-port'],
		:k8s_cidr => node['k8s']['node-ports']['cidr'],
		:k8s_default_gw => node['k8s']['node-ports']['gw']
		})
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

template "/etc/bcf-agent.yaml" do
	source "sdn/bcf-agent.yaml.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:masters => master_ips
		})
end


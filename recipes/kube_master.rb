include_recipe "#{cookbook_name}::_kube_core"

bcf_etcd_connect=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	bcf_etcd_connect += server['hostname'] + "=http://" + server['ip']['node-port']
	bcf_etcd_connect += ":9122,"
end
bcf_etcd_connect.chomp(',')

etcd_connect_2380=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	etcd_connect_2380 += server['hostname'] + "=http://" + server['ip']['node-port']
	etcd_connect_2380 += ":2380,"
end
etcd_connect_2380.chomp(',')

etcd_connect_2379=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	etcd_connect_2379 += "http://" + server['ip']['node-port']
	etcd_connect_2379 += ":2379,"
end
etcd_connect_2379.chomp(',')


etcd_connect_2381=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	etcd_connect_2381 += server['hostname'] + "=http://" + server['ip']['node-port']
	etcd_connect_2381 += ":2381,"
end
etcd_connect_2381.chomp(',')

etcd_connect_2378=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	etcd_connect_2378 += "etcd://" + server['ip']['node-port']
	etcd_connect_2378 += ":2378,"
end
etcd_connect_2378.chomp(',').chomp(',')

masters=[]
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	masters << server['ip']['node-port']
end
masters.sort!

execute "pull docker etcd" do
	command "docker pull #{node['k8s']['images']['etcd']}"
end

if node['k8s']['sdn']['solution'] == "bcf"
	template "/etc/systemd/system/bcf-etcd.service" do
		if node['k8s']['new_features']
			source "systemd/bcf-etcd-new.service.erb"
		else
			source "systemd/bcf-etcd.service.erb"
		end
		owner "root"
		group "root"
		mode "0644"
		variables({
			:etcd_image => node['k8s']['images']['etcd'],
			:hostname => node['k8s']['nodes'][node['k8s']['macaddress']]['hostname'],
			:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
			:kube_masters => bcf_etcd_connect
			})
		notifies :run, 'execute[systemctl daemon-reload]', :immediately
	end
end

template "/etc/systemd/system/etcd.service" do
	if node['k8s']['new_features']
		source "systemd/etcd-new.service.erb"
	else
		source "systemd/etcd.service.erb"
	end
	owner "root"
	group "root"
	mode "0644"
	variables({
		:etcd_image => node['k8s']['images']['etcd'],
		:hostname => node['k8s']['nodes'][node['k8s']['macaddress']]['hostname'],
		:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
		:kube_masters => etcd_connect_2380
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

if node['k8s']['storage']['solution'] == "pwx"
	template "/etc/systemd/system/pwx-etcd.service" do
		source "systemd/pwx-etcd.service.erb"
		owner "root"
		group "root"
		mode "0644"
		variables({
			:etcd_image => node['k8s']['images']['etcd-pwx'],
			:image_pwx_init => node['k8s']['images']['etcd-pwx-init'],
			:image_pwx_enterprise => node['k8s']['images']['etcd-pwx-enterprise'],
			:hostname => node['k8s']['nodes'][node['k8s']['macaddress']]['hostname'],
			:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
			:kube_masters => etcd_connect_2381
			})
		notifies :run, 'execute[systemctl daemon-reload]', :immediately
	end
	service "pwx-etcd" do
		action [ :enable, :start ]
	end
	template "/etc/kubernetes/portworx.yaml" do
		source "manifests/portworx.yaml.erb"
		owner "root"
		group "root"
		mode "0644"
		variables({
			:image_pwx_enterprise => node['k8s']['images']['pwx-enterprise'],
			:image_pwx_init => node['k8s']['images']['pwx-init'],
			:hostname => node['k8s']['nodes'][node['k8s']['macaddress']]['hostname'],
			:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
			:kube_masters => etcd_connect_2378,
			:mgmt_interface => node['k8s']['key_interface']
			})
		notifies :run, 'execute[systemctl daemon-reload]', :immediately
	end
end
service "etcd" do
	action [ :enable, :start ]
end

if node['k8s']['sdn']['solution'] == "bcf"
	service "bcf-etcd" do
		action [ :enable, :start ]
	end
end

server_hostnames=[]
node['k8s']['nodes'].each do |mac, server|
	server_hostnames << server['hostname']
end

master_ips=[]
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	master_ips << server['ip']['node-port']
end

template "/etc/bcf-config.yaml" do
	source "sdn/bcf-config.yaml.erb"
	group "root"
	owner "root"
	mode "0644"
	variables({
		:masters => master_ips,
		:bcf_controller_ip => node['k8s']['sdn']['bcf_controller_ip'],
		:tenant => node['k8s']['sdn']['bcf']['tenant'],
		:service_cidr => node['k8s']['service_network']['cidr'],
		:password => node['k8s']['sdn']['bcf_password'],
		:user => node['k8s']['sdn']['bcf_username'],
		:network_kube_system => node['k8s']['sdn']['bcf']['networks']['kube-system'],
		:network_default => node['k8s']['sdn']['bcf']['networks']['default'],
		:network_nodes => node['k8s']['sdn']['bcf']['networks']['nodes'],
		:network_extra => node['k8s']['sdn']['bcf']['networks']['extra'],
		:server_hostnames => server_hostnames
		})
end

template "/etc/kubernetes/manifests/kube-apiserver.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	if node['k8s']['new_features']
		source "manifests/kube-apiserver-new.yaml.erb"
	else
		source "manifests/kube-apiserver.yaml.erb"
	end
	if node['k8s']['new_features']
	variables ({
		:image => node['k8s']['images']['kube-apiserver'],
		:port => 6443,
		:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
		:etcd_servers => etcd_connect_2379,
		:cluster_ip_range => node['k8s']['service_network']['cidr'],
		:kubemaster_cname => node['k8s']['masters']['cname']
		})
	else
	variables ({
		:image => node['k8s']['images']['kube-apiserver'],
		:port => 8080,
		:etcd_servers => etcd_connect_2379,
		:cluster_ip_range => node['k8s']['service_network']['cidr'],
		:kubemaster_cname => node['k8s']['masters']['cname']
		})
	end
end
template "/etc/kubernetes/manifests/kube-scheduler.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	if node['k8s']['new_features']
		source "manifests/kube-scheduler-new.yaml.erb"
		variables ({
			:image => node['k8s']['images']['kube-scheduler'],
			:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
			:master => "127.0.0.1"
		})
	else
		source "manifests/kube-scheduler.yaml.erb"
		variables ({
			:image => node['k8s']['images']['kube-scheduler'],
			:master => "127.0.0.1"
		})
	end
	
end

template "/etc/kubernetes/manifests/kube-controller-manager.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	if node['k8s']['new_features']
		source "manifests/kube-controller-manager-new.yaml.erb"
		variables ({
			:image => node['k8s']['images']['kube-controller'],
			:master => "127.0.0.1",
			:ipaddr => node['k8s']['nodes'][node['k8s']['macaddress']]['ip']['node-port'],
			:cluster_name => node['k8s']['cluster_name']
		})
	else
		source "manifests/kube-controller-manager.yaml.erb"
		variables ({
			:image => node['k8s']['images']['kube-controller'],
			:master => "127.0.0.1",
			:cluster_name => node['k8s']['cluster_name']
		})
	end
end

template "/etc/systemd/system/kubelet.service" do
	owner "root"
	group "root"
	mode "0644"
	if node['k8s']['new_features']
		source "systemd/kubelet-master-new.service.erb"
	else
		source "systemd/kubelet-master.service.erb"
	end
	variables({
		:pod_infra_container_image => node['k8s']['images']['pod_infra_container_image'],
		:cluster_domain => node['k8s']['dns_service']['domain'],
		:cluster_dns_server => node['k8s']['dns_service']['ip']
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
	notifies :restart, 'service[kubelet]', :delayed
end

service "kubelet" do
	action [ :enable, :start ]
end

if node['k8s']['sdn']['solution'] == "bcf"
	service "bcf-agent" do
		action [ :enable, :start ]
	end
end

# Install daemonsets if the primary master
template "/etc/kubernetes/kube-proxy.yaml" do
	source "daemonsets/kube-proxy.yaml.erb"
	owner "root"
	group "root"
	mode "0644"
	variables ({
		:image => node['k8s']['images']['kube-proxy'],
		:master => node['k8s']['masters']['cname']
	})
end

#execute "kubectl apply kube-proxy.yaml" do
#	command "kubectl apply -f /etc/kubernetes/kube-proxy.yaml"
#	only_if { node['k8s']['nodes'][node.k8s.macaddress]['node-port'] == masters[0] } # only run on one node
#end 

service "kube-proxy" do
	action [ :enable, :start]
end

template "/etc/kubernetes/coredns.yaml" do
	source "manifests/coredns.yaml.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:api_server_host => node['k8s']['nodes'][node['macaddress']]['ip']['node-port'],
		:coredns_image => node['k8s']['images']['coredns']
		})
end

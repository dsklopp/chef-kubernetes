include_recipe "#{cookbook_name}::_kube_core"

master1=node['k8s']['masters']['ipaddr']['kube-master-1']
master2=node['k8s']['masters']['ipaddr']['kube-master-2']
master3=node['k8s']['masters']['ipaddr']['kube-master-3']

execute "pull docker etcd" do
	command "docker pull #{node['k8s']['images']['etcd']}"
end

template "/etc/systemd/system/bcf-etcd.service" do
	source "systemd/bcf-etcd.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:etcd_image => node['k8s']['images']['etcd'],
		:hostname => node['k8s']['hostname'][node['macaddress']],
		:ipaddr => node['k8s']['node-ports'][node['macaddress']],
		:kube_masters => "kube-master-1=http://#{master1}:9122,kube-master-2=http://#{master2}:9122,kube-master-3=http://#{master3}:9122"
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end
template "/etc/systemd/system/etcd.service" do
	source "systemd/etcd.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:etcd_image => node['k8s']['images']['etcd'],
		:hostname => node['k8s']['hostname'][node['macaddress']],
		:ipaddr => node['k8s']['node-ports'][node['macaddress']],
		:kube_masters => "kube-master-1=http://#{master1}:2380,kube-master-2=http://#{master2}:2380,kube-master-3=http://#{master3}:2380"
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

service "etcd" do
	action [ :enable, :start ]
end
service "bcf-etcd" do
	action [ :enable, :start ]
end

server_hostnames=[]
node['k8s']['hostname'].each do |mac, hostname|
	server_hostnames << hostname
end

template "/etc/bcf-config.yaml" do
	source "sdn/bcf-config.yaml.erb"
	group "root"
	owner "root"
	mode "0644"
	variables({
		:master1 => master1,
		:master2 => master2,
		:master3 => master3,
		:bcf_controller_ip => node['k8s']['sdn']['bcf_controller_ip'],
		:service_cidr => node['k8s']['service_network']['cidr'],
		:password => node['k8s']['sdn']['bcf_password'],
		:user => node['k8s']['sdn']['bcf_username'],
		:network_kube_system => node['k8s']['sdn']['bcf']['networks']['kube-system'],
		:network_default => node['k8s']['sdn']['bcf']['networks']['default'],
		:network_nodes => node['k8s']['sdn']['bcf']['networks']['nodes'],
		:server_hostnames => server_hostnames
		})
end

template "/etc/bcf-agent.yaml" do
	source "sdn/bcf-agent.yaml.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:master1 => master1,
		:master2 => master2,
		:master3 => master3
		})
end

template "/etc/kubernetes/manifests/kube-apiserver.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	source "manifests/kube-apiserver.yaml.erb"
	variables ({
		:image => node['k8s']['images']['kube-apiserver'],
		:port => 8080,
		:kubelet_port => 10250,
		:etcd_servers => "http://#{master1}:2379,http://#{master2}:2379,http://#{master3}:2379",
		:cluster_ip_range => node['k8s']['service_network']['cidr'],
		:kubemaster_cname => node['k8s']['masters']['cname']
		})
end
template "/etc/kubernetes/manifests/kube-scheduler.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	source "manifests/kube-scheduler.yaml.erb"
	variables ({
		:image => node['k8s']['images']['kube-scheduler'],
		:master => "127.0.0.1"
		})
end

template "/etc/kubernetes/manifests/kube-controller-manager.yaml" do
	owner 'root'
	group 'root'
	mode '0644'
	source "manifests/kube-controller-manager.yaml.erb"
	variables ({
		:image => node['k8s']['images']['kube-controller'],
		:master => "127.0.0.1",
		:cluster_name => "veda-kube"
		})
end

template "/etc/systemd/system/kubelet.service" do
	source "systemd/kubelet-master.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:pod_infra_container_image => node['k8s']['images']['pod_infra_container_image']
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end


service "kubelet" do
	action [ :enable, :start ]
end

service "bcf-agent" do
	action [ :enable, :start ]
end

service "kube-proxy" do
	action [ :enable, :start]
end

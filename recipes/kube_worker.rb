include_recipe "#{cookbook_name}::_kube_core"

api_servers=""
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	if node['k8s']['new_features']
		api_servers += "http://" + server['ip']['node-port'] + ":6443,"
	else
		api_servers += "http://" + server['ip']['node-port'] + ":8080,"
	end
end
api_servers.chomp(',')

template "/etc/systemd/system/kubelet.service" do
	source "systemd/kubelet-agent.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:pod_infra_container_image => node['k8s']['images']['pod_infra_container_image'],
		:api_servers => api_servers,
		:cluster_domain => node['k8s']['dns_service']['domain'],
		:cluster_dns_server => node['k8s']['dns_service']['ip']
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
	notifies :restart, 'service[kubelet]', :delayed
end

service "kubelet" do
	action [ :enable, :start]
end

service "kube-proxy" do
	action [ :enable, :start]
end

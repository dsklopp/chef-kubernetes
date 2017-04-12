include_recipe "#{cookbook_name}::_kube_core"

master1=node['k8s']['masters']['ipaddr']['kube-master-1']
master2=node['k8s']['masters']['ipaddr']['kube-master-2']
master3=node['k8s']['masters']['ipaddr']['kube-master-3']

template "/etc/cni/net.d/bcf.conf" do
	source "sdn/bcf.conf.erb"
	group "root"
	owner "root"
	mode "0644"
	variables({
		:master1 => master1,
		:master2 => master2,
		:master3 => master3
		})
end

template "/etc/systemd/system/kubelet.service" do
	source "systemd/kubelet-agent.service.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:pod_infra_container_image => node['k8s']['images']['pod_infra_container_image'],
		:api_servers => "http://#{master1}:8080,http://#{master2}:8080,http://#{master3}:8080"
		})
	notifies :run, 'execute[systemctl daemon-reload]', :immediately
end



service "kubelet" do
	action [ :enable, :start]
end
service "kube-proxy" do
	action [ :enable, :start]
end
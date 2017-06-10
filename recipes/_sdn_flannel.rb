master_ips=[]
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	master_ips << server['ip']['node-port']
end

template "/etc/kubernetes/kube-flannel.yml" do
	source "kube-flannel.yml.erb"
	owner "root"
	group "root"
	mode "0644"
end

template "/etc/kubernetes/kube-flannel-rbac.yml" do
	source "kube-flannel-rbac.yml.erb"
	owner "root"
	group "root"
	mode "0644"
end
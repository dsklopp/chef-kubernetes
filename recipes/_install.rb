dl_url = node['k8s']['kube-binaries']['url']
cni_dl_url = node['k8s']['cni-binaries']['url']
k8s_version = node['k8s']['kubernetes']['version']
cni_version = node['k8s']['cni-binaries']['version']


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
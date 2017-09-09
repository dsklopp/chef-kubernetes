dl_url = node['k8s']['kube-binaries']['url']
cni_dl_url = node['k8s']['cni-binaries']['url']
k8s_version = node['k8s']['kubernetes']['version']
cni_version = node['k8s']['cni-binaries']['version']

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
if cni_version == "0.6.0"
	[ "cnitool", "noop" ].each do |binary|
		remote_file "/opt/cni/bin/#{binary}" do
			source "#{cni_dl_url}/#{cni_version}/#{binary}"
			owner "root"
			group "root"
			mode "0755"
			action :create
		end
	end
else
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
end

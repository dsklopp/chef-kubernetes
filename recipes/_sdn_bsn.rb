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

template "/etc/cni/net.d/bcf.conf" do
	source "sdn/bcf.conf.erb"
	group "root"
	owner "root"
	mode "0644"
	variables({
		:etcd_masters => bcf_etcd_masters
		})
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
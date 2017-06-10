master_ips=[]
node['k8s']['nodes'].each do |mac, server|
	next unless server['master']
	master_ips << server['ip']['node-port']
end


default['k8s']['macaddress']=node['macaddress']
default['k8s']['airgap_install']=false

default['k8s']['storage']['solution']="default"

default['k8s']['sdn']['interfaces']="-u eno2 -u eno3"
default['k8s']['sdn']['netmask']="255.255.252.0"

default['k8s']['yum_repos']['purge_old'] = true

default['k8s']['sdn']['solution']="flannel" # select bcf for BigSwitch
# Flannel specific settings
default['k8s']['sdn']['flannel']

# BCF specific settings
default['k8s']['sdn']['bcf_controller_ip']='10.1.1.2'
default['k8s']['sdn']['bcf_password']='123123123'
default['k8s']['sdn']['bcf_username']='admin'
default['k8s']['sdn']['bcf']['networks']['kube-system']='10.1.2.1/24'
default['k8s']['sdn']['bcf']['networks']['default']='10.1.4.1/23'
default['k8s']['sdn']['bcf']['networks']['nodes']='10.1.3.1/24'
default['k8s']['sdn']['bcf']['networks']['extra']=[]
default['k8s']['sdn']['bcf']['tenant']='Kubernetes'

# To leverage the URL you must enable node['k8s']['airgap_install']
# Inhouse we point it to an HTTP endpoint of an Artifactory repository
default['k8s']['kube-binaries']['url']=""
default['k8s']['kubernetes']['version']='1.5.6'
default['k8s']['cni-binaries']['url']=""
default['k8s']['cni-binaries']['version']='0.5.2'

default['k8s']['masters']['cname']='kube-master'

default['k8s']['images'].tap do |image|
	image['etcd'] = "quay.io/coreos/etcd:v3.1.5"
	image['etcd-pwx'] = "quay.io/coreos/etcd"
	image['kube-apiserver'] = "gcr.io/google_containers/kube-apiserver-amd64:v1.5.6"
	image['kube-proxy'] = "gcr.io/google_containers/kube-proxy-amd64:v1.5.6"
	image['kube-scheduler']="gcr.io/google_containers/kube-scheduler-amd64:v1.5.6"
	image['kube-controller']="gcr.io/google_containers/kube-controller-manager-amd64:v1.5.6"
	image['pod_infra_container_image'] = "gcr.io/google_containers/pause:0.8.0"
end

default['k8s']['node-ports']['netmask']='255.255.255.0'
default['k8s']['node-ports']['cidr']='10.1.3.1/24'
default['k8s']['node-ports']['gw']='10.1.3.1'

default['k8s']['service_network']['netmask']='16'
default['k8s']['service_network']['network']='10.255.0.1'
default['k8s']['service_network']['cidr']='10.255.0.1/16'
default['k8s']['nodes'].default = {
	'ip': {
		'node-port': '192.168.1.1'
	},
	'master': false,
	'worker': true,
	'hostname': 'unspecified'
}
default['k8s']['nodes']['08:00:27:8F:EF:23'].tap do |server|
	server['ip']['node-port']='192.168.7.10'
	server['master']=true
	server['worker']=false
	server['hostname']='kube-master-1'
end
default['k8s']['nodes']['01:23:45:67:89:AC'].tap do |server|
	server['ip']['node-port']='192.168.7.11'
	server['master']=true
	server['worker']=false
	server['hostname']='kube-master-2'
end
default['k8s']['nodes']['01:23:45:67:89:AD'].tap do |server|
	server['ip']['node-port']='192.168.7.12'
	server['master']=true
	server['worker']=false
	server['hostname']='kube-master-3'
end
default['k8s']['nodes']['01:23:45:67:89:AE'].tap do |server|
	server['ip']['node-port']='192.168.7.13'
	server['master']=false
	server['worker']=true
	server['hostname']='worker-1'
end

default['k8s']['sdn']['bcf_repo_url']='https://null'

default['k8s']['dns_service']['ip']='10.255.0.254'
default['k8s']['dns_service']['domain']='cluster.local'
default['k8s']['cluster_name']='test'

default['k8s']['new_features']=false

default['k8s']['client_cert']="unset"
default['k8s']['client_key']="unset"

default['k8s']['key_interface']="eno1" # mgmt interface, used by portwork as well

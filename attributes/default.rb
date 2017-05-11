
default['k8s']['airgap_install']=false

default['k8s']['sdn']['interfaces']="-u eno2 -u eno3 -u eno4"
default['k8s']['sdn']['netmask']="255.255.252.0"

default['k8s']['yum_repos']['purge_old'] = true

default['k8s']['sdn']['bcf_controller_ip']='10.1.1.2'
default['k8s']['sdn']['bcf_password']='123123123'
default['k8s']['sdn']['bcf_username']='admin'
default['k8s']['sdn']['bcf']['networks']['kube-system']='10.1.2.1/24'
default['k8s']['sdn']['bcf']['networks']['default']='10.1.4.1/23'
default['k8s']['sdn']['bcf']['networks']['nodes']='10.1.3.1/24'
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
	image['kube-apiserver'] = "gcr.io/google_containers/kube-apiserver-amd64:v1.5.6"
	image['kube-proxy'] = "quay.io/coreos/hyperkube:v1.5.6_coreos.0"
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

default['k8s']['masters']['ipaddr'].tap do |ipaddr|
	ipaddr['kube-master-1'] = '10.1.3.32'
	ipaddr['kube-master-2'] = '10.1.3.33'
	ipaddr['kube-master-3'] = '10.1.3.34'
end

default['k8s']['node-ports'].tap do |port|
	port['01:23:45:67:89:AB']='10.1.3.32'
	port['01:23:45:67:89:AC']='10.1.3.33'
	port['01:23:45:67:89:AD']='10.1.3.34'
	port['01:23:45:67:89:AE']='10.1.3.35'
end

default['k8s']['hostname'].tap do |port|
	port['01:23:45:67:89:AB']='kube-master-1'
	port['01:23:45:67:89:AC']='kube-master-2'
	port['01:23:45:67:89:AD']='kube-master-3'
	port['01:23:45:67:89:AE']='worker-1'
end

default['k8s']['sdn']['bcf_repo_url']='https://null'

default['k8s']['dns_service']['ip']='10.255.0.254'
default['k8s']['dns_service']['domain']='cluster.local'

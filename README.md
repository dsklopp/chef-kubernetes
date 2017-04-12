# chef-kubernetes-cookbook

Creates multi-master Kubernetes cluster, designed for air gap Enterprise systems.  This is provided as is, please submit issues as necessary, but use at own risk.

This cookbook was built specifically to utilize the Big Switch SDN (http://www.bigswitch.com/) which is our SDN of choice.  This is the cookbook we use to deploy our production and dev Kubernetes cluster on baremetal and eventually AWS.  Future platforms may be supported.

## Supported Platforms

 * Centos 7.3

## Architecture
Master nodes and worker nodes are distinct physical systems.  Theoretically we can use the same system but this cookbook has not been tested in that way.

Master nodes run the following services:

 * bcf-agent
 * etcd
 * bcf-etcd
 * kube-proxy
 * kubelet
   * kube-controller   
   * kube-apiserver
   * kube-scheduler
   * kube-controller

Worker nodes run the following services:

 * kube-proxy
 * kubelet

All manifest files are installed under /etc/kubernetes/manifests .

Every node has 4 interfaces.  In our implementation these are eno1, eno2, eno3, and eno4.  Presently eno2, eno3 and eno4 are used by the SDN (Chef attribute node['k8s']['sdn']['interfaces']).  eno1 is used by the system for general management and is not used by Kubernetes at this time.  In the future we expect to bind all four interfaces to the SDN.

## Setup
This cookbook was designed to work in air gap enterprise setups and HA solutions.  As such, there are some steps that may seem needlessly complicated to those who only need kops or the beta tool kubeadm.

### Limitations
There must be 3 master nodes.  There can be at least 1 worker node.

### Package Repositories

First things first, repositories must be set up.  THis cookbook can use your own private repositories (and this is how we use it inhouse).  If you choose to use public repositories, you can do this but you need to manually provide the BCF CNI plugin repository in a wrapper cookbook.  

To use a private repository you need to mirror a minimum of:

 * Mirror the Centos yum repository
 * Mirror the docker yum repository
 * Stage the BCF SDN RPM into an accessible yum repository
 * Mirror Kubernetes docker images to your own private repository
 * Stage Kubernete binaries at an accessible HTTP endpoint
 * Stage CNI plugin binaries at an accessible HTTP endpoint
 * Stage etcd docker image from Coreos / quay.io

If you do not want to mirror all of the above then use the defaults.  Please note you must set the variable node['k8s']['sdn']['bcf_repo_url'] to a yum repository serving the BCF CNI plugin.

### Setting variables
Next, define your cluster.  Only 3 kubernetes masters are supported, no more, no less.  Any number of kubernete workers are acceptable.

First, set the interfaces to use for Kubernetes and BCF SDN.

```
default['k8s']['sdn']['interfaces']="-u eno2 -u eno3 -u eno4"
```

next, configure the SDN.  These are specific to BCF.

```
default['k8s']['sdn']['bcf_controller_ip']='ip here'
default['k8s']['sdn']['bcf_password']='password here'
default['k8s']['sdn']['bcf_username']='username here'cidr_here'
default['k8s']['sdn']['bcf']['networks']['default']='10.cidr_here'
default['k8s']['sdn']['bcf']['networks']['nodes']='cidr_here'
default['k8s']['sdn']['bcf']['tenant']='Kubernetes.cni'
```

Please update the variables above as appropriate.

next update the download links

```
default['k8s']['kube-binaries']['url']=""
default['k8s']['kubernetes']['version']='1.5.6'
```

The first is where your private repository of kubectl, kubeadm and kubelet is located.  If node['k8s']['airgap_install'] is set to true then node['k8s']['kube-binaries']['url'] is not used.  The node['k8s']['kubernetes']['version'] is important if airgap_install is false, as it will attempt to download the binaries directly from github releases.

Similarly set:

```
default['k8s']['cni-binaries']['url']=""
default['k8s']['cni-binaries']['version']='0.5.2'
```

The same logic from node['k8s']['kube-binaries']['url'] and node['k8s']['kubernetes']['version'] apply here.

Next set the master CNAME or A record.  This must be a round robin DNS entry, equally weighted for all kubernetes masters.  A FQDN is recommended.

```
default['k8s']['masters']['cname']='kube-master'
```

Include kube_worker for worker nodes and kube_master for master nodes.

Next create the mapping of mac addresses and hostnames.  This is done to support our kickstart boot process.  At boottime we need a way to identify a node.



```
default['k8s']['masters']['ipaddr'].tap do |ipaddr|
  ipaddr['kube-master-1'] = '10.1.3.32'
  ipaddr['kube-master-2'] = '10.1.3.33'
  ipaddr['kube-master-3'] = '10.1.3.34'
end
```
Map node['k8s']['masters']['ipaddr'] from hostname to IP address.

```
default['k8s']['node-ports'].tap do |port|
  port['01:23:45:67:89:AB']='10.1.3.32'
  port['01:23:45:67:89:AC']='10.1.3.33'
  port['01:23:45:67:89:AD']='10.1.3.34'
  port['01:23:45:67:89:AE']='10.1.3.35'
end
```

Map node['k8s']['node-ports'] from mac address to node-port IP address.

```
default['k8s']['hostname'].tap do |port|
  port['01:23:45:67:89:AB']='kube-master-1'
  port['01:23:45:67:89:AC']='kube-master-2'
  port['01:23:45:67:89:AD']='kube-master-3'
  port['01:23:45:67:89:AE']='worker-1'
end
```

Map node['k8s']['hostname'] mac addresses to hostnames.

By default this cookbook is run once, the nodes reboot, and the cluster comes back up.

Good luck!

### Installation
After setting the variables, run kube_master on the masters and kube_worker on the workers.  Reboot the nodes.  On one of the masters run the command:

```
bcf-cfg-ctl /etc/bcf-config.yaml
```


## License and Authors

Author:: Daniel Klopp (<dsklopp@gmail.com>)

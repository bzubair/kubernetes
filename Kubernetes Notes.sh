
******CoreOS*********
- At boot, CoreOS reads a user-supplied configuration file called "cloud-config" to do some initial configuration. 
- Usually, the "cloud-config" file will, at a minimum, tell the host how to join an existing cluster and command the host to boot up two services called etcd and fleet. configuration
- The etcd daemon is used to store and distribute data to each of the hosts in a cluster.
	This is useful for keeping consistent configurations and it also serves as a platform with which services can announce themselves.
- The fleet daemon is basically a distributed init system.
	It handles service scheduling, constraining the deployment targets based on user-defined criteria.


Container related info:
- cgroups: are often in /sys/fs/cgroups. Used for resource metering and limiting
- Rocket is like docker

Tools:
- cAdvisors: it takes the resource number and give it a times series. If a vm is resouce is using 100% resource right now then what it was using before

***********Kubernetes has several components***********

etcd - A highly available key-value store for shared configuration and service discovery.
flannel - An etcd backed network fabric for containers.
kube-apiserver - Provides the API for Kubernetes orchestration.
kube-controller-manager - Enforces Kubernetes services.
kube-scheduler - Schedules containers on hosts.
kubelet - Processes a container manifest so the containers are launched according to how they are described.
kube-proxy - Provides network proxy services.


****Kubernetes Installation - Centos7****
http://severalnines.com/blog/installing-kubernetes-cluster-minions-centos7-manage-pods-services
https://www.youtube.com/watch?v=tA8XNVPZM2w
1. systemctl stop/disable firewalld
2. yum -y install ntp, systemctl start/enable/sync ntpd

*************************
	  PROXY SETTING
*************************

On Minions following cnfiguration required
1. mkdir /etc/systemd/system/docker.service.d
2. Edit "/etc/systemd/system/docker.service.d/http-proxy.conf " the enter the following configure
		[Service]
		Environment="HTTP_PROXY=http://proxy.lbs.alcatel-lucent.com:8000/"
		Environment="HTTPS_PROXY=https://proxy.lbs.alcatel-lucent.com:8000/"
3. For no-proxy (OPTIONAL)
		Environment="HTTP_PROXY=http://proxy.example.com:80/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
4. systemctl daemon-reload
5. systemctl restart docker

NOTE: MAY BE you need to go to minion and tun "docker images" if you see gcr.io/google_containers/pause then delete this docker image 
	docker  -D rmi -f 2c40b0526b63

***************************
Kube Master Installation
***************************

	1. Install Centos 7.1
	2. yum -y install etcd kubernetes
	3. edit /etc/etcd/etcd.conf
		ETCD_NAME=default
		ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
		ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
		ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"
	4. Edit /etc/kubernetes/apiserver
		KUBE_API_ADDRESS="--address=0.0.0.0"
		KUBE_API_PORT="--port=8080"
		KUBELET_PORT="--kubelet_port=10250"
		KUBE_ETCD_SERVERS="--etcd_servers=http://127.0.0.1:2379"
		KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
		KUBE_ADMISSION_CONTROL="--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
		KUBE_API_ARGS=""

	5. Start and enable etcd kube-apiserver kube-controller-manager kube-scheduler
	
	6. Define flannel network configuration in etcd. 
		etcdctl mk /atomic.io/network/config '{"Network":"172.17.0.0/16"}'
		**In this scenario we are using atomic.ip but have multiple other options like coreos etc

	7. Check to see if any Miniosn nodes are added	
		kubectl get nodes

***********************************
Kubernetes Minions Installation
***********************************

	1. Install Centos 7.1 with physical drive 20 and another volume group (vdb) atleast 10
		- create volume and attach to vm
		- "pvcreate /dev/vdb" (Attached/create second disk to vm)
		- "pvs" (check the second disk)
		- "vgextend centos /dev/vdb" (Add disk to volume group named centos)
		- "vgs" to check the additional disk space is added to volume group
		- "vgdisplay -v | more" "pvdisplay" "lvdisplay" other command to very space
	2. yum -y install flannel kubernetes
	3. Edit /etc/sysconfig/flanneld to configure etcd server 
		FLANNEL_ETCD="http://192.168.0.134:2379"
		FLANNEL_ETCD_KEY="/atomic.io/network"
		#FLANNEL_ETCD_KEY="/coreos.com/network"
	4. Edit  /etc/kubernetes/config to define kubernet server
		KUBE_MASTER="--master=http://192.168.0.134:8080"
	5. Edit /etc/kubernetes/kubelet to configure kubelet service
		KUBELET_ADDRESS="--address=0.0.0.0"
		KUBELET_PORT="--port=10250"
		# change the hostname to this host’s IP address
		KUBELET_HOSTNAME="--hostname_override=minion1.lab.local"
		KUBELET_API_SERVER="--api_servers=http://kubemaster.lab.local:8080"
		KUBELET_ARGS=""
	6. Start and enable kube-proxy, kubelet, docker and flanneld services
	7. Login to Kubemaster and check if node is added "kubectl get nodes"


*************************
	  CLUSTER CONFIG
*************************
1. NON-SECURE cluster setup (????)
kubectl config set-credentials myself --username=admin --password=secret
kubectl config set-cluster local-server --server=http://localhost:8080
kubectl config set-context default-context --cluster=local-server --user=myself
kubectl config use-context default-context
kubectl config set contexts.default-context.namespace the-right-prefix
kubectl config view




*************************
	  CREATING PODS
*************************
	--> Create yaml file (checj sample yaml is kubernetes folder)
	--> auto-create the API token for  service Account (http://stackoverflow.com/questions/31891734/not-able-to-create-pod-in-kubernetes)
			- openssl genrsa -out /tmp/serviceaccount.key 2048
			- vi /etc/kubernetes/apiserver:
					KUBE_API_ARGS="--service_account_key_file=/tmp/serviceaccount.key"
			- vi /etc/kubernetes/controller-manager
					KUBE_CONTROLLER_MANAGER_ARGS="--service_account_private_key_file=/tmp/serviceaccount.key"
			- systemctl restart kube-controller-manager.service
	--> kubectl create -f pod.yaml
	--> kubectl get pods
			kubectl get events --watch
			kubectl logs <POD-NAME>
			kubectl cluster-info


Image deployment
kubectl run my-nginx --image=nginx --replicas=2 --port=80 --expose --service-overrides='{ "spec": { "type": "LoadBalancer" } }'

***************************
	"TROUBLESHOOTING"
***************************
	Check events "bin/kubectl -s x.x.x.x:8080 get events --namespace=kube-system"
	To check more commands "https://github.com/kubernetes/kubernetes/issues/11684"
	kubectl get events --watch
	if docker throw error message about expection 172.16.54.1 or something like then 
			run "systemctl daemon-reload"
			reboot machine

****Kubernetes commands****
--> "NODES RELATED"
	kubectl get nodes -- to check online nodes
	kubectl describe nodes

--> "Deleting PODS"
	kubectl get deployment 
	kubectl delete deployment 
	kubectl delete pod <--all OR POD NAME> -- If POD is deployed using run command 
	kubectl get pods -l run=my-nginx -o yaml
	kubectl get pods -l run=my-nginx -o wide


--> "NETWORKING"
	etcdctl get /atomic.io/network/config



--> "MISC"
	kubectl -s x.x.x.x:8080 version -- to check version

kubectl get pods -L run -- to check Labels
kubectl get service/my-nginx


--> create the kube-system namespace, the rc and service for kube-ui
	"bin/kubectl -s x.x.x.x:8080 create -f kube-ui-rc.yaml --namespace=kube-system" 
	"bin/kubectl -s x.x.x.x:8080 create -f -f kube-ui-svc.yaml --namespace=kube-system"

	"bin/kubectl -s x.x.x.x:8080 get services --namespace=kube-system"
	"bin/kubectl -s x.x.x.x:8080 get rc --namespace=kube-system"



--> kubectl delete rc kubernetes-dashboard --namespace=kube-system

--> "kubectl exec <pod-name> date" EXEC command against container in a POD

1. kubectl get pods
2. kubectl get services
3. kubectl get ep 
4. kubectl describe services my-nginx
5. kubectl exec my-nginx-3800858182-46owm -- printenv | grep SERVICE
6. kubectl resize rc <pod-name> --replicas=3


to launch and expose to internet (https://www.youtube.com/watch?v=DC7NECq3Ghs) *This example is used to deploy=my-nginx with king DEPLOYMENT
1. deploy POD (check the kind becuase rest of the commands depend if the pod is deploy as kind: POD, DEPLOYMENT or RC)
2. k get/service pods
3. check via curl to see if it working
4. kubectl scale --current-replicas=1 --replicas=3 deployment/my-nginx (ADD containers for kind:deployment from 1 to 3)
5. kubectl get pods(you should see 3 containers)
6. check with curl 
7. kubectl expose -f nginx-kindDeployment.yaml --port=80 --external-ip=192.168.245.250 (assign service/LB IP to aboce three container)
		OR
	kubectl expose -f nginx-kindDeployment.yaml --port=80 --type=NodePort
			and Access the container on Node IP: Node Port
8 kubectl get services
9. curl with the service IP



Training
https://github.com/RedHatWorkshops/docker-kubernetes-workshop


kubectl expose (-f FILENAME | TYPE NAME) [--port=port] [--protocol=TCP|UDP] [--target-port=number-or-name] [--name=name] [--external-ip=external-ip-of-service] [--type=type] [flags]
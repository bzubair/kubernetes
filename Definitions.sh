*****Kubernetes Concepts*****

So put it all together 
	"Containers" runs on clusters 
		"PODs" are containers that work together
			"Services" are PODS that work together like a web farm
				"Labels" are used to organize services
https://www.youtube.com/watch?v=qCxYjq7EBHc

NODE: 
	run Docker, kubelet and proxy
	Prepare a Node Manifest

POD
	Pods are a colocated group of application containers with shared volumes
	Share some namespaces like network namespace
	It runs a infrastructure deamon to grap the ip from Docker
	Each POD has one IP NOT every container
	Containers in a POD share the namespaces includng their IP addresses
	Pods can be created individually, but it is recommended that you use a replication controller even if creating a single pod.
	A pod generally represents one or more containers that should be controlled as a single "application".

API SERVERS 
	API Servers are the "ONLY SERVERS which talks to ETCD"
	This is the one which understand all the "MANIFESTS"
	is the main management point of the entire cluster. 
	A client called "kubecfg" is packaged along with the server-side tools and can be used from a local computer or by connecting to the master server.

SCHEDULER
	Best fit choses based on POD requirement
	Only schedules job to nodes which a re healthy
	Scheduler tackes action --> picks a nodes in a cluster --> Puts a POD in its namespace in etcd and new pod will be launched
	Unhealthy nodes will be removed
	Pluggable Other schedulers can used like mesos

REPLICATION CONTROLLERS
	Replication controllers manage the lifecycle of pods.
	Creates PODS from templates (POD Manifest)	
	Ensures desired number of PODS are running
	Self-healing.. If pods goes down --reschedule it somewhere else

SERVICE
	Services provide a single, stable name and address for a set of pods. 
	They act as basic load balancers.
	Can have VIP per service 

ETCD 
	This is where all the configuration is stored
	If ETCD is gone then everything is gone so cluster ETCD servers are recommended
	Kubernetes uses etcd to store configuration data that can be used by each of the nodes in the cluster. 

NAMESPACES
	The kube-system namespace is the one where the administrative user (system:admin) typically runs the kube-ui 
	and dns service, and so on for all the users of the cluster. 
	This imposes a networking requirement that the services deployed in the “kube-system” namespace should have 
	reachability to and from pods in all other namespaces.
	
FLANNELD
	This is for overlay network 

CADVISOR
	Kubelet has this tool built in which works with scheduler to give output of the resources used or free. This will help SCHEDULER choose node and deploy PODS there
	CADVISOR gets it from CGROUPS


PROXY SERVICE
	Portal_net configuration isused to define the VIP subnet for services

CLOUD PROVIDER
	Kubernetes has the concept of a Cloud Provider, which is a module which provides an interface for managing TCP Load Balancers, Nodes (Instances) and Networking Routes.

KUBERNETES NETWORKING 
	Highly-coupled container-to-container communications: this is solved by pods and localhost communications
	Pod-to-Service communications: this is covered by services.
	External-to-Service communications: this is covered by services
	Pod-to-Pod communications: 
			all containers can communicate with all other containers without NAT
			all nodes can communicate with all containers (and vice-versa) without NAT
			the IP that a container sees itself as is the same IP that others see it as

KUBEKET SERVICE 
	is the main contact point for each minion with the cluster group.
	This service is responsible for relaying information to and from the master server, as well as interacting with the etcd store to read configuration details or write new values






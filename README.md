# kubernetes-standalone

A repository containing setup scripts and configurations for a single-node Kubernetes cluster using [microk8s](https://microk8s.io/). 

The cluster is hosted on AWS EC2.

The cluster provides hosting for the web page and server [professional-website](https://github.com/matthewjohnson42/professional-website).

The cluster also formerly provided hosting for [memex-service](https://github.com/matthewjohnson42/memex-service) and [memex-ui](https://github.com/matthewjohnson42/memex-ui).

Given that the hosting scheme is based on cost, the single node host was used to provide the deploy platform. 
The host configuration is bound with the deploy scripts, and so the deploy scripts are included in this repository rather than kept along with the source code of the corresponding system components.

### usage

Create AWS EC2 instance with 2 CPU and 4 GB of memory.

Create AWS 2 EBS disks of a size appropriate to the volume of entries stored by the memex, say 8 GB. Attach the disks to the EC2 instance.

Ensure that the AWS EC2 instance has an associated VPC and security group exposing ports 22, 80, 443, and 8544 on both IPv4 and IPv6.

Initialize the EC2 instance by logging in and running:

* `curl https://raw.githubusercontent.com/matthewjohnson42/k8s-standalone/master/server-init.sh -o ~/server-init.sh`
* `sudo sh ~/server-init.sh ${USER} ${HOME}`

To update the instance, run the scripts titled `build-and-deploy.sh` in the subdirectories of the `kubernetes` directory.


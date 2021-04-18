# k8s-standalone
A repository containing scripts and configurations for a single-node Kubernetes cluster using [microk8s](https://microk8s.io/). Cluster is hosted on AWS using EC2.

The cluster provides hosting for a personal memex project as implemented by [memex-service](https://github.com/matthewjohnson42/memex-service) and [memex-ui](https://github.com/matthewjohnson42/memex-ui), as well as the simple web site present as [professional-website](https://github.com/matthewjohnson42/professional-website)

### usage

Create AWS EC2 instance with 2 CPU and more than 4 GB of memory.

Create AWS 2 EBS disks of a size appropriate to the volume of entries stored by the memex, say 8 GB. Attach the disks to the EC2 instance.

Initialize the EC2 instance by logging in and running:

* `curl https://raw.githubusercontent.com/matthewjohnson42/k8s-standalone/master/server-init.sh -o ~/server-init.sh`
* `sudo sh ~/server-init.sh ${USER} ${HOME}`

To update the instance, run the scripts titled `build-and-deploy.sh` in the subdirectories of the `kubernetes` directory.

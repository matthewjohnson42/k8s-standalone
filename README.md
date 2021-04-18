# k8s-standalone
A repository containing scripts and configurations for a single-node Kubernetes cluster using [microk8s](https://microk8s.io/). Cluster is hosted on AWS using EC2.

The cluster provides hosting for a personal memex project as implemented by [memex-service](https://github.com/matthewjohnson42/memex-service) and [memex-ui](https://github.com/matthewjohnson42/memex-ui), as well as the simple web site present as [professional-website](https://github.com/matthewjohnson42/professional-website)

### usage

To initialize the server providing hosting for the Kubernetes cluster, login to the server and run:

* `curl https://raw.githubusercontent.com/matthewjohnson42/personal-memex-server/master/server-init.sh -o ~/server-init.sh`
* `sudo sh ~/server-init.sh ${USER} ${HOME}`

To update the server, run the scripts titled `build-and-deploy.sh` in the subdirectories of the `kubernetes` directory.

# personal-memex-server
A repository containing scripts and configurations for a server hosting [personal-memex-service](https://github.com/matthewjohnson42/personal-memex-service) and [personal-memex-ui](https://github.com/matthewjohnson42/personal-memex-ui).

Server is hosted on AWS using a Lightsail Ubuntu instance.

The server includes setup a firewall configuration, a FS mount of an AWS block storage device for data persistence, a Docker service to host the app's containers (container runtime provider), and a Kubernetes instance configured to repopulate the app containers as needed.

### usage

To initialize the server, run:

* `curl https://raw.githubusercontent.com/matthewjohnson42/personal-memex-server/master/server-init.sh -o ~/server-init.sh`
* `sudo sh ~/server-init.sh ${USER} ${HOME}`

To update the server, run the script `build-and-deploy.sh`.

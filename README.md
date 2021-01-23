# personal-memex-server
A repository containing scripts and configurations for a server hosting [personal-memex-service](https://github.com/matthewjohnson42/personal-memex-service) and [personal-memex-ui](https://github.com/matthewjohnson42/personal-memex-ui).

Server is hosted on AWS using a Lightsail Ubuntu instance.

The server includes as part of its design a firewall configuration, an Nginx service configured to route traffic, a Docker service configured to host the app's containers, and a Kubernetes instance on Docker configured to repopulate the app containers as needed.

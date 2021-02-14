# personal-memex-server
A repository containing scripts and configurations for a server hosting [personal-memex-service](https://github.com/matthewjohnson42/personal-memex-service) and [personal-memex-ui](https://github.com/matthewjohnson42/personal-memex-ui).

Server is hosted on AWS using a Lightsail Ubuntu instance.

The server includes as part of its design a firewall configuration, an Nginx service configured to route traffic, a Docker service configured to host the app's containers, and a Kubernetes instance configured to repopulate the app containers as needed.

### usage

To initialize the server,

* perform a `git clone --bare` into the home directory of the AWS instance
* run `workspaceInit.sh`
* run `cloudInit.sh`
* run `webserverInit.sh`
* run `startApp.sh`

To update the server,

* run `updateFromSources.sh`

Note that the firewall is configured by the `webserverInit.sh` script. Outbound HTTP requests will be blocked without a run of `ufwAllowOut.sh`

### webserver cert renewal

Assumes that `webserverInit.sh` has been run on the system first.

To renew the cert:

1) run `sudo certbot certonly --force-renewal -d matthewjohnson42.com`
2) select 3 for the method of verification, and enter `/usr/share/nginx/html/` as the webroot.
3) copy the DH random prime file from the previous certificate installation in `/etc/letsencrypt/live/`
4) update the nginx configuration in `/etc/nginx/sites-available` to reference the new certificate installation
5) reload nginx using `sudo nginx -s reload`, updating `run/nginx.pid` as appropriate

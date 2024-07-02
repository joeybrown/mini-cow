# mini-cow

This depends on running podman with some config.

### Allow insecure localhost registry
podman machine list
podman machine ssh podman-machine-default
sudo su -
vi /etc/containers/registries.conf

```toml
[[registry]]
location = "localhost"
insecure = true
```

### Set DOCKER_HOST
podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}'
export DOCKER_HOST=unix://<your_podman_socket_location>
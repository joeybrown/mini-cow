# mini-cow

This depends on running podman with some config.

podman machine list
podman machine ssh podman-machine-default
sudo su -
vi /etc/containers/registries.conf

```toml
[[registry]]
location = "localhost"
insecure = true
```

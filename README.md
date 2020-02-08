# wireguard-docker

A Debian Docker container for WireGuard.

* [Setting Up](#setting-up)
  * [Build](#build)
  * [Run](#run)
  * [Configure](#configure)
  * [Update](#update)
* [Extras](#extras)
  * [Secure DNS](#secure-dns)
  * [Bind Mounts](#bind-mounts)
  * [IPv6 Support](#ipv6-support)
* [Credits](#credits)

***

## Setting Up

### Build

Docker should already be installed, then execute the following in any directory you wish:

```sh
git clone https://github.com/lazerl0rd/wireguard-docker.git -b <variant>
cd wireguard-docker
docker build -t wireguard-docker:custom .
```

where the variant is the Debian flavour you are running.

### Run

You must first install the WireGuard kernel module (or build a kernel with it), then execure:

```sh
docker run --cap-add net_admin --cap-add sys_module -v <config volume or host dir>:/etc/wireguard -p <externalport>:<dockerport>/udp wireguard-docker:custom
```

An example could be:

```sh
docker run --cap-add net_admin --cap-add sys_module -v wireguard_conf:/etc/wireguard -p 5555:5555/udp wireguard-docker:custom
```

### Configure

A `wg[0-9].conf` file should be placed into `/etc/wireguard` in the container. If you used a volume, rather than mounting a directory from the host, then you need to jump into the container's shell. This can be done as follows:

```sh
docker exec -it <running container id> sh
nano /etc/wireguard/wg0.conf
```

where the container ID can be found by using the `docker ps` command.

Some example configuration is shown below:

```conf
[Interface]
Address = 192.168.20.1/24
PrivateKey = <server_private_key>
ListenPort = 5555

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 192.168.20.2
```

You can use the `genkeys` script to generate the key pairs used, as shown below:

```sh
docker run -it --rm wireguard-docker:custom genkeys
```

### Update

To update, just jump back into the directory where you cloned this repository and execute:

```sh
cd wireguard-docker
git pull
docker build -t wireguard-docker:custom . --pull
```

If you do not have the WireGuard module on the host system, then you need to re-run the `install-module` script, as follows:

```sh
docker run -it --rm --cap-add sys_module -v /lib/modules:/lib/modules wireguard-docker:custom:<variant> install-module
```

where, as before, the variant is the Debian flavour you are running.

## Extras

### Secure DNS

There are many protocols for secure DNS resolving inculding DoT, DoH, and DNSCrypt alongside DNSSEC. Therefore, the Unbound DNS resolver has been bundled together with this container to provide just that.

First, we must configure Unbound through the container (this is only necessary if you used a volume for `/etc/wireguard`, otherwise do what you did to edit `wg[0-9].conf`):

```sh
docker exec -it <running container id> sh
nano /etc/wireguard/unbound.conf
```

where the container ID can be found by using the `docker ps` command.

Inside the `/etc/wireguard/unbound.conf` file you must [configure the Unbound resolver](https://www.nlnetlabs.nl/documentation/unbound/unbound.conf) with the listen address of your WG configuration. An example is as follows:

```conf
server:
  access-control: 127.0.0.0/8 allow
  access-control: ::1/128 allow
  # auto-trust-anchor-file: "/etc/wireguard/dnssec-root.key"
  hide-identity: yes
  hide-version: yes
  interface: 0.0.0.0
  interface: ::0
  ip-freebind: yes
  prefetch: yes
  prefetch-key: yes
  qname-minimisation: yes
  so-reuseport: yes
  tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
  use-caps-for-id: yes

forward-zone:
  name: "."
  forward-tls-upstream: yes
  forward-addr: 176.103.130.132@853#dns-family.adguard.com
  forward-addr: 2a00:5a60::bad1:0ff@853#dns-family.adguard.com
  forward-addr: 176.103.130.134@853#dns-family.adguard.com
  forward-addr: 2a00:5a60::bad2:0ff@853#dns-family.adguard.com
```

And finally, add the DNS servers to your client:

```conf
DNS = 192.168.20.1
```

### Bind Mounts

Volumes are used in these examples, but bind mounts could easily be too. This can be useful if you are not running a WireGuard server on your host. I suggest using the `readonly` flag and modifing the configuration via your host only. So instead of:

```sh
-v <config volume or host dir>:/etc/wireguard
```

Use:

```sh
--mount type=bind,source=<host dir>,target=/etc/wireguard,readonly
```

### IPv6 Support

Docker put through a change a while back which disables IPv6 by default for containers. To re-gain the ability to have IPv6-able WireGuard, please add `--sysctl net.ipv6.conf.all.disable_ipv6=0` to your `docker run` command.

For example:

```
docker run --cap-add net_admin --cap-add sys_module -v wireguard_conf:/etc/wireguard -p 5555:5555/udp --sysctl net.ipv6.conf.all.disable_ipv6=0 wireguard-docker:custom 
```

## Credits

Thanks to [cmulk](https://github.com/cmulk) for their [Docker image](https://hub.docker.com/r/cmulk/wireguard-docker) which was the base for this, and provided the example configuration.

Thanks to David Huie and [Active EOS](https://activeeos.com) for their [Docker image](https://hub.docker.com/r/activeeos/wireguard-docker), which was inspiration for most WireGuard Docker images.

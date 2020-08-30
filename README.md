# arch-simpletorrentvpn

[![Docker Pulls](https://img.shields.io/docker/pulls/zikeji/arch-simpletorrentvpn.svg)][dockerhub]
[![Image Size](https://images.microbadger.com/badges/image/zikeji/arch-simpletorrentvpn.svg)][dockerhub]

[dockerhub]: https://hub.docker.com/r/zikeji/arch-simpletorrentvpn/

## Special Thanks

This Docker image is based on the amazing [arch-delugevpn](https://github.com/binhex/arch-delugevpn) image and it's core components created by [binhex](https://github.com/binhex).

## Disclaimer

While I tried my best to understand the amazing work that binhex put into the original image, I may have made mistakes along the line. I've only tested with with AirVPN and have not verified the PIA auto port mapping works. Feel free to open an issue if you run into any bugs or trouble.

## Application

* [SimpleTorrent Repository](https://github.com/boypt/simple-torrent/)
* [OpenVPN Website](https://openvpn.net/)  
* [Privoxy Website](http://www.privoxy.org/)

## Description

SimpleTorrent is a a self-hosted remote torrent client, written in Go (golang). Started torrents remotely, download sets of files on the local disk of the server, which are then retrievable or streamable via HTTP. This Docker includes OpenVPN to ensure a secure and private connection to the Internet, including use of iptables to prevent IP leakage when the tunnel is down. It also includes Privoxy to allow unfiltered access to index sites, to use Privoxy please point your application at `http://<host ip>:8118`.

## Build notes

* Latest SimpleTorrent build from master branch
* Latest stable OpenVPN release from Arch Linux repo.
* Latest stable Privoxy release from Arch Linux repo.

### Usage

```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 3000:3000 \
    -p 8118:8118 \
    --name=<container name> \
    -v <path for config files>:/config \
    -v <path for downloads>:/downloads \
    -v <path for torrent watching>:/torrents
    -v /etc/localtime:/etc/localtime:ro \
    -e SIMPLETORRENT_TITLE=<optional title for binary, defaults to SimpleTorrent> \
    -e VPN_ENABLED=<yes|no> \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_PROV=<pia|airvpn|custom> \
    -e VPN_OPTIONS=<additional openvpn cli options> \
    -e STRICT_PORT_FORWARD=<yes|no> \
    -e ENABLE_PRIVOXY=<yes|no> \
    -e NAME_SERVERS=<name server ip(s)> \
    -e ADDITIONAL_PORTS=<port number(s)> \
    -e DEBUG=<true|false> \
    -e UMASK=<umask for created files> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    zikeji/arch-simpletorrentvpn
```

Please replace all user variables in the above command defined by <> with the correct values. Please ensure your mounts have the correct permissions that match the PUID and PGID.

#### Access SimpleTorrent

`http://<host ip>:3000`

#### Access Privoxy

`http://<host ip>:8118`

#### PIA Example
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 3000:3000 \
    -p 8118:8118 \
    --name=simpletorrentvpn \
    -v /apps/docker/simpletorrentvpn/config:/config \
    -v /apps/docker/simpletorrentvpn/downloads:/downloads \
    -v /apps/docker/simpletorrentvpn/torrents:/torrents \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_USER=myusername \
    -e VPN_PASS=mypassword \
    -e VPN_PROV=pia \
    -e STRICT_PORT_FORWARD=yes \
    -e ENABLE_PRIVOXY=yes \
    -e NAME_SERVERS=209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e ADDITIONAL_PORTS=1234 \
    -e DEBUG=false \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    zikeji/arch-simpletorrentvpn
```
### AirVPN Provider

AirVPN users will need to generate a unique OpenVPN configuration file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the arch-simpletorrentvpn docker to create the folder structure
4. Stop arch-simpletorrentvpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start arch-simpletorrentvpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

#### AirVPN Example
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 3000:3000 \
    -p 8118:8118 \
    --name=simpletorrentvpn \
    -v /apps/docker/simpletorrentvpn/config:/config \
    -v /apps/docker/simpletorrentvpn/downloads:/downloads \
    -v /apps/docker/simpletorrentvpn/torrents:/torrents \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_PROV=airvpn \
    -e ENABLE_PRIVOXY=yes \
    -e NAME_SERVERS=209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e DEBUG=false \
    -e ADDITIONAL_PORTS=1234 \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    zikeji/arch-simpletorrentvpn
```
### Notes

Please note this Docker image does not include the required OpenVPN configuration file and certificates. These will typically be downloaded from your VPN providers website (look for OpenVPN configuration files), and generally are zipped.

PIA users - The URL to download the OpenVPN configuration files and certs is:-

https://www.privateinternetaccess.com/openvpn/openvpn.zip

Once you have downloaded the zip (normally a zip as they contain multiple ovpn files) then extract it to /config/openvpn/ folder (if that folder doesn't exist then start and stop the docker container to force the creation of the folder).

If there are multiple ovpn files then please delete the ones you don't want to use (normally filename follows location of the endpoint) leaving just a single ovpn file and the certificates referenced in the ovpn file (certificates will normally have a crt and/or pem extension).

Due to Google and OpenDNS supporting EDNS Client Subnet it is recommended NOT to use either of these NS providers.
The list of default NS providers in the above example(s) is as follows:-

209.222.x.x = PIA
84.200.x.x = DNS Watch
37.235.x.x = FreeDNS
1.x.x.x = Cloudflare

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

`id <username>`
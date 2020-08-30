# build bin
FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git
WORKDIR /root/simple-torrent
ENV PATH=$HOME/go/bin:$PATH 
RUN git clone https://github.com/boypt/simple-torrent.git . && \
    go get -v -u github.com/shuLhan/go-bindata/... && \
    go get -v -t -d ./... && \
    cd static && \
    sh generate.sh

ENV GO111MODULE=on CGO_ENABLED=0
RUN go build -ldflags "-s -w -X main.VERSION=$(git describe --tags)" -o /usr/local/bin/simple-torrent

# build arch-simpletorrentvpn image
FROM binhex/arch-int-openvpn:latest
LABEL maintainer="me@zikeji.com"

# copy bin from builder
COPY --from=builder /usr/local/bin/simple-torrent /usr/local/bin/simple-torrent

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add bash scripts to install app
ADD build/root/*.sh /root/

# add bash script to setup iptables
ADD run/root/*.sh /root/

# add bash script to run SimpleTorrent
ADD run/nobody/*.sh /home/nobody/

# add pre-configured config files for SimpleTorrent
ADD config/nobody/ /home/nobody/

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh /home/nobody/*.sh && \
	/bin/bash /root/install.sh

# docker settings
#################

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /downloads to host defined downloads path
VOLUME /downloads

# map /torrents to host defined torrents path
VOLUME /torrents

# expose port for SimpleTorrent
EXPOSE 3000

# expose port for privoxy
EXPOSE 8118

# expose port for default SimpleTorrent incoming port (used only if VPN_ENABLED=no)
EXPOSE 50007
EXPOSE 50007/udp

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/usr/local/bin/init.sh"]
#!/bin/bash

if [[ "${simpletorrent_running}" == "false" ]]; then

	echo "[info] Attempting to start SimpleTorrent..."

	# run SimpleTorrent daemon
	nohup /usr/local/bin/simple-torrent -t "${simpletorrent_title}" -c /config/simple-torrent.yaml > /config/simpletorrent.log 2>&1 &

	# make sure process simple-torrent DOES exist
	retry_count=30
	while true; do
		if ! pgrep -fa "simple-torrent" > /dev/null; then
			retry_count=$((retry_count-1))
			if [ "${retry_count}" -eq "0" ]; then
				echo "[warn] Wait for SimpleTorrent process to start aborted, too many retries"
				echo "[warn] Showing output from command before exit..."
				timeout 10 /usr/local/bin/simple-torrent -t "${simpletorrent_title}" -c /config/simple-torrent.yaml > /config/simpletorrent.log 2>&1 &
				cat /config/simpletorrent.log ; exit 1
			else
				if [[ "${DEBUG}" == "true" ]]; then
					echo "[debug] Waiting for SimpleTorrent process to start..."
				fi
				sleep 1s
			fi
		else
			echo "[info] SimpleTorrent process started"
			break
		fi

	done

	echo "[info] Waiting for SimpleTorrent process to start listening on port 3000..."

	while [[ $(netstat -lnt | awk "\$6 == \"LISTEN\" && \$4 ~ \".3000\"") == "" ]]; do
		sleep 0.1
	done

	echo "[info] SimpleTorrent process listening on port 3000"
fi

# change incoming port
if [[ "${VPN_PROV}" == "pia" && -n "${VPN_INCOMING_PORT}" ]]; then
	# set incoming port
	yq -Y ".incomingport=${VPN_INCOMING_PORT}" /config/simple-torrent.yaml | sponge /config/simple-torrent.yaml

	# set SimpleTorrent port to current vpn port (used when checking for changes on next run)
	simpletorrent_port="${VPN_INCOMING_PORT}"
fi

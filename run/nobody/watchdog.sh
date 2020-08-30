#!/bin/bash

# if SimpleTorrent config file doesnt exist then copy stock config file
if [[ ! -f /config/simple-torrent.yaml ]]; then
	echo "[info] SimpleTorrent config file doesn't exist, copying default..."
	cp /home/nobody/simpletorrent/simple-torrent.yaml /config/
fi

# set default values for port
simpletorrent_port=`cat /config/simple-torrent.yaml | yq .incomingport`

# set value for title, default if unset
simpletorrent_title=${SIMPLETORRENT_TITLE:-SimpleTorrent}

# define sleep period between loops
sleep_period_secs=30

# define sleep period between incoming port checks
sleep_period_incoming_port_secs=1800

# sleep period counter - used to limit number of hits to external website to check incoming port
sleep_period_counter_secs=0

# while loop to check ip and port
while true; do
	# reset triggers to negative values
	simpletorrent_running="false"
	privoxy_running="false"
	simpletorrent_port_change="false"

	if [[ "${VPN_ENABLED}" == "yes" ]]; then
		# run script to get all required info
		source /home/nobody/preruncheck.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then
			# check if SimpleTorrent is running
			if ! pgrep -fa "simple-torrent" > /dev/null; then
				echo "[info] SimpleTorrent not running"
			else
				simpletorrent_running="true"
			fi

			if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then
				# check if privoxy is running, if not then skip shutdown of process
				if ! pgrep -fa "/usr/bin/privoxy" > /dev/null; then
					echo "[info] Privoxy not running"
				else
					# mark as privoxy as running
					privoxy_running="true"
				fi
			fi

			if [[ "${VPN_PROV}" == "pia" ]]; then
				# if vpn port is not an integer then dont change port
				if [[ ! "${VPN_INCOMING_PORT}" =~ ^-?[0-9]+$ ]]; then
					# set vpn port to current SimpleTorrent port, as we currently cannot detect incoming port (line saturated, or issues with pia)
					VPN_INCOMING_PORT="${simpletorrent_port}"
					# ignore port change as we cannot detect new port
					simpletorrent_port_change="false"
				else
					if [[ "${simpletorrent_running}" == "true" ]]; then
						if [ "${sleep_period_counter_secs}" -ge "${sleep_period_incoming_port_secs}" ]; then
							# run script to check incoming port is accessible
							source /home/nobody/checkextport.sh
							# reset sleep period counter
							sleep_period_counter_secs=0
						fi
					fi

					if [[ "${simpletorrent_port}" != "${VPN_INCOMING_PORT}" ]]; then
						echo "[info] SimpleTorrent incoming port $simpletorrent_port and VPN incoming port ${VPN_INCOMING_PORT} different, marking for reconfigure"

						# mark as reconfigure required due to mismatch
						simpletorrent_port_change="true"
					fi
				fi
			fi

			if [[ "${simpletorrent_port_change}" == "true" || "${simpletorrent_running}" == "false" ]]; then
				# run script to start SimpleTorrent
				source /home/nobody/simpletorrent.sh
			fi

			if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then
				if [[ "${privoxy_running}" == "false" ]]; then
					# run script to start privoxy
					source /home/nobody/privoxy.sh
				fi
			fi
		else
			echo "[warn] VPN IP not detected, VPN tunnel maybe down"
		fi
	else
		# check if SimpleTorrent is running
		if ! pgrep -fa "simple-torrent" > /dev/null; then
			echo "[info] SimpleTorrent not running"
		else
			simpletorrent_running="true"
		fi

		if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then
			# check if privoxy is running, if not then start via privoxy.sh
			if ! pgrep -fa "/usr/bin/privoxy" > /dev/null; then
				echo "[info] Privoxy not running"
				# run script to start privoxy
				source /home/nobody/privoxy.sh
			fi

		fi

		if [[ "${simpletorrent_running}" == "false" ]]; then
			# run script to start SimpleTorrent
			source /home/nobody/simpletorrent.sh
		fi
	fi

	if [[ "${DEBUG}" == "true" && "${VPN_ENABLED}" == "yes" ]]; then
		if [[ "${VPN_PROV}" == "pia" && -n "${VPN_INCOMING_PORT}" ]]; then
			echo "[debug] VPN incoming port is ${VPN_INCOMING_PORT}"
			echo "[debug] SimpleTorrent incoming port is ${simpletorrent_port}"
		fi
		echo "[debug] VPN IP is ${vpn_ip}"
	fi

	# increment sleep period counter - used to limit number of hits to external website to check incoming port
	sleep_period_counter_secs=$((sleep_period_counter_secs+"${sleep_period_secs}"))
	sleep "${sleep_period_secs}"s
done

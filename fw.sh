#!/bin/sh

##########################
# Setup the Firewall rules
##########################
fw_setup() {
  # First we added a new chain called 'REDSOCKS' to the 'nat' table.
  iptables -t nat -N REDSOCKS

  # Next we used "-j RETURN" rules for the networks we don’t want to use a proxy.
  # while read item; do
  #     iptables -t nat -A REDSOCKS -d $item -j RETURN
  # done < /etc/redsocks-whitelist.txt
  iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
  iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 198.18.0.0/15 -j RETURN
  iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

  # We then told iptables to redirect all port 80 connections to the http-relay redsocks port and all other connections to the http-connect redsocks port.
  # iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to-ports 12345
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $port

  # Finally we tell iptables to use the ‘REDSOCKS’ chain for all outgoing connection in the network interface ‘eth0′.
  iptables -t nat -A PREROUTING -i $device -p tcp -j REDSOCKS
}

##########################
# Clear the Firewall rules
##########################
fw_clear() {
  iptables-save | grep -v REDSOCKS | iptables-restore
  #iptables -L -t nat --line-numbers
  #iptables -t nat -D PREROUTING 2
}

usage() {
  echo "Usage: $0 {device} {port} {start|stop}"
}

if [ $# -ne 3 ]; then
    usage
    exit 1
fi

device="$1"
port="$2"

case "$3" in
    start)
        echo -n "Setting REDSOCKS firewall rules for interface $device... "
        fw_clear
        fw_setup
        echo "done."
        ;;
    stop)
        echo -n "Cleaning REDSOCKS firewall rules for interface $device... "
        fw_clear
        echo "done."
        ;;
    *)
        usage
        exit 1
        ;;
esac
exit 0

#!/bin/bash

# Infer the device name from the IP address
args=("$@")
for i in $(seq 0 $#); do
    case ${args[$i]} in
        -a)
        ip=${args[$i+1]}
        ;;

        -a=*)
        arg=${args[$i]}
        ip=${arg#*=}
        ;;

        -t)
        proxy=${args[$i+1]}
        ;;

        -t=*)
        arg=${args[$i]}
        proxy=${arg#*=}
        ;;

        -p)
        port=${args[$i+1]}
        ;;

        -p=*)
        arg=${args[$i]}
        port=${arg#*=}
        ;;

    esac
done

if [ -z "$proxy" ]; then
    if [ ! -z "$http_proxy" ]; then
        proxy="$http_proxy"
    else
        echo "No proxy specified, defaulting to http://localhost:3128"
        proxy="http://localhost:3128"
    fi
fi

if [ -z "$ip" ]; then
    echo "No listening address specified, defaulting to 127.0.0.1"
    ip="127.0.0.1"
fi

if [ -z "$port" ]; then
    echo "No listening port specified, defaulting to 12345"
    port="12345"
fi

device=$(/sbin/ifconfig | grep -B1 $ip | grep -o "^\w*")
proxy_host=$(echo $proxy | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")
proxy_port=$(echo $proxy | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\)\(:\([0-9]\{1,5\}\)\)\?.*/\4/")

echo "Creating redsocks configuration file using proxy ${proxyHost}:${proxyPort}..."
sed -e "s|\${proxy_ip}|${proxy_host}|" \
    -e "s|\${proxy_port}|${proxy_port}|" \
    -e "s|\${ip}|${ip}|" \
    -e "s|\${port}|${port}|" \
    /etc/redsocks.tmpl > /tmp/redsocks.conf

echo "Generated configuration:"
cat /tmp/redsocks.conf

/fw.sh $device $port start

pid=0

# SIGUSR1 handler
usr_handler() {
  echo "usr_handler"
}

# SIGTERM-handler
term_handler() {
    if [ $pid -ne 0 ]; then
        echo "Term signal catched. Shutdown redsocks and disable iptables rules..."
        kill -SIGTERM "$pid"
        wait "$pid"
        /fw.sh $device $port stop
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
trap 'kill ${!}; usr_handler' SIGUSR1
trap 'kill ${!}; term_handler' INT QUIT TERM

echo "Starting redsocks..."
/usr/local/bin/redsocks -c /tmp/redsocks.conf &
pid="$!"

# wait indefinetely
while true
do
    tail -f /dev/null & wait ${!}
done

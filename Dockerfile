FROM alpine:3.7

MAINTAINER Wheeler Law <whelderwheels613@gmail.com>

# Proxy settings might need to be set to run the container: (preferred)
# docker run --net=host -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" --rm -it alpine sh
# OR (assumes that Cntlm can listen on Docker's bridge interface)
# docker run -e "http_proxy=http://`ip addr show docker0 | sed -n 's/.*inet \([0-9.]\+\)\/.*/\1/p'`:3128" -e "https_proxy=http://`ip addr show docker0 | sed -n 's/.*inet \([0-9.]\+\)\/.*/\1/p'`:3128" --rm -it alpine sh

RUN apk update && apk add build-base curl libevent-dev iptables-dev bash ca-certificates \
  && curl -fsSL https://github.com/darkk/redsocks/archive/release-0.5.tar.gz | tar xz \
  && make -C redsocks-release-0.5/

# Use a multi-stage build to cut down on image size
FROM alpine:3.7
RUN apk --no-cache add iptables bash ca-certificates libevent
COPY --from=0 redsocks-release-0.5/redsocks /usr/local/bin

COPY redsocks.tmpl /etc/redsocks.tmpl
COPY entrypoint.sh /entrypoint.sh
COPY fw.sh /fw.sh

ENTRYPOINT ["/entrypoint.sh"]

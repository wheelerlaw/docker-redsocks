# docker-redsocks

Wraps [redsocks](https://github.com/darkk/redsocks) in an easy to use Docker image. 

### Usage

To run:

```
docker run --net=host --privileged wheelerlaw/redsocks <proxy-host> <proxy-port>
```

### Building

To build the image:

```
docker build .
```

If you are trying to build the image while behind a proxy, you can specify the proxy server:

```
docker build --build-arg "http_proxy=<proxy-URL>" --build-arg "https_proxy=<proxy-URL>" .
```

Or if your proxy host is defined in a local environment variable (`http_proxy`):

```
docker build --build-arg http_proxy --build-arg https_proxy .
```

If `http_proxy` is set to `http://localhost:3128` (if you are connecting through Cntlm for example), then it is likely the above commands won't work. You will need to tell the Docker daemon to use the host network stack:

```
docker build --build-arg http_proxy --build-arg https_proxy --network=host .
```

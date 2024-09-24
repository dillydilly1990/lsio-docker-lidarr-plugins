# syntax=docker/dockerfile:1
FROM --platform=$TARGETPLATFORM docker.io/library/node:21-alpine as deemix

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "Building for TARGETPLATFORM=$TARGETPLATFORM | BUILDPLATFORM=$BUILDPLATFORM"
RUN apk add --no-cache git jq python3 make gcc musl-dev g++ && \
    rm -rf /var/lib/apt/lists/*
RUN git clone --recurse-submodules https://gitlab.com/RemixDev/deemix-gui.git
WORKDIR deemix-gui
RUN case "$TARGETPLATFORM" in \
        "linux/amd64") \
            jq '.pkg.targets = ["node16-alpine-x64"]' ./server/package.json > tmp-json ;; \
        "linux/arm64") \
            jq '.pkg.targets = ["node16-alpine-arm64"]' ./server/package.json > tmp-json ;; \
        *) \
            echo "Platform $TARGETPLATFORM not supported" && exit 1 ;; \
    esac && \
    mv tmp-json /deemix-gui/server/package.json
RUN yarn install-all
# Patching deemix: see issue https://github.com/youegraillot/lidarr-on-steroids/issues/63
RUN sed -i 's/const channelData = await dz.gw.get_page(channelName)/let channelData; try { channelData = await dz.gw.get_page(channelName); } catch (error) { console.error(`Caught error ${error}`); return [];}/' ./server/src/routes/api/get/newReleases.ts
RUN yarn dist-server
RUN mv /deemix-gui/dist/deemix-server /deemix-server

FROM ghcr.io/linuxserver/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG LIDARR_RELEASE
LABEL build_version="Linuxserver.io custom build:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="dillydilly"

# environment settings
ARG LIDARR_BRANCH="plugins"
ENV XDG_CONFIG_HOME="/config/xdg" \
  COMPlus_EnableDiagnostics=0 \
  TMPDIR=/run/lidarr-temp

RUN \
  echo "**** install packages ****" && \
  apk add -U --upgrade --no-cache \
    chromaprint \
    icu-libs \
    sqlite-libs \
    xmlstarlet && \
  echo "**** install lidarr ****" && \
  mkdir -p /app/lidarr/bin && \
  if [ -z ${LIDARR_RELEASE+x} ]; then \
    LIDARR_RELEASE=$(curl -sL "https://lidarr.servarr.com/v1/update/${LIDARR_BRANCH}/changes?runtime=netcore&os=linuxmusl" \
    | jq -r '.[0].version'); \
  fi && \
  curl -o \
    /tmp/lidarr.tar.gz -L \
    "https://lidarr.servarr.com/v1/update/${LIDARR_BRANCH}/updatefile?version=${LIDARR_RELEASE}&os=linuxmusl&runtime=netcore&arch=x64" && \
  tar xzf \
    /tmp/lidarr.tar.gz -C \
    /app/lidarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${LIDARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/lidarr/package_info && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /app/lidarr/bin/Lidarr.Update \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
VOLUME ["/config", "/music"]
EXPOSE 6595 8686

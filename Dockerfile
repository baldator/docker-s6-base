FROM i386/alpine:3.10

ENV PUID=1000
ENV PGID=1000

ENV S6_OVERLAY_RELEASE v1.22.1.0
ENV TMP_BUILD_DIR /tmp/build

# Pull in the overlay binaries
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-nobin.tar.gz ${TMP_BUILD_DIR}/
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-nobin.tar.gz.sig ${TMP_BUILD_DIR}/

# Pull in the trust keys
COPY keys/trust.gpg ${TMP_BUILD_DIR}/

# Patch in source for testing sources...
# Update, install necessary packages, fixup permissions, delete junk
RUN apk add --update s6 s6-portable-utils && \
    apk add --virtual verify gnupg && \
    chmod 700 ${TMP_BUILD_DIR} && \
    cd ${TMP_BUILD_DIR} && \
    gpg --no-options --no-default-keyring --homedir ${TMP_BUILD_DIR} --keyring ./trust.gpg --no-auto-check-trustdb --trust-model always --verify s6-overlay-nobin.tar.gz.sig s6-overlay-nobin.tar.gz && \
    apk del verify && \
    tar -C / -xzf s6-overlay-nobin.tar.gz && \
    cd / && \
    rm -rf /var/cache/apk/* && \
    rm -rf ${TMP_BUILD_DIR}

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
        curl \
        tar && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
        bash \
        ca-certificates \
        coreutils \
        shadow \
        tzdata && \
 echo "**** create abc user and make our folders ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
        /app \
        /config \
        /defaults && \
 echo "**** cleanup ****" && \
 apk del --purge \
        build-dependencies && \
 rm -rf \
        /tmp/*

ENTRYPOINT [ "/init" ]
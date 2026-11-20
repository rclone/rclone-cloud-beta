# The image of an rclone Cloud release, laid out like rclone's
# (https://github.com/rclone/rclone/blob/master/Dockerfile). The release workflow puts each
# platform's release binary in the build context as <arch>/rclone-cloud, with the release's LICENSE
# and THIRD_PARTY_NOTICES.
FROM alpine:3.24

ARG TARGETARCH
ARG RCLONE_UID=1009
ARG RCLONE_GID=1009

RUN echo "**** Install Dependencies ****" && \
    apk add --no-cache \
        ca-certificates \
        fuse3 \
        mailcap \
        tzdata && \
    echo "Enable user_allow_other in fuse" && \
    echo "user_allow_other" >> /etc/fuse.conf

COPY ${TARGETARCH}/rclone-cloud /usr/local/bin/
COPY ${TARGETARCH}/LICENSE ${TARGETARCH}/THIRD_PARTY_NOTICES /usr/share/doc/rclone-cloud/

RUN echo "**** Print Version Binary ****" && \
    rclone-cloud version

RUN addgroup -g "${RCLONE_GID}" rclone && adduser -u "${RCLONE_UID}" -Ds /bin/sh -G rclone rclone && \
    install -d -o rclone -g rclone /config /data && \
    install -d -o rclone -g rclone -m 0700 /config/rclone-cloud /config/key

# Unlike rclone's image, not root: every account with file access works on the disk as this user.
USER rclone

ENTRYPOINT [ "rclone-cloud" ]
CMD [ "serve" ]

WORKDIR /data
ENV XDG_CONFIG_HOME=/config \
    RCLONE_CLOUD_DATA_DIR=/config/rclone-cloud \
    RCLONE_CLOUD_BIND=0.0.0.0:5573
EXPOSE 5573

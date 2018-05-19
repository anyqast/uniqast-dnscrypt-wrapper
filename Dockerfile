FROM alpine:edge
RUN apk upgrade --no-cache \
 && apk add --no-cache libsodium libevent make autoconf gcc musl-dev bsd-compat-headers libevent-dev libsodium-dev supervisor \
 && wget -O- https://github.com/cofyc/dnscrypt-wrapper/archive/v0.4.1.tar.gz | tar -xz \
 && cd dnscrypt-wrapper-0.4.1/ \
 && make \
 && make install \
 && cd .. \
 && rm -rf dnscrypt-wrapper-0.4.1/
ADD files /
ENV DNSCRYPT_HOST_PORTS="0.0.0.0 8443" \
    DNSCRYPT_CERT_FILE_EXPIRE_DAYS="1h" \
    DNSCRYPT_CERT_FILE_ROTATION_INTERVAL="3300" \
    DNSCRYPT_CERT_FILE_ROTATION_TIMEOUT="300" \
    DNSCRYPT_CERT_FILE_HISTORY_SIZE="24" \
    DNSCRYPT_PROVIDER_NAME="dnscrypt.info"
CMD ["/boot.sh"]
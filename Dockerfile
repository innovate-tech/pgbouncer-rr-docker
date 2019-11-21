FROM alpine AS builder

ARG VERSION=1.12.0

RUN apk add -U --no-cache build-base libevent-dev c-ares-dev libressl-dev python2-dev patch

WORKDIR /tmp
RUN wget https://pgbouncer.github.io/downloads/files/$VERSION/pgbouncer-$VERSION.tar.gz && \
    wget https://github.com/innovate-tech/pgbouncer-rr-patch/archive/v$VERSION.tar.gz && \
    tar -xf pgbouncer-$VERSION.tar.gz && tar -xf v$VERSION.tar.gz  && \
    rm pgbouncer-$VERSION.tar.gz && rm v$VERSION.tar.gz

WORKDIR /tmp/pgbouncer-rr-patch-$VERSION
RUN sh install-pgbouncer-rr-patch.sh /tmp/pgbouncer-$VERSION

WORKDIR /tmp/pgbouncer-$VERSION
RUN ./configure --prefix=/usr/local && make && make install

WORKDIR /tmp/rootfs
RUN mkdir -p usr/bin usr/lib lib && \
    cp /usr/local/bin/pgbouncer usr/bin && \
    for lib in $(ldd usr/bin/pgbouncer | awk '{ print $(NF-1) }'); do \
    cp $lib .$lib; \
    done

FROM busybox

COPY --from=builder /tmp/rootfs /

RUN adduser -D -S pgbouncer && \
    mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer && \
    chown pgbouncer /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer
USER pgbouncer

VOLUME /etc/pgbouncer

EXPOSE 6432

CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]

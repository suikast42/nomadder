ARG PULL_REGISTRY
ARG TIMESCALE_VERSION
#FROM ${docker.registry}/timescale/timescaledb:${container.module.version}-pg14
FROM ${PULL_REGISTRY}/timescale/timescaledb-ha:pg16.1-ts${TIMESCALE_VERSION}-all as builder


#timescaledb-ha image contains timescaledb-tune
USER root
#RUN  apt update && \
#     apt install dos2unix

RUN curl "https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2024-01-13T08-44-48Z" \
                -o /usr/local/bin/mc
RUN chmod 744 /usr/local/bin/mc
RUN chown postgres:postgres /usr/local/bin/mc
RUN mkdir -p /home/postgres/.mc
RUN chown -R postgres:postgres /home/postgres
RUN mc --version
COPY backup.sh /usr/bin/backup.sh
RUN chown -R postgres:postgres /usr/bin/backup.sh
RUN chmod 744 /usr/bin/backup.sh
COPY restore.sh /usr/bin/restore.sh
RUN chown -R postgres:postgres /usr/bin/restore.sh
RUN chmod 744 /usr/bin/restore.sh
USER postgres

#/usr/bin/dos2unix

FROM ${PULL_REGISTRY}/timescale/timescaledb-ha:pg16.1-ts${TIMESCALE_VERSION}-all
COPY --from=builder /usr/local/bin/mc /usr/local/bin/mc
COPY --from=builder /home/postgres /home/postgres
COPY --from=builder /usr/bin/backup.sh /usr/bin/backup.sh
COPY --from=builder /usr/bin/restore.sh /usr/bin/restore.sh
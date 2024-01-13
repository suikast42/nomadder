ARG PULL_REGISTRY="NotSet"
ARG MINIO_CLI_VERSION="NotSet"
ARG MSSQL_VERSION="NotSet"

FROM  ${PULL_REGISTRY}/mssql/server:${MSSQL_VERSION} as builder
USER root
RUN apt update
RUN #apt-cache policy curl
RUN apt install --yes  curl
RUN curl "https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2024-01-13T08-44-48Z" \
                -o /usr/local/bin/mc
RUN chmod 744 /usr/local/bin/mc
RUN chown mssql:mssql /usr/local/bin/mc
RUN mkdir -p /home/mssql/.mc
RUN chown -R mssql:mssql /home/mssql
RUN mc --version
COPY backup.sh /usr/local/bin/backup.sh
RUN chown -R mssql:mssql /usr/local/bin/backup.sh
RUN chmod 744 /usr/local/bin/backup.sh
COPY restore.sh /usr/local/bin/restore.sh
RUN chown -R mssql:mssql /usr/local/bin/restore.sh
RUN chmod 744 /usr/local/bin/restore.sh

FROM  ${PULL_REGISTRY}/mssql/server:${MSSQL_VERSION}
COPY --from=builder /usr/local/bin/mc /usr/local/bin/mc
COPY --from=builder /home/mssql /home/mssql
COPY --from=builder /usr/local/bin/backup.sh /usr/local/bin/backup.sh
COPY --from=builder /usr/local/bin/restore.sh /usr/local/bin/restore.sh
#mssql:x:10001:10001::/home/mssql:/bin/bashdockerfile
ARG PULL_REGISTRY=registry.amovacloud.io
ARG IMAGE="not set"
FROM $PULL_REGISTRY/$IMAGE

MAINTAINER Süleyman Vurucu <sueleyman.vurucu@amova.eu>

USER root
RUN apt  -y update && apt  -y install jq
USER jenkins
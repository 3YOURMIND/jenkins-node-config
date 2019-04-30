FROM alpine as docker-cli

ENV DOCKER_VERSION=18.09.5
ENV PYTHON_VERSION 3.6.5
ENV PYTHON_RELEASE 3.6.5

RUN wget "https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz" -O docker.tgz

RUN tar -xzvf docker.tgz


FROM jenkins/jnlp-slave:alpine

USER root

COPY --from=docker-cli /docker/docker /usr/bin/docker
RUN apk add py-pip curl && pip install awscli
RUN pip install bandit

USER jenkins

ENV USER=jenkins

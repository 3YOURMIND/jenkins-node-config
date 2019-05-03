FROM alpine as docker-cli

ENV DOCKER_VERSION=18.09.5

RUN wget "https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz" -O docker.tgz

RUN tar -xzvf docker.tgz

FROM jenkins/jnlp-slave:alpine

USER root

COPY --from=docker-cli /docker/docker /usr/bin/docker

RUN apk add py3-pip curl nodejs nodejs-npm && pip3 install awscli
RUN pip3 install bandit
RUN npm install -g swagger-cli

USER jenkins

ENV USER=jenkins

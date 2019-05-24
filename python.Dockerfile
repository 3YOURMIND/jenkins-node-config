FROM jenkins/jnlp-slave:alpine

ENV SCANNER_VERSION 3.3.0.1492
ENV DOCKER_VERSION=18.09.5

USER root

# Install the docker engine
RUN wget "https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz" -O docker.tgz
RUN tar -xzvf docker.tgz && rm docker.tgz
RUN cp /home/jenkins/docker/docker /usr/bin/docker

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SCANNER_VERSION.zip
RUN mkdir /usr/bin/sonar-scanner && unzip sonar-scanner-cli-$SCANNER_VERSION.zip && cp -r sonar-scanner-${SCANNER_VERSION}/* /usr/bin/sonar-scanner/
RUN rm sonar-scanner-cli-$SCANNER_VERSION.zip && rm -r sonar-scanner-${SCANNER_VERSION}

RUN apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev libffi-dev openssl-dev libgcc make

RUN apk add nodejs nodejs-npm py3-pip openjdk8-jre-base
RUN npm install -g swagger-cli cowsay && pip3 install awscli bandit pycodestyle docker-compose

RUN apk --purge del .build-deps

USER jenkins

ENV USER=jenkins

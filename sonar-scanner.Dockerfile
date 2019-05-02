FROM openjdk:13-ea-16-jdk-alpine3.9
ENV SCANNER_VERSION 3.3.0.1492
ENV PROJECT ""
ENV SONAR_TOKEN ""

RUN apk add --no-cache git

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492.zip
RUN unzip sonar-scanner-cli-3.3.0.1492.zip

WORKDIR /home/code
ENTRYPOINT ../../sonar-scanner-cli-3.3.0.1492/bin/sonar-scanner \
    -Dsonar.projectKey=${PROJECT} \
    -Dsonar.sources=${PWD} \
    -Dsonar.host.url=https://sonar.internal.3yourmind.com \
    -Dsonar.login=${SONAR} \
    -Dsonar.analysis.scmRevision="$(git rev-parse HEAD)" \
    -Dsonar.projectVersion="$(cat version)"
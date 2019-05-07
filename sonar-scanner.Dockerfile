FROM openjdk:8u201-jdk-alpine3.9
ENV SCANNER_VERSION 3.3.0.1492
ENV PROJECT ""
ENV SONAR_TOKEN ""
ENV BRANCH_NAME ""

RUN apk add --no-cache git nodejs nodejs-npm py3-pip bash
RUN npm install -g swagger-cli
RUN pip3 install bandit pycodestyle

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SCANNER_VERSION.zip
RUN unzip sonar-scanner-cli-$SCANNER_VERSION.zip -d /home/bin
CMD ./sonar-scanner-${SCANNER_VERSION}/bin/sonar-scanner \
    -Dsonar.projectKey=${PROJECT} \
    -Dsonar.sources=${PWD} \
    -Dsonar.host.url=https://sonar.internal.3yourmind.com \
    -Dsonar.login=${SONAR_TOKEN} \
    -Dsonar.analysis.scmRevision=${BRANCH_NAME}} \
    -Dsonar.projectVersion="$(cat version)"

ENTRYPOINT [ "/bin/bash", "-c"]
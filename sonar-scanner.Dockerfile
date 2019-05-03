FROM openjdk:8u201-jdk-alpine3.9
ENV SCANNER_VERSION 3.3.0.1492
ENV PROJECT ""
ENV SONAR_TOKEN ""
ENV BRANCH_NAME ""

RUN apk add --no-cache git nodejs nodejs-npm py3-pip bash
RUN npm install -g swagger-cli
RUN pip3 install bandit pycodestyle

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SCANNER_VERSION.zip
RUN mkdir /home/bin
RUN unzip sonar-scanner-cli-$SCANNER_VERSION.zip -d /home/bin

WORKDIR /home/code
#ENTRYPOINT [ "/bin/bash" ]
#CMD ["ls", "-lah"]

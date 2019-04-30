FROM alpine
ENV SCANNER_VERSION 3.3.0.1492

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SCANNER_VERSION-linux.zip
RUN unzip sonar-scanner-cli-3.3.0.1492-linux.zip


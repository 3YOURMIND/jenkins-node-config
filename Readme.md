# Jenkins docker swarm-node configs

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/3yourmind/jenkins-node-config?style=for-the-badge)

This repo includes Dockerfiles used to provide the necessary dependencies to Jenkins nodes.

#### Dockerfile:
This dockerfile includes the configuration for nodes running a python build script.
It is pre-configured to use python 3.6.
It also includes the docker-cli in order to run docker commands.

#### sonar-scanner.Dockerfile:
This image is a general purpose script to test a code base with the sonar-scanner. It will automatically execute
and analyze code that is mounted into it's `/home/code` directory.
It relies on being provided with the `PROJECT_NAME`, the `SONAR_TOKEN` & the `BRANCH_NAME` via the -e tag.

You can use it wherever you have the docker-cli implemented: 
`docker run -it -v $(pwd)/.:/home/code -e PROJECT=${PROJECT} -e SONAR_TOKEN=$SONAR_TOKEN -e BRANCH_NAME=${BRANCH_NAME} 3yourmind/sonar-scanner:latest sh`

#### cpp-compile.Dockerfile
A Docker image for generic cpp compilation. contains latest gcc and cmake compiled from sources


#### /vars:
Contains a groovyscript file that is used as shared library between all pipelines.
It contains useful functions that are used to interact with AWS, git or to publish built images.

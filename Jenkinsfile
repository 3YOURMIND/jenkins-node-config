// Jenkinsfile for the 3yd-cpp build

node ('docker'){
    stage('Setup') {
      checkout scm;
      helpers.ECRLogin()
    }
    stage('Build') {
      sh "docker build -t 854130308264.dkr.ecr.eu-central-1.amazonaws.com/3yd-cpp:latest -f cpp-compile.Dockerfile ."
    }
    stage('Push'){
      sh "docker push 854130308264.dkr.ecr.eu-central-1.amazonaws.com/3yd-cpp:latest"
    }
}
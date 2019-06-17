def isTagBuild() {
  gitOut = sh (
    script: "git --no-pager describe --exact-match || true",
    returnStdout: true
  ).trim()

  return !gitOut.startsWith("fatal:")
}

def getTagName() {
  gitOut = sh (
    script: "git --no-pager describe --exact-match || true",
    returnStdout: true
  ).trim()

  return gitOut.startsWith("fatal:") ? "" : gitOut
}

def ECRLogin(){
    sh "echo \$(aws ecr get-authorization-token --region eu-central-1 --output text --query 'authorizationData[].authorizationToken' | base64 -d | cut -d: -f2) | docker login -u AWS https://123456.dkr.ecr.eu-central-1.amazonaws.com --password-stdin"
}

def retagAndPushImage(String project, String branch_name, String tag){
  if (tag != "") {
    sh "docker tag ${project}:${branch_name} ${env.ECR_ENDPOINT}/${project}:${tag}"
    sh "docker push ${env.ECR_ENDPOINT}/${project}:${tag}"
  } else {
    sh "docker tag ${project}:${branch_name} ${env.ECR_ENDPOINT}/${project}:${branch_name}"
    sh "docker push ${env.ECR_ENDPOINT}/${project}:${branch_name}"
  }
}

return this
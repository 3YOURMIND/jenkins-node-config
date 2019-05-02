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
    sh "eval \$(aws ecr get-login --no-include-email --region eu-central-1)"
}

def retagAndPushImage(String tag){
  sh "docker tag ${PROJECT}:${BRANCH_NAME} ${env.ECR_ENDPOINT}/${PROJECT}:${tag}"
  sh "docker push ${env.ECR_ENDPOINT}/${PROJECT}:${tag}"
}

return this
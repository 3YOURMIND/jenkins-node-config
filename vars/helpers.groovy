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

def retagAndPushImage(String tag, String project){
  sh "docker tag ${tag}"
  sh "docker push ${env.ECR_ENDPOINT}/${project}:${tag}"
}

return this
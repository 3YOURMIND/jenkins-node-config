# run

docker run -it  -v $PWD:/home/code -e 'PROJECT=button3d' -e 'BRANCH_NAME=DEV-635-button3D-jenkins-ci' d1b2 /bin/bash -c "./devops/check_codehealth_py.sh"

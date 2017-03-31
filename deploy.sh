#!/bin/bash
set -e
export PROJECT_ID=core-gearbox-112418
export TREE_HASH=`git cat-file -p HEAD`
export TREE_HASH=${TREE_HASH:5:7}
export CONTAINER_TAG=$TREE_HASH

printer()
{
    echo -e "\033[0;33m$1\033[0m"
    # echo $1 | slacker -c dev-releases -t xoxp-11239767985-11233063075-26572878627-8d835d7a28
}

build_container()
{
    printer "Building $CONTAINER_TAG"
    docker build -t eu.gcr.io/$PROJECT_ID/passfort-help-center:$CONTAINER_TAG -f Dockerfile .
    sudo /opt/google-cloud-sdk/bin/gcloud docker push eu.gcr.io/$PROJECT_ID/passfort-help-center:$CONTAINER_TAG
}

deploy_container()
{
    printer "Deploying $CONTAINER_TAG"
    envsubst < passfort-help-center.yaml | kubectl replace --record -f - || envsubst < passfort-help-center.yaml | kubectl create --record -f -
}

# Switch to the correct cluster
sudo /opt/google-cloud-sdk/bin/gcloud config set container/cluster $CLUSTER_NAME
sudo /opt/google-cloud-sdk/bin/gcloud config set compute/zone $CLOUDSDK_COMPUTE_ZONE
sudo /opt/google-cloud-sdk/bin/gcloud container clusters get-credentials $CLUSTER_NAME

printer "Building Release *$CONTAINER_TAG*"
build_container
printer "Build completed"

printer "Deploying Release *$CONTAINER_TAG* to cluster *$CLUSTER_NAME* ($CLUSTER_NAME)."
deploy_container
printer "Deploy completed"

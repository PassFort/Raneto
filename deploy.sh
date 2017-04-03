#!/bin/bash
set -e
export PROJECT_ID=core-gearbox-112418
export TREE_HASH=`git cat-file -p HEAD`
export TREE_HASH=${TREE_HASH:5:7}
export CONTAINER_TAG=$TREE_HASH
export CLUSTER_NAME=production
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcloud-service-key.json

printer()
{
    echo -e "\033[0;33m$1\033[0m"
}

build_container()
{
    printer "Building $CONTAINER_TAG"
    sudo docker build -t eu.gcr.io/$PROJECT_ID/passfort-help-center:$CONTAINER_TAG -f Dockerfile .
    sudo /opt/google-cloud-sdk/bin/gcloud docker -- push eu.gcr.io/$PROJECT_ID/passfort-help-center:$CONTAINER_TAG
}

deploy_container()
{
    printer "Deploying $CONTAINER_TAG"
    envsubst < help-center-deployment.yaml | kubectl replace --validate=false --record -f - || envsubst < help-center-deployment.yaml | kubectl create --validate=false --record -f -
}

deploy_service()
{
    printer "Deploying service $CONTAINER_TAG"
    envsubst < help-center-service.yaml | kubectl replace --validate=false --record -f - || envsubst < help-center-service.yaml | kubectl create --validate=false --record -f -
}

# Switch to the correct cluster
sudo /opt/google-cloud-sdk/bin/gcloud config set container/cluster $CLUSTER_NAME
sudo /opt/google-cloud-sdk/bin/gcloud config set compute/zone europe-west1-b
sudo /opt/google-cloud-sdk/bin/gcloud config set project $PROJECT_ID
sudo /opt/google-cloud-sdk/bin/gcloud container clusters get-credentials $CLUSTER_NAME
sudo chmod 744 ~/.kube/config

printer "Building Release *$CONTAINER_TAG*"
build_container
printer "Build completed"

printer "Deploying Release *$CONTAINER_TAG* to cluster *$CLUSTER_NAME* ($CLUSTER_NAME)."
deploy_container
deploy_service
printer "Deploy completed"

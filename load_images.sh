#!/bin/bash

# Load the OCP images
# Modified from
# https://stackoverflow.com/questions/35575674/how-to-save-all-docker-images-and-copy-to-another-machine?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

docker load -i /tmp/repos/images/ocp_docker_images.tar

while read REPOSITORY TAG IMAGE_ID
do
        echo "== Tagging $REPOSITORY $TAG $IMAGE_ID =="
        docker tag "$IMAGE_ID" "$REPOSITORY:$TAG"
done < /tmp/repos/images/ocp_docker_images.list
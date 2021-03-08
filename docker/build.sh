#!/bin/sh
MY_DOCKER_IMAGE=sebsto/codebuild-swift
docker build -t $MY_DOCKER_IMAGE .
docker push $MY_DOCKER_IMAGE

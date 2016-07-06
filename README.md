# Docker LEMP stack for Drupal development

## Running the container

Basically you can run the container in two ways. The first one (classic) is exposing container services through explicit port mapping.
```bash
#! /bin/bash

PROJECTS_DIR=/var/docker/projects/
PROJECT_NAME=example

docker run -dit \
 -h $PROJECT_NAME \
 -p 80:80 \
 -v $PROJECTS_DIR/$PROJECT_NAME/www:/var/www \
 -v $PROJECTS_DIR/$PROJECT_NAME/mysql:/var/lib/mysql \
 --name $PROJECT_NAME \
  attr/drupal-lemp
```
Having this done you can access web server index page using the following url: http://localhost.

The second way is a bit more advanced. First you need to create custom network as follows:
```bash
docker network create \
  --ip-range=172.28.5.0/24 \
  --gateway=172.28.5.1 \
  my-net
```

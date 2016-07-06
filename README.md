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
  --subnet=172.28.0.0/16 \
  --gateway=172.28.0.254 \
  my-net
```
The IP addresses may be whatever you like.

```bash
#! /bin/bash

PROJECTS_DIR=/var/docker/projects/
PROJECT_NAME=example

docker run -dit \
 -h $PROJECT_NAME \
 -v $PROJECTS_DIR/$PROJECT_NAME/www:/var/www \
 -v $PROJECTS_DIR/$PROJECT_NAME/mysql:/var/lib/mysql \
 --net my-net \
 --ip 172.28.0.1 \
 --name $PROJECT_NAME \
  attr/drupal-lemp
```

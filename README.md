# Docker LEMP stack for Drupal development

## Running the container
```bash
#! /bin/bash

PROJECTS_DIR=/var/docker/projects/
PROJECT_NAME=example

docker run -it \
 -e "HOSTNAME=$PROJECT_NAME" \
 -p 3306:3406 \
 -p 80:80 \
 -p 35729:35729 \
 -v $PROJECTS_DIR/$PROJECT_NAME/www:/var/www \
 -v $PROJECTS_DIR/$PROJECT_NAME/mysql:/var/lib/mysql \
 --name $PROJECT_NAME \
  my/lemp
```

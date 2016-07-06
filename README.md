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
Having this done you can access web server index page by navigationg to the following url: http://localhost.

The second way is a bit more advanced.
First step is creating custom network:
```bash
#! /bin/bash

docker network create \
  --subnet=172.28.0.0/16 \
  --gateway=172.28.0.254 \
  my-net
```
Now the container can be created as follows:
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
The IP address may be whatever you like but make sure it belongs the subnet you have created before. You may want to write the IP address to you host file.
```bash
sudo echo '172.28.0.1 example.local' >> /etc/hosts
```

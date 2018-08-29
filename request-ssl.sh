#! /bin/bash

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout server.pem \
    -new \
    -keyout /etc/ssl/private/localhost.key \
    -out /etc/ssl/certs/localhost.crt \
    -subj /CN=localhost \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /usr/lib/ssl/openssl.cnf <(printf '[SAN]\nsubjectAltName=DNS:localhost')) \
    -sha256 \
    -days 365

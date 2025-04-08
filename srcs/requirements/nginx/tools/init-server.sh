#!/bin/bash

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/nginx.key \
	-out /etc/nginx/ssl/nginx.crt \
	-subj "/C=XX/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"

nginx -g "daemon off;"
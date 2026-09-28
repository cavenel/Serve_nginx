#!/bin/sh
# Startup script required by SciLifeLab Serve (must live in WORKDIR).
set -eu

mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

exec nginx -g 'daemon off;'

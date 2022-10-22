#!/bin/sh

# 启动redis
redis-server /etc/redis.conf --daemonize yes --pidfile /var/run/redis.pid --dir /data/redis

# 启动vscode server web
code-server serve-local --host 0.0.0.0 --port 80 --accept-server-license-terms --without-connection-token --server-data-dir=/app/vscode-server
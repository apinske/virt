#!/bin/sh
podman run --name mq -d --arch amd64 -e LICENSE=accept -e MQ_QMGR_NAME=QM1 -e MQ_APP_PASSWORD=passw0rd -e MQ_ADMIN_PASSWORD=passw0rd -p 1414:1414 -p 9443:9443 icr.io/ibm-messaging/mq:latest

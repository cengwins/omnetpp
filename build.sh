#!/bin/bash
VERSION=6.2.0
INET_VERSION=4.5.4
BUILDARCH=$(uname -m)
docker build --build-arg VERSION=$VERSION --build-arg INET_VERSION=$INET_VERSION --build-arg BUILDARCH=$BUILDARCH -t cengwins/omnetpp-$VERSION-inet-$INET_VERSION-$BUILDARCH .



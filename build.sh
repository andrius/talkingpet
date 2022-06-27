#!/bin/sh

docker build --pull --force-rm -t talkingpet --file ./Dockerfile .

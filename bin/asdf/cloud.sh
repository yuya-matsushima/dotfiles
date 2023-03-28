#!/bin/sh

asdf plugin add awscli
asdf install awscli latest
asdf global awscli latest

asdf plugin add gcloud
asdf install gcloud latest
asdf global gcloud latest

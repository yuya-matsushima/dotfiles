#!/bin/sh

asdf plugin add awscli
asdf install awscli latest
asdf set -u awscli latest

asdf plugin add gcloud
asdf install gcloud latest
asdf set -u gcloud latest

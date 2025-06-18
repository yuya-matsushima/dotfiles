#!/bin/sh

VERSION=openjdk-23

asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install java $VERSION
asdf set -u java $VERSION

#!/bin/sh

asdf plugin add kubectl
asdf install kubectl latest
asdf set -u kubectl latest

asdf plugin add kubectx
asdf install kubectx latest
asdf set -u kubectx latest

asdf plugin add kubeval
asdf install kubeval latest
asdf set -u kubeval latest

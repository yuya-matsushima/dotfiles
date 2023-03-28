#!/bin/sh

asdf plugin add kubectl
asdf install kubectl latest
asdf global kubectl latest

asdf plugin add kubectx
asdf install kubectx latest
asdf global kubectx latest

asdf plugin add kubeval
asdf install kubeval latest
asdf global kubeval latest

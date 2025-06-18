#!/bin/sh

asdf plugin add terraform
asdf install terraform latest
asdf set -u terraform latest

asdf plugin add tflint
asdf install tflint latest
asdf set -u tflint latest

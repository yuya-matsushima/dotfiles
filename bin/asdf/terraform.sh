#!/bin/sh

asdf plugin add terraform
asdf install terraform latest
asdf global terraform latest

asdf plugin add tflint
asdf install tflint latest
asdf global tflint latest

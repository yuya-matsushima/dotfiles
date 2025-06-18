#!/bin/sh

asdf plugin add golang
asdf install golang latest
asdf set -u golang latest

asdf plugin add golangci-lint
asdf install golangci-lint latest
asdf set -u golangci-lint latest

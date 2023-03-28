#!/bin/sh

asdf plugin add golang
asdf install golang latest
asdf global golang latest

asdf plugin add golangci-lint
asdf install golangci-lint latest
asdf global golangci-lint latest

#!/bin/sh

asdf plugin add nodejs
asdf install nodejs lts
asdf set -u nodejs lts

asdf plugin add pnpm
asdf install pnpm latest
asdf set -u pnpm latest

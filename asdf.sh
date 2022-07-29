#!/bin/zsh

asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add python
asdf plugin add terraform
asdf plugin add tflint
asdf plugin add golang
asdf plugin add golangci-lint
asdf plugin add rust
asdf plugin add awscli
asdf plugin add hugo
asdf plugin add kubectl
asdf plugin add kubectx
asdf plugin add kubeval
asdf plugin add gcloud

asdf install ruby latest
asdf global ruby latest

asdf install nodejs lts
asdf global nodejs lts

asdf install python latest
asdf global python latest

asdf install terraform latest
asdf global terraform latest
asdf install tflint latest
asdf global tflint latest

asdf install golang latest
asdf global golang latest
asdf install golangci-lint latest
asdf global golangci-lint latest

asdf install rust latest
asdf global rust latest

asdf install awscli latest
asdf global awscli latest

asdf install hugo latest
asdf global hugo latest

asdf install kubectl latest
asdf global kubectl latest
asdf install kubectx latest
asdf global kubectx latest
asdf install kubeval latest
asdf global kubeval latest

asdf install gcloud latest
asdf global gcloud latest

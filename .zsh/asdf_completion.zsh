[[ $(which aws) == *.asdf/shims/aws* ]] && complete -C aws_completer aws
[[ $(which terraform) == *.asdf/shims/terraform* ]] && complete -C terraform terraform
if [[ $(which gcloud) == *.asdf/shims/gcloud* ]]; then
  local gcloud_version=$(asdf current gcloud | grep -v Version | awk '{ print $2 }')
  source $HOME/.asdf/installs/gcloud/${gcloud_version}/path.zsh.inc
  source $HOME/.asdf/installs/gcloud/${gcloud_version}/completion.zsh.inc
fi

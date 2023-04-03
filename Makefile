.DEFAULT_GOAL := help

.PHONY: homebrew
homebrew: ## Install Homebrew
	sh ./bin/homebrew.sh

.PHONY: font
font: ## Install Fonts
	sh ./bin/homebrew/font.sh

.PHONY: cli
cli: font ## Install CLI Tools
	sh ./bin/homebrew/cli.sh
	sh ./bin/zsh_plugin.sh

.PHONY: app
app: ## Install Apps
	sh ./bin/homebrew/app.sh
	sh ./bin/vim_plugin.sh

.PHONY: main_machine
main_machine: ## Install Option Apps
	sh ./bin/homebrew/main_machine.sh

.PHONY: link
link: ## Set symlinks for configuration file
	sh ./bin/link.sh

.PHONY: unlink
unlink: ## Remove symlinks for configuration file
	sh ./bin/link.sh unlink

.PHONY: asdf_cloud
asdf_cloud: ## Install Cloud CLI Tools
	sh ./bin/asdf/cloud.sh

.PHONY: asdf_k8s
asdf_k8s: ## Install k8s Tools
	sh ./bin/asdf/kubernetes.sh

.PHONY: asdf_terraform
asdf_terraform: asdf_cloud ## Install Terraform Tools
	sh ./bin/asdf/terraform.sh

.PHONY: asdf_nodejs
asdf_nodejs: ## Install NodeJS
	sh ./bin/asdf/nodejs.sh

.PHONY: asdf_ruby
asdf_ruby: asdf_nodejs ## Install Ruby
	sh ./bin/asdf/ruby.sh

.PHONY: asdf_golang
asdf_golang: ## Install Golang
	sh ./bin/asdf/golang.sh

.PHONY: asdf_python
asdf_python: ## Install Python
	sh ./bin/asdf/python.sh

.PHONY: asdf_rust
asdf_rust: ## Install Rust
	sh ./bin/asdf/rust.sh

.PHONY: asdf_hugo
asdf_hugo: ## Install Hugo
	sh ./bin/asdf/hugo.sh

.PHONY: asdf_infra
asdf_infra: asdf_cloud asdf_k8s asdf_terraform ## Install Infra Tools

.PHONY: asdf_langs
asdf_langs: asdf_nodejs asdf_ruby asdf_golang asdf_python asdf_rust ## Install Languages

.PHONY: asdf
asdf: asdf_langs asdf_infra ## Install All asdf

.PHONY: mac
mac: ## Apply Macbook Setting
	sh ./bin/mac.sh

.PHONY: setup_develop
setup_develop: homebrew cli app link asdf_ruby asdf_python asdf_cloud mac ## *setup develop machine

.PHONY: setup
setup: homebrew cli app main_machine link asdf mac ## *setup main machine

help: ## HELP
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

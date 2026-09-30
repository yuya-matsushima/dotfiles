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

.PHONY: nvim_link
nvim_link: ## Create symlink for Neovim config
	ln -sfn $(PWD)/.config/nvim ~/.config/nvim

.PHONY: nvim_unlink
nvim_unlink: ## Remove Neovim config symlink
	rm -rf ~/.config/nvim

.PHONY: nvim_plugin
nvim_plugin: ## Install Neovim plugins
	nvim --headless "+Lazy! sync" +qa

.PHONY: nvim_test
nvim_test: ## Test Neovim configuration
	nvim --headless "+checkhealth" +qa

.PHONY: claude_code
claude_code: ## Install Claude Code CLI
	sh ./bin/claude_code.sh

.PHONY: mise
mise: ## Install all tools defined in mise config
	mise install
	mise exec -- sh ./bin/languages/golang.sh

.PHONY: mise_langs
mise_langs: ## Install languages
	mise install node pnpm ruby python go golangci-lint rust
	mise exec -- sh ./bin/languages/golang.sh

.PHONY: mise_infra
mise_infra: ## Install infra tools
	mise install aws-cli gcloud aws-sam kubectl kubectx kubeval terraform tflint

.PHONY: mise_develop
mise_develop: ## Install tools for develop machine
	mise install node ruby python aws-cli gcloud

.PHONY: mise_upgrade
mise_upgrade: ## Upgrade mise tools and bump config versions
	mise upgrade --bump

.PHONY: mac
mac: ## Apply Macbook Setting
	sh ./bin/mac.sh

.PHONY: agent_hooks
agent_hooks: ## Install AI agent status hooks (Claude Code / Codex / OpenCode)
	sh ./bin/agent_hooks.sh

.PHONY: agent_hooks_uninstall
agent_hooks_uninstall: ## Uninstall AI agent status hooks
	sh ./bin/agent_hooks.sh uninstall

.PHONY: setup_develop
setup_develop: homebrew cli app link mise_develop mac ## *setup develop machine

.PHONY: setup
setup: homebrew cli app main_machine link mise mac ## *setup main machine

help: ## HELP
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

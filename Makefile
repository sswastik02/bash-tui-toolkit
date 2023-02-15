SHELL := /bin/bash
.PHONY: help

help: ## Display this help page
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-30s\033[0m %s\n", $$1, $$2}'

lint: ## Lint files with shellcheck
	@find src/*.sh -type f -exec "shellcheck" "-x" {} \;

generate-docs: ## Build documentation using docker container
	@docker build . -t bash-tui-toolkit/shdoc -f .development/docs/Dockerfile
	@docker run --rm  bash-tui-toolkit/shdoc 'shdoc < logging.sh ' 2>&1 > docs/modules/Logging.md
	@docker run --rm  bash-tui-toolkit/shdoc 'shdoc < prompts.sh ' 2>&1 > docs/modules/Prompts.md
	@docker run --rm  bash-tui-toolkit/shdoc 'shdoc < user_feedback.sh ' 2>&1 > docs/modules/User-Feedback.md

_remove_comments_from_file:
	@cat $(file) | sed '/^$$/d' | sed '/^#/d' | sed '/^\s*#/d' | tee $(file) > /dev/null

_push_module:
	echo "=> Push module $(module)"
	cp src/$(module).sh dist/$(module).sh
	@$(MAKE) _remove_comments_from_file file=dist/$(module).sh

build: ## Bundle script to dist folder and remove all top level comments
	@echo "=> Create dist folder"
	@rm -rf dist || true
	@mkdir dist/
	@echo "=> Create builder image"
	@docker build . -t bash-tui-toolkit/builder -f .development/build/Dockerfile
	@echo "=> Bundle and remove comments from target files"
	@docker run --rm bash-tui-toolkit/builder 'bash_bundler bundle --entry src/main.sh --output /dev/stderr' 2>dist/bundle.sh
	@$(MAKE) _remove_comments_from_file file=dist/bundle.sh
	@$(MAKE) _push_module module=logging
	@$(MAKE) _push_module module=prompts
	@$(MAKE) _push_module module=user_feedback

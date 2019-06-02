
.DEFAULT_GOAL := help

.PHONY: help
help: ## Shows this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install package
	pip install .

.PHONY: uninstall
uninstall: ## Uninstall package
	pip uninstall -y vtable_lib .

.PHONY: reinstall
reinstall: uninstall install ## Reinstall package

lint: ## Lint source for errors
	pylint -E ./src

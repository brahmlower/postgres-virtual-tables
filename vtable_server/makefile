
.DEFAULT_GOAL := help

.PHONY: help
help: ## Shows this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: run
run: ## Run the server via the installed package
	gunicorn --bind 0.0.0.0:8000 'vtable_server:build_app()'

.PHONY: run-dev
run-dev: ## Run the server via the direct source code
	gunicorn --bind 0.0.0.0:8000 'src:build_app()'

.PHONY: install
install: ## Install the pip package
	pip install .

.PHONY: uninstall
uninstall: ## Uninstall the pip package
	pip uninstall -y vtable_server .

.PHONY: reinstall
reinstall: uninstall install

lint: ## Lint source for errors
	pylint -E ./src

test: ## Run newman tests (requires server to be running)
	newman run ./vtable_server.postman.json

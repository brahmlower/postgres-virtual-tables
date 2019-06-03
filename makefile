
.DEFAULT_GOAL := help

.PHONY: help
help: ## Shows this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

db-up: ## Start the database in the background (creates pgdata folder)
	mkdir -p pgdata
	docker-compose up -d

db-down: ## Shuts down the database
	docker-compose down

db-deploy: ## Deploys sqitch schmea to running database
	cd schema && sqitch deploy db:pg://test:test@localhost:5432/test

db-revert: ## Reverts sqitch schema
	cd schema && sqitch revert db:pg://test:test@localhost:5432/test

db-shell: ## Helper for giving you a psql shell in database
	PGPASSWORD=test psql -U test -h localhost test

server-run: ## Run the vtable server via the installed package
	cd vtable_server && make run

server-run-dev: ## Run the vtable server via raw source code
	cd vtable_server && make run-dev

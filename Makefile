.PHONY: help install purge status push sync

.DEFAULT_GOAL := help

# --- Help ---
help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $1, $2}'

# --- Operation ---
install: ## Install ZSH environment
	bash scripts/install.sh

purge: ## Purge ZSH environment
	bash scripts/purge.sh

# --- Git ---
status: ## Git status --short
	@git status --short

push: ## Push current branch to all remotes
	@git remote | xargs -I {} git push {} $(shell git branch --show-current)

sync: ## Add all, commit and push (usage: make sync M="message")
	@git add .
	@git commit -m "$(or $(M),sync: auto-commit from Makefile)"
	@$(MAKE) push

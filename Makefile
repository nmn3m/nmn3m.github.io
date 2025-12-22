.PHONY: help build serve clean new deploy

HUGO := ./hugo

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the site
	$(HUGO) --minify

serve: ## Start the development server
	$(HUGO) server --buildDrafts --buildFuture

clean: ## Clean the public directory
	rm -rf public

new: ## Create a new post (usage: make new POST="my-post-title")
	@if [ -z "$(POST)" ]; then \
		echo "Error: POST variable is required. Usage: make new POST=\"my-post-title\""; \
		exit 1; \
	fi
	$(HUGO) new posts/$(POST).md

new-ar: ## Create a new Arabic post (usage: make new-ar POST="my-post-title")
	@if [ -z "$(POST)" ]; then \
		echo "Error: POST variable is required. Usage: make new-ar POST=\"my-post-title\""; \
		exit 1; \
	fi
	$(HUGO) new posts/$(POST).ar.md

deploy: clean build ## Build and prepare for deployment
	@echo "Site built successfully in ./public"
	@echo "Ready to deploy to GitHub Pages"

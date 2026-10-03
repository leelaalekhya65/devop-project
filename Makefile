SHELL := /bin/bash
ENV_FILE ?= .env

.PHONY: help keys up down logs test helm-lint tf-init tf-apply tf-destroy ansible argocd-bootstrap docs

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

keys: ## Generate SSH key pair into .env
	./scripts/gen-keys.sh

up: ## Start app + Prometheus + Loki + Grafana with Docker Compose
	@[ -f .env ] || cp .env.example .env
	docker compose --env-file $(ENV_FILE) up -d --build

down: ## Stop the Compose stack
	docker compose down -v

logs: ## Tail app logs
	docker compose logs -f webapp

test: ## Run app tests
	pip install -q -r app/requirements.txt && pytest app -q

helm-lint: ## Lint and render the Helm chart
	helm lint helm/webapp && helm template webapp helm/webapp >/dev/null

tf-init: ## terraform init
	cd terraform && terraform init

tf-apply: ## Create the kind cluster and install Argo CD
	cd terraform && terraform apply -auto-approve

tf-destroy: ## Delete the kind cluster
	cd terraform && terraform destroy -auto-approve

ansible: ## Provision tools on the host defined in .env
	set -a; . ./$(ENV_FILE); set +a; cd ansible && ansible-playbook playbook.yml

argocd-bootstrap: ## Apply the Argo CD project and root app (set REPO_URL first)
	kubectl apply -f argocd/project.yaml
	kubectl apply -f argocd/root-app.yaml

docs: ## Open the HTML docs
	@echo "Open docs/index.html in your browser"

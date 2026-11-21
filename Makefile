.DEFAULT_GOAL := help
COMPOSE := docker compose --env-file .env -f infra/docker-compose.yml
SHELL := /bin/bash

.PHONY: help init up down restart status health logs backup shell-ad shell-glpi seed test lint docs

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

init: ## Copia .env.example a .env si no existe y crea volumenes
	@test -f .env || (cp .env.example .env && echo "Creado .env - EDITALO ANTES DE SEGUIR")
	@mkdir -p infra/clonezilla/images docs/screenshots backups
	@touch infra/clonezilla/images/.gitkeep
	@$(COMPOSE) config --quiet && echo "Compose validado correctamente"

up: ## Levanta todos los servicios
	$(COMPOSE) up -d

down: ## Baja todos los servicios
	$(COMPOSE) down

restart: ## Reinicia todos los servicios
	$(COMPOSE) restart

status: ## Muestra el estado de los contenedores
	$(COMPOSE) ps

health: ## Ejecuta los healthchecks del laboratorio
	./scripts/healthcheck.sh

logs: ## Sigue los logs de todos los servicios
	$(COMPOSE) logs -f

seed: ## Carga usuarios AD y tickets de prueba en GLPI
	./infra/active-directory/scripts/create-users.sh
	./infra/glpi/scripts/seed-tickets.sh

shell-ad: ## Abre shell en el controlador de dominio
	$(COMPOSE) exec ad bash

shell-glpi: ## Abre shell en el contenedor de GLPI
	$(COMPOSE) exec glpi bash

backup: ## Ejecuta backup cifrado con restic
	./scripts/backup.sh

test: ## Validaciones basicas del repositorio
	./scripts/validate.sh

lint: test ## Alias de test

docs: ## Muestra el indice de documentacion
	@cat docs/INDICE.md

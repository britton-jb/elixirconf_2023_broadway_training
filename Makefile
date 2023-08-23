#!make

SHELL := /bin/bash

install:
	@bash ./scripts/setup.sh
	@make compose.up

compose-up: compose.up
compose.up:
	@docker compose -p elixir-conf-2023-broadway-training up -d
	@docker compose -p elixir-conf-2023-broadway-training ps

compose-down: compose.down
compose.down:
	@docker compose -p elixir-conf-2023-broadway-training down
	@docker compose -p elixir-conf-2023-broadway-training ps

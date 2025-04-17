# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jeberle <jeberle@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/11/12 15:44:57 by jeberle           #+#    #+#              #
#    Updated: 2025/04/09 17:18:48 by jeberle          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#------------------------------------------------------------------------------#
#--------------                       PRINT                       -------------#
#------------------------------------------------------------------------------#

BLACK := \033[90m
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
X := \033[0m

SUCCESS := \n\
$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)\n\
$(X)\n\
█  ██    █  ███████  ███████  ███████  ███████  █  ███████  ██    █ $(X)\n\
█  █ █   █  █        █        █     █     █     █  █     █  █ █   █ $(X)\n\
█  █  █  █  █        ███████  ███████     █     █  █     █  █  █  █ $(X)\n\
█  █   █ █  █        █        █           █     █  █     █  █   █ █ $(X)\n\
█  █    ██  ███████  ███████  █           █     █  ███████  █    ██ $(X)\n\
$(X)\n\
$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)$(BLUE)█$(X)$(CYAN)█$(X)\n\
#------------------------------------------------------------------------------#
#--------------                      GENERAL                      -------------#
#------------------------------------------------------------------------------#

NAME=inception
DOCKER_COMPOSE = srcs/docker-compose.yml

DATA_DIR = /home/jeberle/data

WP_DATA_DIR = $(DATA_DIR)/wordpress
DB_DATA_DIR = $(DATA_DIR)/mariadb

#------------------------------------------------------------------------------#
#--------------                  DOCKER COMMANDS                  -------------#
#------------------------------------------------------------------------------#

.PHONY: all build up down logs status clean fclean re stop prune

all: prepare build up
	@echo "$(GREEN)$(SUCCESS)$(X)"
	@echo "$(GREEN)Inception is now running!$(X)"

build:
	@echo "$(BLUE)Building Docker containers...$(X)"
	@docker-compose -f $(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build complete.$(X)"

up:
	@echo "$(BLUE)Starting Docker containers...$(X)"
	@docker-compose -f $(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers started.$(X)"

down:
	@echo "$(BLUE)Stopping containers...$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers stopped.$(X)"

logs:
	@echo "$(BLUE)Showing logs:$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) logs

logs-%:
	@echo "$(BLUE)Showing logs for $*:$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) logs $*

clean: down
	@echo "$(BLUE)Cleaning Docker system...$(X)"
	@docker system prune -a --force
	@echo "$(GREEN)Clean complete.$(X)"

fclean: clean
	@echo "$(BLUE)Removing Docker volumes...$(X)"
	@docker volume rm $$(docker volume ls -q) 2 || true
	@echo "$(GREEN)Full clean complete.$(X)"

re: fclean all

stop:
	@echo "$(BLUE)Stopping containers...$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) stop
	@echo "$(GREEN)Containers stopped.$(X)"

prune:
	@echo "$(RED)WARNING: This will remove all unused containers, networks, volumes, and all data.$(X)"
	@echo "$(RED)Are you sure? [y/N]$(X)"
	@read -r answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		echo "$(BLUE)Stopping containers...$(X)"; \
		docker-compose -f $(DOCKER_COMPOSE) down --volumes; \
		echo "$(BLUE)Cleaning Docker system...$(X)"; \
		docker system prune -a --volumes --force; \
		echo "$(BLUE)Removing entire data directory...$(X)"; \
		sudo rm -rf $(DATA_DIR); \
		echo "$(GREEN)Prune complete. All data has been removed.$(X)"; \
	else \
		echo "$(BLUE)Prune cancelled.$(X)"; \
	fi

prepare:
	@[ -d "$(DATA_DIR)" ] || mkdir -p "$(DATA_DIR)"
	@[ -d "$(WP_DATA_DIR)" ] || mkdir -p "$(WP_DATA_DIR)"
	@[ -d "$(DB_DATA_DIR)" ] || mkdir -p "$(DB_DATA_DIR)"
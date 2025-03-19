# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jonathaneberle <jonathaneberle@student.    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/11/12 15:44:57 by jeberle           #+#    #+#              #
#    Updated: 2025/03/19 13:08:47 by jonathanebe      ###   ########.fr        #
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

DATA_DIR = ./data/

WP_DATA_DIR = $(DATA_DIR)/wordpress
DB_DATA_DIR = $(DATA_DIR)/mariadb

#------------------------------------------------------------------------------#
#--------------                       FLAGS                       -------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#--------------                        DIR                        -------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#--------------                        LIBS                       -------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#--------------                        SRC                        -------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#--------------                      OBJECTS                      -------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#--------------                      COMPILE                      -------------#
#------------------------------------------------------------------------------#

.PHONY: all setup prepare build up down ps logs status clean fclean re restart stop prune volumes images info check-env

all: prepare build up
	@echo "$(GREEN)$(SUCCESS)$(X)"
	@echo "$(GREEN)Inception is now running!$(X)"

prepare:
	@echo "$(BLUE)Creating data directories...$(X)"
	@mkdir -p $(WP_DATA_DIR)
	@mkdir -p $(DB_DATA_DIR)
	@echo "$(GREEN)Data directories created at $(DATA_DIR)$(X)"

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

ps:
	@echo "$(BLUE)List of running containers:$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) ps

logs:
	@echo "$(BLUE)Showing logs:$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) logs

logs-%:
	@echo "$(BLUE)Showing logs for $*:$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) logs $*

status:
	@echo "$(BLUE)Checking status:$(X)"
	@docker ps -a
	@echo "\n$(BLUE)Networks:$(X)"
	@docker network ls
	@echo "\n$(BLUE)Volumes:$(X)"
	@docker volume ls

clean: down
	@echo "$(BLUE)Cleaning Docker system...$(X)"
	@docker system prune -a --force
	@echo "$(BLUE)Removing data...$(X)"
	@rm -rf $(WP_DATA_DIR)/*
	@rm -rf $(DB_DATA_DIR)/*
	@echo "$(GREEN)Clean complete.$(X)"

fclean: clean
	@echo "$(BLUE)Removing Docker volumes...$(X)"
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@echo "$(GREEN)Full clean complete.$(X)"

re: fclean all

restart:
	@echo "$(BLUE)Restarting containers...$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) restart
	@echo "$(GREEN)Containers restarted.$(X)"

stop:
	@echo "$(BLUE)Stopping containers...$(X)"
	@DATA_DIR=$(DATA_DIR) docker-compose -f $(DOCKER_COMPOSE) stop
	@echo "$(GREEN)Containers stopped.$(X)"

prune:
	@echo "$(RED)WARNING: This will remove all unused containers, networks, and volumes.$(X)"
	@echo "$(RED)Are you sure? [y/N]$(X)"
	@read -r answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		docker system prune -a --volumes --force; \
		echo "$(GREEN)Prune complete.$(X)"; \
	else \
		echo "$(BLUE)Prune cancelled.$(X)"; \
	fi

volumes:
	@echo "$(BLUE)Docker volumes:$(X)"
	@docker volume ls

images:
	@echo "$(BLUE)Docker images:$(X)"
	@docker images

info:
	@echo "$(CYAN)INCEPTION PROJECT INFO:$(X)"
	@echo "$(BLUE)Container statuses:$(X)"
	@docker ps -a | grep -E 'nginx|wordpress|mariadb' || echo "No containers running"
	@echo "\n$(BLUE)Volumes:$(X)"
	@docker volume ls
	@echo "\n$(BLUE)Networks:$(X)"
	@docker network ls | grep inception || echo "No inception networks found"
	@echo "\n$(BLUE)Data directory:$(X)"
	@echo "$(DATA_DIR)"

check-env:
	@echo "$(BLUE)Checking environment files...$(X)"
	@if [ -f srcs/.env ]; then \
		echo "$(GREEN).env file exists.$(X)"; \
	else \
		echo "$(RED).env file is missing!$(X)"; \
	fi

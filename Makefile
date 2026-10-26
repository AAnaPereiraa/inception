NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/ana-pdos/data


dirs:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

build: dirs
	docker compose -f $(COMPOSE_FILE) build
	
up: build
	@echo "$(YELLOW)Starting containers..$(NC)"
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✓ Containers started!$(NC)"
	@echo "$(BLUE)Access your site at: https://ana-pdos.42.fr$(NC)"

all: build up

down:
	@echo "$(YELLOW)Stopping containers..$(NC)"
	docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✓ Containers stopped!$(NC)"

db:
	@echo "$(YELLOW)Accessing MariaDB container..$(NC)"
	docker exec -it mariadb mariadb -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME)

restart:
	@echo "$(YELLOW)Restarting containers..$(NC)"
	docker compose -f $(COMPOSE_FILE) restart
	@echo "$(GREEN)✓ Containers restarted!$(NC)"

ps:
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@echo "$(YELLOW)Showing logs..$(NC)"
	@docker compose -f $(COMPOSE_FILE) logs -f

clean: 
	@echo "$(YELLOW)Removing containers and images..$(NC)"	
	@$(MAKE) down
	@docker compose -f $(COMPOSE_FILE) down --rmi all
	@echo "$(GREEN)✓ All containers and images cleaned!$(NC)"
	

fclean: clean
	@docker system prune -af
	@sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@echo "$(GREEN)✓ Full clean completed!$(NC)"

re: down up
	@echo "$(GREEN)✓ Containers restarted!$(NC)"


.PHONY: all dirs up down stop start ps logs clean fclean re

NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/ana-pdos/data

all: up

dirs:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

up: dirs
	@docker compose -f $(COMPOSE_FILE) up --build -d

down:
	@docker compose -f $(COMPOSE_FILE) down

stop:
	@docker compose -f $(COMPOSE_FILE) stop

start:
	@docker compose -f $(COMPOSE_FILE) start

ps:
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

clean: down
	@docker compose -f $(COMPOSE_FILE) down --rmi all --volumes
	@docker volume rm vol-mariadb vol-wordpress 2>/dev/null || true

fclean: clean
	@docker system prune -af
	@sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

re: clean up

.PHONY: all dirs up down stop start ps logs clean fclean re

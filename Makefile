NAME = Inception
DOCKER_COMPOSE_FILE = srcs/docker-compose.yml

all: run_docker

run_docker:
	@echo "\033[33m \n-- RUNNING DOCKER --\033[0m"
	@docker compose -f $(DOCKER_COMPOSE_FILE) up --build -d

clean:
	@echo " \n\033[43m- PRINTING ALL RUNNING CONTAINERS -\033[0m"
	@docker ps
	@echo " \n\033[43m- STOPPING CONTAINERS -\033[0m"
	@docker compose -f srcs/docker-compose.yml down
	@echo "\n\033[32m ----- All containers stopped! ----- \033[0m"

fclean:
	@$(MAKE) --no-print-directory clean
	@docker system prune -af

re_f: fclean all
re:   clean all

.PHONY: all clean fclean re re_f run_docker
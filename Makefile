# General release info
APP_NAME				= wetty-openapi
DOCKER_ACCOUNT	= boeboe
VERSION					= 1.0.0

# With or without debug tools
ifeq ($(DEBUG), true)
DOCKER_TAG        = ${VERSION}-dbg
DEBUG_TOOL_LIST		= bash tree vim nano strace iputils curl wget httpie net-tools netcat-openbsd socat tcpdump bind-tools iproute2 tcptraceroute iperf3
DOCKER_BUILD_ARGS	= --rm --build-arg DEBUG_TOOLS=true --build-arg DEBUG_TOOL_LIST="${DEBUG_TOOL_LIST}" -f Dockerfile
else
DOCKER_TAG        = ${VERSION}
DOCKER_BUILD_ARGS = --rm --build-arg DEBUG_TOOLS=false -f Dockerfile
endif

# Ports for wetty, tcp and udp echo server
WETTY_PORT							= 3000
API_SERVER_PORT					= 3001
API_CLIENT_PORT					= 3002

EXPOSED_WETTY_PORT			= 18080
EXPOSED_API_SERVER_PORT	= 18081
EXPOSED_API_CLIENT_PORT	= 18082

PORT_MAPPING=-p=$(EXPOSED_WETTY_PORT):${WETTY_PORT} -p=$(EXPOSED_API_CLIENT_PORT):${API_CLIENT_PORT} -p=$(EXPOSED_API_SERVER_PORT):${API_SERVER_PORT}

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


#### DOCKER TASKS ###

build: ## Build the container
	docker build ${DOCKER_BUILD_ARGS} -t $(DOCKER_ACCOUNT)/$(APP_NAME) .

build-nc: ## Build the container without caching
	docker build ${DOCKER_BUILD_ARGS} --no-cache -t $(DOCKER_ACCOUNT)/$(APP_NAME) .

run: ## Run container
	docker run -i -t --rm ${PORT_MAPPING} --name="$(APP_NAME)" $(DOCKER_ACCOUNT)/$(APP_NAME)

run-sh: ## Run interactive shell in container
	docker run -i -t --entrypoint /bin/sh --name="$(APP_NAME)" $(DOCKER_ACCOUNT)/$(APP_NAME)

login-sh: ## Login with shell in running container
	docker exec -i -t $(APP_NAME) /bin/sh

up: build run ## Build and run container on port configured

stop: ## Stop and remove a running container
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

release: build-nc publish ## Make a full release

publish: ## Tag and publish container
	@echo 'create tag $(DOCKER_TAG)'
	docker tag $(DOCKER_ACCOUNT)/$(APP_NAME) $(DOCKER_ACCOUNT)/$(APP_NAME):$(DOCKER_TAG)
	@echo 'publish $(VERSION) to $(DOCKER_ACCOUNT)/$(APP_NAME):$(DOCKER_TAG)'
	docker push $(DOCKER_ACCOUNT)/$(APP_NAME):$(DOCKER_TAG)


#### KUBERNETES TASKS ###

deploy-k8s: ## Deploy onto kubernetes
	kubectl apply -f ./kubernetes

undeploy-k8s: ## Undeploy from kubernetes
	kubectl delete -f ./kubernetes
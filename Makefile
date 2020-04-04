# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

AWS_ECR_URL=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

FILE_TAR                        :=./$(IMAGE_REPO_NAME).tar
FILE_GZ                         :=$(FILE_TAR).gz
UNAME_S                         :=$(shell uname -apps)
ifeq ($(UNAME_S),Linux)
    APP_HOST                    :=localhost
endif
ifeq ($(UNAME_S),Darwin)
    APP_HOST                    :=$(shell docker-appmachine ip default)
endif

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS
build: ## Build the release container.
	docker build -t $(IMAGE_REPO_NAME) .

build-nc: ## Build the container without caching
	docker build --no-cache -t $(IMAGE_REPO_NAME) .

save: ## Save the container as a gzip file
	docker image save $(IMAGE_REPO_NAME) > $(FILE_TAR)
	@[ -f $(FILE_TAR) ] && gzip $(FILE_TAR) || true

load: ## Load the container from a gzip file
	@[ -f $(FILE_GZ) ] && gunzip $(FILE_GZ) || true
	@[ -f $(FILE_TAR) ] && docker load -i $(FILE_TAR) && gzip $(FILE_TAR) || true

tag: ## Generate container tag to docker hub
	@echo 'create tag latest'
	docker tag $(IMAGE_REPO_NAME):latest paperinik/$(IMAGE_REPO_NAME):latest

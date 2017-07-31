PROJECT_NAME = wagtail_cookie_db
SHELL := /bin/sh
help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  all                      to setup the whole development environment for the project"
	@echo "  virtualenv               to create the virtualenv for the project"
	@echo "  requirements             install the requirements to the virtualenv"
	@echo "  deploy_user              create the deploy user fetch deployment keys. Defaults to production DEPLOY_ENV=vagrant/staging"
	@echo "  provision                provision the production server Defaults to production DEPLOY_ENV=staging"
	@echo "  deploy                   provision the staging server Defaults to production DEPLOY_ENV=staging"

.PHONY: requirements


all: virtualenv requirements provision

# Command variables
MANAGE_CMD = python manage.py
PIP_INSTALL_CMD = pip install
PLAYBOOK = ansible-playbook
VIRTUALENV_NAME = env

# Helper functions to display messagse
ECHO_BLUE = @echo "\033[33;34m $1\033[0m"
ECHO_RED = @echo "\033[33;31m $1\033[0m"

# The default server host local development
HOST ?= localhost:8000
DEPLOY_ENV = production

virtualenv: 
	virtualenv $(VIRTUALENV_NAME)

requirements:
	( \
		. $(VIRTUALENV_NAME)/bin/activate; \
		$(PIP_INSTALL_CMD) -r requirements.txt; \
	)

runserver:
	( \
		. $(VIRTUALENV_NAME)/bin/activate; \
		$(MANAGE_CMD) runserver 0.0.0.0:8000; \
	)

runhoncho:
	( \
		. $(VIRTUALENV_NAME)/bin/activate; \
		honcho start; \
	)

runcircus:
	( \
		. $(VIRTUALENV_NAME)/bin/activate; \
		circusd circle.ini; \
	)

deploy_user:
ifeq ($(DEPLOY_ENV), vagrant)
	$(call ECHO_BLUE, Create the deploy user for vagrant based staging VM)
	(\
		cd ansible; \
		vagrant up; \
		$(PLAYBOOK) -c paramiko -i staging vagrant_staging_setup.yml --ask-pass --sudo -u vagrant; \
	)
else
	$(call ECHO_BLUE, Create the deploy user for based $(DEPLOY_ENV) )
	(\
		$(PLAYBOOK) -i $(DEPLOY_ENV) provision.yml --tags user -vvv; \
	)
endif

provision:
	$(call ECHO_BLUE, Provision the $(DEPLOY_ENV) server )
	(\
		$(PLAYBOOK) -i $(DEPLOY_ENV) provision.yml --skip-tags user -vvv; \
	)

deploy:
	$(call ECHO_BLUE, deploy changes to the $(DEPLOY_ENV) server )
	(\
		$(PLAYBOOK) -i $(DEPLOY_ENV) deploy.yml;  \
	)


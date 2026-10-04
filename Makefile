SHELL := /bin/bash
PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help
BACKEND ?= keepassxc
REBUILD_PREVIEWS ?= 0

ifeq ($(filter $(REBUILD_PREVIEWS),0 1),)
$(error REBUILD_PREVIEWS must be 0 or 1)
endif

ifeq ($(BACKEND),keepassxc)
KEYRING_BACKEND := keepassxc
else ifeq ($(BACKEND),gnome-keyring)
KEYRING_BACKEND := gnome-keyring
else
$(error BACKEND must be keepassxc or gnome-keyring)
endif

.PHONY: help setup keyring verify test hook icons theme zed micro cli herdr disk editors tode clean lang i18n-status lint

lint:
	@if ! command -v shellcheck &> /dev/null; then \
		echo "shellcheck not found. Install with: pkexec pacman -S shellcheck (or use CI)"; \
		exit 1; \
	fi
	shellcheck --severity=style \
		scripts/*.sh scripts/lib/*.sh scripts/lib/modules/*.sh \
		hooks/theme-set.d/* hooks/pre-refresh-pacman.d/* hooks/post-update.d/* \
		conf/*/*.sh \
		tests/*.sh

help:
	@bash scripts/lib/help.sh

setup:
	pkexec bash $(PROJECT_ROOT)/scripts/setup.sh $(if $(filter 1,$(REBUILD_PREVIEWS)),--rebuild-previews)

keyring:
	bash $(PROJECT_ROOT)/scripts/keyring-switch.sh "$(KEYRING_BACKEND)"

verify:
	bash scripts/verify.sh

test:
	bash tests/run-all.sh

hook:
	@mkdir -p ~/.config/omarchy/hooks/theme-set.d ~/.config/omarchy/hooks/i18n/messages
	cp hooks/theme-set.d/* ~/.config/omarchy/hooks/theme-set.d/
	chmod +x ~/.config/omarchy/hooks/theme-set.d/*
	cp scripts/lib/i18n.sh scripts/lib/i18n-boot.sh ~/.config/omarchy/hooks/i18n/
	cp scripts/lib/messages/*.msg ~/.config/omarchy/hooks/i18n/messages/

icons:
	@bash hooks/theme-set.d/folder-color

theme:
	@bash hooks/theme-set.d/folder-color
	@bash hooks/theme-set.d/micro-theme

zed:
	bash conf/zed/install.sh

micro:
	bash conf/micro/install.sh

cli:
	bash conf/cli/install.sh

herdr:
	bash conf/herdr/install.sh

disk:
	bash conf/disk/install.sh

editors: zed micro cli

tode:
	TODE_FORCE_INSTALL=1 bash conf/terminal-code/install.sh

lang:
	@bash scripts/lib/i18n.sh --list

i18n-status:
	@bash scripts/lib/i18n.sh

clean:
	rm -f setup.log

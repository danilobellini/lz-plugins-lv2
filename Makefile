# LV2 Makefile for Python-based plugins
# License is GPLv3, see COPYING.txt for more details.
# Created on 2014-09-19 03:32 BRT
# by Danilo J. S. Bellini

# Configuration
PY_VERSION ?= 2.7
SOURCE_PATH = src

# C/C++ Language information
SOURCE_EXT = c
COMPILER = gcc

# Python-specific C API configuration
PY_CONFIG = python$(PY_VERSION)-config
PY_INCLUDES = $(shell $(PY_CONFIG) --includes)
PY_LDLIBS = $(shell $(PY_CONFIG) --libs)
PY_PREFIX = $(shell $(PY_CONFIG) --prefix)

# Install path, with many locations possible. Uses $(DESTDIR) and $(prefix)
# conventions. Installs globally when running with sudo, and locally otherwise
PREFIX = $(or $(prefix), $(PY_PREFIX), /usr/local)
DEFAULT_PATH = $(if $(filter $(USER), root),$(PREFIX)/lib/lv2,$(HOME)/.lv2)
INSTALL_PATH = $(or $(DESTDIR), $(DEFAULT_PATH))

# File and plugin names
SOURCE_FILES = $(wildcard $(SOURCE_PATH)/*.$(SOURCE_EXT))
NAMES = $(notdir $(basename $(SOURCE_FILES)))
PLUGINS = $(NAMES:=.so)

# Install information
INSTALL_TARGET_PREFIX = install-
INSTALL_NAMES = $(foreach name, $(NAMES), $(INSTALL_TARGET_PREFIX)$(name))

# Uninstall information
UNINSTALL_TARGET_PREFIX = uninstall-
UNINSTALL_NAMES = $(foreach name, $(NAMES), $(UNINSTALL_TARGET_PREFIX)$(name))

# Compiler/linker parameters
COMPILER_FLAGS = $(PY_INCLUDES) -Ofast -Wall -march=native -mtune=native -fPIC
LDFLAGS = -shared -rdynamic
LDLIBS = $(PY_LDLIBS)

# Makefile targets

all: $(NAMES)

$(NAMES): %: %.so $(SOURCE_PATH)/%.ttl

%.so: $(SOURCE_PATH)/%.o
	$(COMPILER) -o $@ $(LDFLAGS) $< $(LDLIBS)

%.o: %.$(SOURCE_EXT)
	$(COMPILER) -c $(COMPILER_FLAGS) -o $@ $<

%.ttl: %.py
	lz2lv2 ttl $<

clean: O_FILES = $(SOURCE_FILES:.$(SOURCE_EXT)=.o)
clean: TTL_FILES = $(SOURCE_FILES:.$(SOURCE_EXT)=.ttl)
clean:
	rm -f $(O_FILES) $(TTL_FILES) $(PLUGINS)

install: $(INSTALL_NAMES)

$(INSTALL_NAMES): PLUGIN_NAME = $<
$(INSTALL_NAMES): PLUGIN_PATH = $(INSTALL_PATH)/$(PLUGIN_NAME).lv2
$(INSTALL_NAMES): $(INSTALL_TARGET_PREFIX)%: %
	mkdir -p $(PLUGIN_PATH)
	cp $(PLUGIN_NAME).so $(PLUGIN_PATH)
	cp $(SOURCE_PATH)/$(PLUGIN_NAME).ttl $(PLUGIN_PATH)/manifest.ttl

uninstall: $(UNINSTALL_NAMES)

define do_uninstall
	rm -f $(PLUGIN_PATH)/$(PLUGIN_NAME).so
	rm -f $(PLUGIN_PATH)/manifest.ttl
	rmdir --ignore-fail-on-non-empty $(PLUGIN_PATH)
endef

define cant_uninstall
	@echo "Can't uninstall '$(PLUGIN_PATH)' as it doesn't exist"
endef

$(UNINSTALL_NAMES): PLUGIN_NAME = $(@:$(UNINSTALL_TARGET_PREFIX)%=%)
$(UNINSTALL_NAMES): PLUGIN_PATH = $(INSTALL_PATH)/$(PLUGIN_NAME).lv2
$(UNINSTALL_NAMES): PLUGIN_PATH_EXISTS = $(wildcard $(PLUGIN_PATH))
$(UNINSTALL_NAMES):
	$(if $(PLUGIN_PATH_EXISTS), $(do_uninstall), $(cant_uninstall))

.PHONY: all clean install $(INSTALL_NAMES) uninstall $(UNINSTALL_NAMES)

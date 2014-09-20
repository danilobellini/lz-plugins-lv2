# LV2 Makefile for Python-based plugins
# License is GPLv3, see COPYING.txt for more details.
# Created on 2014-09-19 03:32 BRT
# by Danilo J. S. Bellini

# Configuration
PY_VERSION ?= 2.7
SOURCE_PATH = src

# C/C++ Language information
SOURCE_EXT = cpp
COMPILER = g++

# Python-specific C API configuration
PY_CONFIG = python$(PY_VERSION)-config
PY_INCLUDES = $(shell $(PY_CONFIG) --includes)
PY_LDLIBS = $(shell $(PY_CONFIG) --libs)
PY_PREFIX = $(shell $(PY_CONFIG) --prefix)

# Install path: global when running with sudo, and local otherwise
PREFIX = $(or $(prefix), $(PY_PREFIX), /usr/local)
INSTALL_PATH = $(if $(filter $(USER), root), $(PREFIX)/lib/lv2, $(HOME)/.lv2)

# File and plugin names
SOURCE_FILES = $(wildcard $(SOURCE_PATH)/*.$(SOURCE_EXT))
NAMES = $(notdir $(basename $(SOURCE_FILES)))
PLUGINS = $(NAMES:=.so)
INSTALL_TARGET_PREFIX = install-
INSTALL_NAMES = $(foreach name, $(NAMES), $(INSTALL_TARGET_PREFIX)$(name))

# Compiler/linker parameters
COMPILER_FLAGS = $(PY_INCLUDES) -Ofast -Wall -march=native -mtune=native -fPIC
LDFLAGS = -shared -rdynamic
LDLIBS = $(PY_LDLIBS)

# Makefile targets

all: $(NAMES)

$(NAMES): %: %.so

%.so: $(SOURCE_PATH)/%.o
	$(COMPILER) -o $@ $(LDFLAGS) $< $(LDLIBS)

%.o: %.$(SOURCE_EXT)
	$(COMPILER) -c $(COMPILER_FLAGS) -o $@ $<

clean:
	rm -f $(SOURCE_FILES:.$(SOURCE_EXT)=.o) $(PLUGINS)

install: $(INSTALL_NAMES)

$(INSTALL_NAMES): PLUGIN_NAME = $<
$(INSTALL_NAMES): PLUGIN_PATH = $(INSTALL_PATH)/$(PLUGIN_NAME).lv2
$(INSTALL_NAMES): $(INSTALL_TARGET_PREFIX)%: %
	mkdir -p $(PLUGIN_PATH)
	cp $(PLUGIN_NAME).so $(PLUGIN_PATH)
	cp ttl/manifest.ttl $(PLUGIN_PATH)
	cp ttl/$(PLUGIN_NAME).ttl $(PLUGIN_PATH)

.PHONY: all clean install $(INSTALL_NAMES)

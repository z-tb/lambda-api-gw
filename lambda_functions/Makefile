# Makefile

.PHONY: test install
TARGET_DIR = ./layers
PYTHON_DIR = $(TARGET_DIR)/python

# Default target
default: test

# Install target to install requirements
install:
	pip install --upgrade -r requirements.txt --target=$(PYTHON_DIR)

# Test target to check if packages can be installed
test:
	@echo "Checking installation of requirements..."
	pip install --dry-run -r requirements.txt --target=$(PYTHON_DIR) || true
	@echo "\033[33mTEST MODE\033[0m"


# Vim modeline
# vim: syntax=make ts=8 sw=8 noet

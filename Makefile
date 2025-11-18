# DevFlow DSL Parser Makefile
# Requires: bison, flex, gcc

CC = gcc
CFLAGS = -Wall -g
BISON = bison
FLEX = flex

# Target executable
TARGET = devflow_parser

# Source files
LEXER = devflow.l
PARSER = devflow.y
PARSER_C = devflow.tab.c
PARSER_H = devflow.tab.h
LEXER_C = lex.yy.c

# Object files
OBJS = $(PARSER_C:.c=.o) $(LEXER_C:.c=.o)

# Default target
all: $(TARGET)

# Build the parser
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) -lfl

# Generate parser from Bison grammar
$(PARSER_C) $(PARSER_H): $(PARSER)
	$(BISON) -d $(PARSER)

# Generate lexer from Flex file
$(LEXER_C): $(LEXER) $(PARSER_H)
	$(FLEX) $(LEXER)

# Compile object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Test targets
test: $(TARGET)
	@echo "Testing simple pipeline..."
	./$(TARGET) examples/simple_pipeline.devflow
	@echo "\nTesting docker pipeline..."
	./$(TARGET) examples/docker_pipeline.devflow
	@echo "\nTesting matrix pipeline..."
	./$(TARGET) examples/matrix_pipeline.devflow
	@echo "\nTesting full CI/CD pipeline..."
	./$(TARGET) examples/full_cicd_pipeline.devflow

test-simple: $(TARGET)
	./$(TARGET) examples/simple_pipeline.devflow

test-docker: $(TARGET)
	./$(TARGET) examples/docker_pipeline.devflow

test-matrix: $(TARGET)
	./$(TARGET) examples/matrix_pipeline.devflow

test-full: $(TARGET)
	./$(TARGET) examples/full_cicd_pipeline.devflow

# Clean build artifacts
clean:
	rm -f $(TARGET) $(OBJS) $(PARSER_C) $(PARSER_H) $(LEXER_C)

# Install dependencies (Linux/Unix)
install-deps:
	@echo "Installing dependencies..."
	@if command -v apt-get > /dev/null; then \
		sudo apt-get update && sudo apt-get install -y bison flex gcc; \
	elif command -v brew > /dev/null; then \
		brew install bison flex gcc; \
	elif command -v yum > /dev/null; then \
		sudo yum install -y bison flex gcc; \
	else \
		echo "Please install bison, flex, and gcc manually"; \
	fi

# Help target
help:
	@echo "DevFlow DSL Parser Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the parser (default)"
	@echo "  test         - Run all example tests"
	@echo "  test-simple  - Test simple pipeline"
	@echo "  test-docker  - Test docker pipeline"
	@echo "  test-matrix  - Test matrix pipeline"
	@echo "  test-full    - Test full CI/CD pipeline"
	@echo "  clean        - Remove build artifacts"
	@echo "  install-deps - Install required dependencies"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  make              - Build the parser"
	@echo "  make test         - Test with example files"
	@echo "  ./devflow_parser <file> - Parse a DevFlow file"

.PHONY: all test test-simple test-docker test-matrix test-full clean install-deps help


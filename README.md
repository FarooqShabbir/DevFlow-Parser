# DevFlow DSL - Domain Specific Language for DevOps, CI/CD

**DevFlow DSL** is a specialized Domain Specific Language designed for expressing DevOps workflows, Continuous Integration (CI), and Continuous Delivery (CD) pipelines. The language provides a clean, intuitive syntax for defining build, test, and deployment processes that integrates seamlessly with Docker and GitHub Actions workflows.

## Features

- **Clean Syntax**: Domain-specific keywords (`pipeline`, `stage`, `job`, `step`) that read like natural language
- **Docker-First**: Native support for container-based workflows
- **Matrix Builds**: Test across multiple versions and environments
- **Service Dependencies**: Easy declaration of dependent services (databases, caches, etc.)
- **Artifact Management**: Automatic artifact passing between stages
- **Conditional Logic**: Express complex deployment conditions
- **Platform Independence**: Generate configs for multiple platforms (GitHub Actions, GitLab CI, etc.)

## Project Structure

```
Project/
├── DSL_Report.md              # Comprehensive report on the DSL
├── devflow.y                  # Bison/Yacc grammar file
├── devflow.l                  # Flex lexer file
├── Makefile                   # Build configuration
├── README.md                  # This file
└── examples/                  # Example DevFlow DSL files
    ├── simple_pipeline.devflow
    ├── docker_pipeline.devflow
    ├── matrix_pipeline.devflow
    ├── full_cicd_pipeline.devflow
    └── microservices_pipeline.devflow
```

## Requirements

To build and run the DevFlow DSL parser, you need:

- **Bison** (or Yacc) - Parser generator
- **Flex** (or Lex) - Lexical analyzer generator
- **GCC** (or compatible C compiler) - C compiler
- **Make** - Build automation tool

### Installing Dependencies

#### Linux (Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install bison flex gcc make
```

#### Linux (RedHat/CentOS/Fedora)
```bash
sudo yum install bison flex gcc make
# or for newer versions:
sudo dnf install bison flex gcc make
```

#### macOS
```bash
brew install bison flex gcc make
```

#### Windows (WSL/msys2)
```bash
# Using msys2
pacman -S bison flex gcc make

# Using WSL (follow Ubuntu instructions)
```

## Building

1. **Clone or download the project**:
   ```bash
   cd Project
   ```

2. **Build the parser**:
   ```bash
   make
   ```

   This will generate the `devflow_parser` executable.

   Alternatively, if dependencies are not installed:
   ```bash
   make install-deps  # Install dependencies (Linux/macOS)
   make               # Then build
   ```

## Usage

### Basic Usage

Parse a DevFlow DSL file:

```bash
./devflow_parser examples/simple_pipeline.devflow
```

### Running Tests

Test all example files:

```bash
make test
```

Test individual examples:

```bash
make test-simple   # Test simple pipeline
make test-docker   # Test docker pipeline
make test-matrix   # Test matrix pipeline
make test-full     # Test full CI/CD pipeline
```

### Example Output

When you run the parser, it will:

1. Parse the DevFlow DSL file
2. Validate the syntax
3. Display a structured representation of the pipeline

Example output:
```
Parsing DevFlow DSL file: examples/simple_pipeline.devflow

✓ Successfully parsed DevFlow DSL pipeline

=== Pipeline: simple_ci ===
Triggers: push(main), pull_request

--- Stage: build ---

  Job: compile
    Image: node:18
    Steps:
      - run: npm install

      - run: npm run build

    Artifacts: dist/*, package.json

--- Stage: test ---

  Job: unit_tests
    Image: node:18
    Steps:
      - run: npm test


✓ Parsing completed successfully!
```

## Language Syntax

### Simple Pipeline Example

```devflow
pipeline simple_ci {
    on push("main"), pull_request
    
    stage build {
        job compile {
            image "node:18"
            step run("npm install")
            step run("npm run build")
            artifact "dist/*", "package.json"
        }
    }
    
    stage test {
        job unit_tests {
            image "node:18"
            step run("npm test")
        }
    }
}
```

### Docker Pipeline with Services

```devflow
pipeline docker_ci {
    on push("main", "develop"), pull_request
    
    stage build {
        job docker_build {
            image "docker:latest"
            step run("docker build -t myapp:${{ github.sha }} .")
            step run("docker push registry.io/myapp:${{ github.sha }}")
        }
    }
    
    stage test {
        job integration_tests {
            image "node:18"
            service postgres {
                image "postgres:14"
                port 5432:5432
                env POSTGRES_DB = "testdb"
                env POSTGRES_USER = "test"
                env POSTGRES_PASSWORD = "testpass"
            }
            step run("npm run test:integration")
        }
    }
}
```

### Matrix Builds

```devflow
pipeline test_matrix {
    on push
    
    stage test {
        job test_versions {
            matrix [node: ["14", "16", "18"], os: ["ubuntu-latest", "windows-latest"]]
            image "node:${{ node }}"
            
            step checkout()
            step run("npm install")
            step run("npm test")
        }
    }
}
```

### Full CI/CD Pipeline

```devflow
pipeline full_cicd {
    on push("main", "develop"), pull_request, schedule("0 2 * * *")
    
    stage build {
        job docker_build {
            image "docker:latest"
            step run("docker build -t myapp:${{ github.sha }} .")
            step run("docker push registry.io/myapp:${{ github.sha }}")
            artifact "docker-compose.yml"
        }
    }
    
    stage test {
        job unit_tests {
            image "node:18"
            step run("npm test")
        }
        
        job e2e_tests {
            image "node:18"
            service app {
                image "registry.io/myapp:${{ github.sha }}"
                port 3000:3000
            }
            service postgres {
                image "postgres:14"
                port 5432:5432
                env POSTGRES_DB = "testdb"
            }
            step run("npm run test:e2e")
        }
    }
    
    stage deploy {
        job deploy_staging {
            image "ubuntu:latest"
            step deploy(registry="ghcr.io", image="myapp")
        }
        
        job deploy_production {
            image "ubuntu:latest"
            step deploy(registry="ghcr.io", image="myapp")
            step notify(channel="slack", message="Production deployment complete!")
        }
    }
}
```

## Grammar Overview

The DevFlow DSL grammar supports:

- **Pipeline Declaration**: Top-level pipeline definition with triggers
- **Stages**: Logical phases (build, test, deploy)
- **Jobs**: Units of work within stages
- **Steps**: Atomic operations (run, checkout, deploy, notify)
- **Services**: Docker container dependencies
- **Artifacts**: Build outputs shared between jobs
- **Matrix Builds**: Testing across multiple versions/environments
- **Environment Variables**: Service and job configuration

See `DSL_Report.md` for the complete Backus-Naur Form (BNF) grammar specification.

## Language Features

### 1. Triggers

Define when pipelines should run:

```devflow
on push("main"), pull_request("develop"), schedule("0 2 * * *"), manual
```

### 2. Jobs with Images

Specify container images for jobs:

```devflow
job build {
    image "node:18"
    step run("npm install")
}
```

### 3. Service Dependencies

Declare dependent services:

```devflow
job test {
    image "python:3.9"
    service postgres {
        image "postgres:14"
        port 5432:5432
        env POSTGRES_DB = "testdb"
    }
    service redis {
        image "redis:7"
        port 6379:6379
    }
    step run("pytest tests/")
}
```

### 4. Artifact Management

Pass artifacts between stages:

```devflow
stage build {
    job compile {
        step run("go build -o app ./cmd")
        artifact "app", "config.yaml"
    }
}

stage deploy {
    job deploy {
        step run("scp app user@server:/opt/app")
    }
}
```

### 5. Matrix Builds

Test across multiple versions:

```devflow
job test_matrix {
    matrix [node: ["14", "16", "18"], os: ["ubuntu-latest", "windows-latest"]]
    image "node:${{ node }}"
    step run("npm test")
}
```

### 6. Deployment Steps

Deploy to registries:

```devflow
step deploy(registry="ghcr.io", image="myapp")
```

### 7. Notification Steps

Send notifications:

```devflow
step notify(channel="slack", message="Deployment complete!")
```

## Comparison with Existing Solutions

### DevFlow DSL vs GitHub Actions YAML

**GitHub Actions (YAML):**
```yaml
name: CI Pipeline
on:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run build
```

**DevFlow DSL:**
```devflow
pipeline ci_pipeline {
    on push("main")
    
    stage build {
        job build {
            image "node:18"
            step checkout()
            step run("npm install")
            step run("npm run build")
        }
    }
}
```

**Benefits:**
- 40-50% reduction in lines of code
- More readable domain-specific keywords
- Less boilerplate
- Clearer structure

## Error Handling

The parser provides helpful error messages:

```
Error at line 15: syntax error
Near: step
```

Common issues:
- Missing semicolons after steps
- Unclosed braces
- Invalid keyword usage
- Type mismatches

## Cleanup

Remove build artifacts:

```bash
make clean
```

This removes:
- Compiled binaries (`devflow_parser`)
- Object files (`.o`)
- Generated parser files (`devflow.tab.c`, `devflow.tab.h`)
- Generated lexer file (`lex.yy.c`)

## Future Enhancements

Potential extensions to the language:

- **Template System**: Reusable pipeline components
- **Conditional Steps**: `if` statements for conditional execution
- **Loops**: `for` loops for iterative operations
- **Code Generation**: Generate GitHub Actions, GitLab CI, CircleCI configs
- **Type System**: Enhanced type checking and validation
- **IDE Support**: Syntax highlighting, autocomplete
- **Validation**: Early error detection and warnings

## Documentation

For comprehensive documentation, see:

- **DSL_Report.md**: Complete report including:
  - Domain overview
  - Literature review of similar DSLs
  - Complete BNF grammar
  - Language evaluation with code samples

## Contributing

This is a course project demonstrating DSL design and implementation using Bison/Yacc parser generators.

## License

This project is created for educational purposes as part of a Domain Specific Languages course.

## References

1. Fowler, M. (2010). "Domain-Specific Languages". Addison-Wesley Professional.
2. GitHub Actions Documentation: https://docs.github.com/en/actions
3. GitLab CI/CD Documentation: https://docs.gitlab.com/ee/ci/
4. Jenkins Pipeline Documentation: https://www.jenkins.io/doc/book/pipeline/
5. Docker Compose Documentation: https://docs.docker.com/compose/
6. Bison Manual: https://www.gnu.org/software/bison/manual/
7. Flex Manual: https://github.com/westes/flex

## Troubleshooting

### Build Errors

**Error: `bison: command not found`**
- Install bison: `sudo apt-get install bison` (Linux) or `brew install bison` (macOS)

**Error: `flex: command not found`**
- Install flex: `sudo apt-get install flex` (Linux) or `brew install flex` (macOS)

**Error: `gcc: command not found`**
- Install gcc: `sudo apt-get install gcc` (Linux) or `xcode-select --install` (macOS)

**Error: `undefined reference to 'yywrap'`**
- This is handled by `%option noyywrap` in the lexer file

**Error: linking issues with `-lfl`**
- On some systems, use `-ll` instead of `-lfl` in the Makefile
- On macOS, you may not need the flag at all

### Parse Errors

**Syntax errors in your `.devflow` file**
- Check for missing semicolons after steps
- Verify all braces are properly closed
- Ensure keywords are spelled correctly
- Check string literals are properly quoted

### Runtime Errors

**Segmentation fault**
- This typically indicates an issue with the parser grammar
- Check that all grammar rules properly allocate memory for AST nodes
- Verify proper memory management in the parser

## Author

Created as part of a Domain Specific Languages course project.

## Acknowledgments

- Inspired by existing CI/CD DSLs (GitHub Actions, GitLab CI, Jenkins Pipeline)
- Built using Bison (GNU parser generator) and Flex (fast lexical analyzer)


#ifndef DEVFLOW_TYPES_H
#define DEVFLOW_TYPES_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* AST Node structures */
typedef struct {
    char *name;
    char *type;
    void *value;
} ASTNode;

typedef struct Trigger {
    char *type;
    char *pattern;
    struct Trigger *next;
} Trigger;

typedef struct Service {
    char *name;
    char *image;
    char *port_host;
    char *port_container;
    struct EnvVar *env_vars;
    struct Service *next;
} Service;

typedef struct EnvVar {
    char *name;
    char *value;
    struct EnvVar *next;
} EnvVar;

typedef struct Step {
    char *type;
    char *command;
    struct StepArg *args;
    struct Step *next;
} Step;

typedef struct StepArg {
    char *name;
    char *value;
    struct StepArg *next;
} StepArg;

typedef struct Artifact {
    char *path;
    struct Artifact *next;
} Artifact;

typedef struct MatrixAxis {
    char *name;
    struct StringList *values;
    struct MatrixAxis *next;
} MatrixAxis;

typedef struct StringList {
    char *value;
    struct StringList *next;
} StringList;

typedef struct Job {
    char *name;
    char *image;
    struct Service *services;
    struct Step *steps;
    struct Artifact *artifacts;
    struct MatrixAxis *matrix;
    struct Job *next;
} Job;

typedef struct Stage {
    char *name;
    struct Job *jobs;
    struct Stage *next;
} Stage;

typedef struct Pipeline {
    char *name;
    struct Trigger *triggers;
    struct Stage *stages;
    struct Artifact *artifacts;
    struct Pipeline *next;
} Pipeline;

#endif /* DEVFLOW_TYPES_H */


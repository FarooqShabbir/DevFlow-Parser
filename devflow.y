%{
#include "devflow_types.h"

extern int yylineno;
extern FILE *yyin;
extern char *yytext;

/* Function prototypes */
int yylex(void);
void yyerror(const char *s);
void print_ast(void);
void print_pipeline(void);
void print_stage(Stage *s);
void print_job(Job *j);
void print_step(Step *s);

/* Global AST root */
static Pipeline *ast_root = NULL;
static Pipeline *current_pipeline = NULL;

%}

%union {
    int number;
    char *string;
    Trigger *trigger;
    Service *service;
    EnvVar *env_var;
    Step *step;
    StepArg *step_arg;
    Artifact *artifact;
    MatrixAxis *matrix_axis;
    StringList *string_list;
    Job *job;
    Stage *stage;
    Pipeline *pipeline;
}

%token <string> IDENTIFIER STRING_LITERAL
%token <number> NUMBER
%token PIPELINE STAGE JOB STEP ON SERVICE IMAGE PORT ENV ARTIFACT
%token MATRIX IF ELSE FOR IN
%token RUN CHECKOUT CACHE DEPLOY NOTIFY
%token PUSH PULL_REQUEST SCHEDULE MANUAL
%token AND OR EQ NE LE GE LT GT NOT
%token ASSIGN PLUS MINUS MULT DIV
%token LBRACE RBRACE LBRACKET RBRACKET LPAREN RPAREN
%token COMMA SEMICOLON COLON DOLLAR DOUBLE_LBRACE DOUBLE_RBRACE

%type <pipeline> program pipeline_decl pipeline_body
%type <trigger> trigger_list trigger trigger_decl
%type <stage> stage_decl stage_decl_list
%type <job> job_decl job_decl_list job_body
%type <string_list> string_list
%type <matrix_axis> matrix_axes matrix_axis matrix_decl
%type <service> service_decl service_decl_list service_body port_decl
%type <env_var> env_decl env_decl_list
%type <step> step_decl step_decl_list
%type <step_arg> step_args step_arg
%type <artifact> artifact_decl artifact_decl_list
%type <string> image_decl

%%

program:
    pipeline_decl {
        ast_root = $1;
        printf("✓ Successfully parsed DevFlow DSL pipeline\n");
        print_pipeline();
    }
    | program pipeline_decl {
        if (ast_root == NULL) {
            ast_root = $2;
        } else {
            Pipeline *p = ast_root;
            while (p->next) p = p->next;
            p->next = $2;
        }
        printf("✓ Successfully parsed additional DevFlow DSL pipeline\n");
        print_pipeline();
    }
    ;

pipeline_decl:
    PIPELINE IDENTIFIER LBRACE pipeline_body RBRACE {
        $$ = (Pipeline *)calloc(1, sizeof(Pipeline));
        $$->name = $2;
        $$->triggers = $4->triggers;
        $$->stages = $4->stages;
        $$->artifacts = $4->artifacts;
        current_pipeline = $$;
    }
    ;

pipeline_body:
    trigger_decl stage_decl_list artifact_decl_list {
        Pipeline *p = (Pipeline *)calloc(1, sizeof(Pipeline));
        p->triggers = $1;
        p->stages = $2;
        p->artifacts = $3;
        $$ = p;
    }
    | stage_decl_list artifact_decl_list {
        Pipeline *p = (Pipeline *)calloc(1, sizeof(Pipeline));
        p->stages = $1;
        p->artifacts = $2;
        $$ = p;
    }
    ;

trigger_decl:
    ON trigger_list {
        $$ = $2;
    }
    ;

trigger_list:
    trigger {
        $$ = $1;
    }
    | trigger_list COMMA trigger {
        Trigger *t = $1;
        while (t->next) t = t->next;
        t->next = $3;
        $$ = $1;
    }
    ;

trigger:
    PUSH {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("push");
    }
    | PULL_REQUEST {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("pull_request");
    }
    | SCHEDULE {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("schedule");
    }
    | MANUAL {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("manual");
    }
    | PUSH LPAREN string_list RPAREN {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("push");
        /* Combine multiple patterns with comma */
        StringList *sl = $3;
        char *patterns = (char *)calloc(1024, sizeof(char));
        int first = 1;
        while (sl) {
            if (!first) strcat(patterns, ",");
            strcat(patterns, sl->value);
            first = 0;
            sl = sl->next;
        }
        $$->pattern = patterns;
    }
    | PULL_REQUEST LPAREN string_list RPAREN {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("pull_request");
        /* Combine multiple patterns with comma */
        StringList *sl = $3;
        char *patterns = (char *)calloc(1024, sizeof(char));
        int first = 1;
        while (sl) {
            if (!first) strcat(patterns, ",");
            strcat(patterns, sl->value);
            first = 0;
            sl = sl->next;
        }
        $$->pattern = patterns;
    }
    | PUSH LPAREN STRING_LITERAL RPAREN {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("push");
        $$->pattern = $3;
    }
    | PULL_REQUEST LPAREN STRING_LITERAL RPAREN {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("pull_request");
        $$->pattern = $3;
    }
    | SCHEDULE LPAREN STRING_LITERAL RPAREN {
        $$ = (Trigger *)calloc(1, sizeof(Trigger));
        $$->type = strdup("schedule");
        $$->pattern = $3;
    }
    ;

stage_decl_list:
    stage_decl {
        $$ = $1;
    }
    | stage_decl_list stage_decl {
        Stage *s = $1;
        while (s->next) s = s->next;
        s->next = $2;
        $$ = $1;
    }
    ;

stage_decl:
    STAGE IDENTIFIER LBRACE job_decl_list RBRACE {
        $$ = (Stage *)calloc(1, sizeof(Stage));
        $$->name = $2;
        $$->jobs = $4;
    }
    ;

job_decl_list:
    job_decl {
        $$ = $1;
    }
    | job_decl_list job_decl {
        Job *j = $1;
        while (j->next) j = j->next;
        j->next = $2;
        $$ = $1;
    }
    ;

job_decl:
    JOB IDENTIFIER LBRACE job_body RBRACE {
        $$ = (Job *)calloc(1, sizeof(Job));
        $$->name = $2;
        if ($4->image) $$->image = $4->image;
        if ($4->services) $$->services = $4->services;
        if ($4->steps) $$->steps = $4->steps;
        if ($4->artifacts) $$->artifacts = $4->artifacts;
        if ($4->matrix) $$->matrix = $4->matrix;
        free($4);
    }
    ;

job_body:
    image_decl service_decl_list step_decl_list artifact_decl_list {
        Job *j = (Job *)calloc(1, sizeof(Job));
        j->image = $1;
        j->services = $2;
        j->steps = $3;
        j->artifacts = $4;
        $$ = j;
    }
    | matrix_decl job_body {
        if ($2->matrix) {
            MatrixAxis *m = $1;
            while (m->next) m = m->next;
            m->next = $2->matrix;
            $2->matrix = $1;
        } else {
            $2->matrix = $1;
        }
        $$ = $2;
    }
    ;

image_decl:
    IMAGE STRING_LITERAL {
        $$ = $2;
    }
    | { $$ = NULL; }
    ;

service_decl_list:
    service_decl {
        $$ = $1;
    }
    | service_decl_list service_decl {
        Service *s = $1;
        while (s->next) s = s->next;
        s->next = $2;
        $$ = $1;
    }
    | { $$ = NULL; }
    ;

service_decl:
    SERVICE IDENTIFIER LBRACE service_body RBRACE {
        $$ = (Service *)calloc(1, sizeof(Service));
        $$->name = $2;
        if ($4->image) $$->image = $4->image;
        if ($4->port_host) $$->port_host = $4->port_host;
        if ($4->port_container) $$->port_container = $4->port_container;
        if ($4->env_vars) $$->env_vars = $4->env_vars;
        free($4);
    }
    ;

service_body:
    image_decl port_decl env_decl_list {
        Service *s = (Service *)calloc(1, sizeof(Service));
        s->image = $1;
        if ($2) {
            s->port_host = $2->port_host;
            s->port_container = $2->port_container;
            free($2);
        }
        s->env_vars = $3;
        $$ = s;
    }
    ;

port_decl:
    PORT NUMBER COLON NUMBER {
        Service *s = (Service *)calloc(1, sizeof(Service));
        char buf1[32], buf2[32];
        sprintf(buf1, "%d", $2);
        sprintf(buf2, "%d", $4);
        s->port_host = strdup(buf1);
        s->port_container = strdup(buf2);
        $$ = s;
    }
    | { $$ = NULL; }
    ;

env_decl_list:
    env_decl {
        $$ = $1;
    }
    | env_decl_list env_decl {
        EnvVar *e = $1;
        while (e->next) e = e->next;
        e->next = $2;
        $$ = $1;
    }
    | { $$ = NULL; }
    ;

env_decl:
    ENV IDENTIFIER ASSIGN STRING_LITERAL SEMICOLON {
        $$ = (EnvVar *)calloc(1, sizeof(EnvVar));
        $$->name = $2;
        $$->value = $4;
    }
    ;

step_decl_list:
    step_decl {
        $$ = $1;
    }
    | step_decl_list step_decl {
        Step *s = $1;
        while (s->next) s = s->next;
        s->next = $2;
        $$ = $1;
    }
    ;

step_decl:
    STEP RUN LPAREN STRING_LITERAL RPAREN opt_semicolon {
        $$ = (Step *)calloc(1, sizeof(Step));
        $$->type = strdup("run");
        $$->command = $4;
    }
    | STEP RUN LPAREN step_args RPAREN opt_semicolon {
        $$ = (Step *)calloc(1, sizeof(Step));
        $$->type = strdup("run");
        if ($4) {
            StepArg *arg = $4;
            while (arg) {
                if (strcmp(arg->name, "command") == 0) {
                    $$->command = strdup(arg->value);
                }
                arg = arg->next;
            }
        }
    }
    | STEP CHECKOUT LPAREN RPAREN opt_semicolon {
        $$ = (Step *)calloc(1, sizeof(Step));
        $$->type = strdup("checkout");
    }
    | STEP DEPLOY LPAREN step_args RPAREN opt_semicolon {
        $$ = (Step *)calloc(1, sizeof(Step));
        $$->type = strdup("deploy");
        $$->args = $4;
    }
    | STEP NOTIFY LPAREN step_args RPAREN opt_semicolon {
        $$ = (Step *)calloc(1, sizeof(Step));
        $$->type = strdup("notify");
        $$->args = $4;
    }
    ;

opt_semicolon:
    SEMICOLON
    | { /* empty */ }
    ;

step_args:
    step_arg {
        $$ = $1;
    }
    | step_arg COMMA step_args {
        $1->next = $3;
        $$ = $1;
    }
    ;

step_arg:
    IDENTIFIER ASSIGN STRING_LITERAL {
        $$ = (StepArg *)calloc(1, sizeof(StepArg));
        $$->name = $1;
        $$->value = $3;
    }
    | IMAGE ASSIGN STRING_LITERAL {
        $$ = (StepArg *)calloc(1, sizeof(StepArg));
        $$->name = strdup("image");
        $$->value = $3;
    }
    ;

matrix_decl:
    MATRIX LBRACKET matrix_axes RBRACKET {
        $$ = $3;
    }
    ;

matrix_axes:
    matrix_axis {
        $$ = $1;
    }
    | matrix_axis COMMA matrix_axes {
        $1->next = $3;
        $$ = $1;
    }
    ;

matrix_axis:
    IDENTIFIER COLON LBRACKET string_list RBRACKET {
        $$ = (MatrixAxis *)calloc(1, sizeof(MatrixAxis));
        $$->name = $1;
        $$->values = $4;
    }
    ;

string_list:
    STRING_LITERAL {
        $$ = (StringList *)calloc(1, sizeof(StringList));
        $$->value = $1;
    }
    | STRING_LITERAL COMMA string_list {
        $$ = (StringList *)calloc(1, sizeof(StringList));
        $$->value = $1;
        $$->next = $3;
    }
    ;

artifact_decl_list:
    artifact_decl {
        $$ = $1;
    }
    | artifact_decl_list artifact_decl {
        Artifact *a = $1;
        while (a->next) a = a->next;
        a->next = $2;
        $$ = $1;
    }
    | { $$ = NULL; }
    ;

artifact_decl:
    ARTIFACT string_list SEMICOLON {
        /* Convert string_list to artifact list */
        Artifact *first = NULL, *last = NULL;
        StringList *sl = $2;
        while (sl) {
            Artifact *a = (Artifact *)calloc(1, sizeof(Artifact));
            a->path = sl->value;
            if (!first) first = a;
            if (last) last->next = a;
            last = a;
            StringList *next = sl->next;
            free(sl);
            sl = next;
        }
        $$ = first;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
    fprintf(stderr, "Near: %s\n", yytext);
}

void print_pipeline(void) {
    if (!ast_root) return;
    
    Pipeline *p = ast_root;
    while (p) {
        printf("\n=== Pipeline: %s ===\n", p->name);
        
        if (p->triggers) {
            printf("Triggers: ");
            Trigger *t = p->triggers;
            while (t) {
                printf("%s", t->type);
                if (t->pattern) printf("(%s)", t->pattern);
                if (t->next) printf(", ");
                t = t->next;
            }
            printf("\n");
        }
        
        Stage *s = p->stages;
        while (s) {
            print_stage(s);
            s = s->next;
        }
        
        if (p->artifacts) {
            printf("Pipeline Artifacts: ");
            Artifact *a = p->artifacts;
            while (a) {
                printf("%s", a->path);
                if (a->next) printf(", ");
                a = a->next;
            }
            printf("\n");
        }
        
        p = p->next;
    }
}

void print_stage(Stage *s) {
    if (!s) return;
    printf("\n--- Stage: %s ---\n", s->name);
    
    Job *j = s->jobs;
    while (j) {
        print_job(j);
        j = j->next;
    }
}

void print_job(Job *j) {
    if (!j) return;
    printf("\n  Job: %s\n", j->name);
    
    if (j->image) {
        printf("    Image: %s\n", j->image);
    }
    
    if (j->matrix) {
        printf("    Matrix:\n");
        MatrixAxis *m = j->matrix;
        while (m) {
            printf("      %s: [", m->name);
            StringList *sl = m->values;
            while (sl) {
                printf("%s", sl->value);
                if (sl->next) printf(", ");
                sl = sl->next;
            }
            printf("]\n");
            m = m->next;
        }
    }
    
    if (j->services) {
        printf("    Services:\n");
        Service *svc = j->services;
        while (svc) {
            printf("      - %s (%s", svc->name, svc->image);
            if (svc->port_host) {
                printf(":%s->%s", svc->port_host, svc->port_container);
            }
            printf(")\n");
            EnvVar *e = svc->env_vars;
            while (e) {
                printf("        %s=%s\n", e->name, e->value);
                e = e->next;
            }
            svc = svc->next;
        }
    }
    
    if (j->steps) {
        printf("    Steps:\n");
        Step *st = j->steps;
        while (st) {
            print_step(st);
            st = st->next;
        }
    }
    
    if (j->artifacts) {
        printf("    Artifacts: ");
        Artifact *a = j->artifacts;
        while (a) {
            printf("%s", a->path);
            if (a->next) printf(", ");
            a = a->next;
        }
        printf("\n");
    }
}

void print_step(Step *s) {
    if (!s) return;
    printf("      - %s", s->type);
    if (s->command) {
        printf(": %s", s->command);
    }
    if (s->args) {
        printf(" (");
        StepArg *arg = s->args;
        while (arg) {
            printf("%s=%s", arg->name, arg->value);
            if (arg->next) printf(", ");
            arg = arg->next;
        }
        printf(")");
    }
    printf("\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <devflow_file>\n", argv[0]);
        return 1;
    }
    
    FILE *file = fopen(argv[1], "r");
    if (!file) {
        fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    yyin = file;
    
    printf("Parsing DevFlow DSL file: %s\n\n", argv[1]);
    
    if (yyparse() == 0) {
        printf("\n✓ Parsing completed successfully!\n");
        fclose(file);
        return 0;
    } else {
        fprintf(stderr, "\n✗ Parsing failed!\n");
        fclose(file);
        return 1;
    }
}


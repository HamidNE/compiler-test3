%union {
    float f;
}

%token <f> NUM
%type <f> E T F

%%

S : E;

E : E '+' T | E '-' T | T;

T : T '*' F | T '/' F | F;

F : '(' E ')' | '-' F | NUM;

%%
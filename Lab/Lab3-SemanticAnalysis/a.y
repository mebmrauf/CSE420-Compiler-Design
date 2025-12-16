%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table* table;

string current_type;
vector<pair<string,string>> current_func_params;

int lines = 1;
int error_count = 0;

ofstream outlog;
ofstream outerror("output1818_error.txt", ios::trunc);

void semantic_error(string msg){
    outerror << "Error at line " << lines << ": " << msg << endl;
    error_count++;
}

void semantic_warning(string msg){
    outerror << "Warning at line " << lines << ": " << msg << endl;
}

void yyerror(char *s){
    // syntax error
    outerror << "Syntax error at line " << lines << endl;
    error_count++;
}

symbol_info* lookup_symbol(string name){
    symbol_info* temp = new symbol_info(name,"ID");
    symbol_info* found = table->lookup(temp);
    delete temp;
    return found;
}

bool declared_current(string name){
    symbol_info* temp = new symbol_info(name,"ID");
    bool ok = table->lookup_current_scope(temp) != NULL;
    delete temp;
    return ok;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
{
    outlog << "Symbol Table\n\n";
    table->print_all_scopes(outlog);
}
;

program : program unit
        | unit
        ;

unit : var_declaration
     | func_definition
     ;

func_definition
: type_specifier ID LPAREN parameter_list RPAREN compound_statement
{
    if(declared_current($2->get_name())){
        semantic_error("Multiple declaration of function " + $2->get_name());
    } else {
        symbol_info* f = new symbol_info($2->get_name(),"ID",$1->get_name(),current_func_params);
        table->insert(f);
    }
    current_func_params.clear();
}
| type_specifier ID LPAREN RPAREN compound_statement
{
    if(declared_current($2->get_name())){
        semantic_error("Multiple declaration of function " + $2->get_name());
    } else {
        vector<pair<string,string>> p;
        symbol_info* f = new symbol_info($2->get_name(),"ID",$1->get_name(),p);
        table->insert(f);
    }
}
;

parameter_list
: parameter_list COMMA type_specifier ID
{
    current_func_params.push_back({$3->get_name(),$4->get_name()});
}
| type_specifier ID
{
    current_func_params.push_back({$1->get_name(),$2->get_name()});
}
;

compound_statement
: LCURL { table->enter_scope(); } statements RCURL
{
    table->print_current_scope();
    table->exit_scope();
}
| LCURL { table->enter_scope(); } RCURL
{
    table->print_current_scope();
    table->exit_scope();
}
;

var_declaration
: type_specifier declaration_list SEMICOLON
{
    if($1->get_name()=="void")
        semantic_error("Variable declared void");
}
;

type_specifier
: INT   { $$ = new symbol_info("int","type"); current_type="int"; }
| FLOAT { $$ = new symbol_info("float","type"); current_type="float"; }
| VOID  { $$ = new symbol_info("void","type"); current_type="void"; }
;

declaration_list
: declaration_list COMMA ID
{
    if(declared_current($3->get_name()))
        semantic_error("Multiple declaration of " + $3->get_name());
    else
        table->insert(new symbol_info($3->get_name(),"ID",current_type));
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
{
    if(declared_current($3->get_name()))
        semantic_error("Multiple declaration of array " + $3->get_name());
    else
        table->insert(new symbol_info($3->get_name(),"ID",current_type,stoi($5->get_name())));
}
| ID
{
    if(declared_current($1->get_name()))
        semantic_error("Multiple declaration of " + $1->get_name());
    else
        table->insert(new symbol_info($1->get_name(),"ID",current_type));
}
| ID LTHIRD CONST_INT RTHIRD
{
    if(declared_current($1->get_name()))
        semantic_error("Multiple declaration of array " + $1->get_name());
    else
        table->insert(new symbol_info($1->get_name(),"ID",current_type,stoi($3->get_name())));
}
;

statements
: statement
| statements statement
;

statement
: expression_statement
| compound_statement
| var_declaration
| RETURN expression SEMICOLON
;

expression_statement
: SEMICOLON
| expression SEMICOLON
;

expression
: variable ASSIGNOP logic_expression
{
    if($1->get_data_type() != $3->get_data_type()){
        if($1->get_data_type()=="int" && $3->get_data_type()=="float")
            semantic_warning("Float to int assignment");
        else
            semantic_error("Type mismatch in assignment");
    }
    $$ = new symbol_info("", "expr", $1->get_data_type());
}
| logic_expression { $$=$1; }
;

logic_expression
: rel_expression
| rel_expression LOGICOP rel_expression
{
    $$ = new symbol_info("","expr","int");
}
;

rel_expression
: simple_expression
| simple_expression RELOP simple_expression
{
    $$ = new symbol_info("","expr","int");
}
;

simple_expression
: term
| simple_expression ADDOP term
{
    if($1->get_data_type()=="float" || $3->get_data_type()=="float")
        $$=new symbol_info("","expr","float");
    else
        $$=new symbol_info("","expr","int");
}
;

term
: unary_expression
| term MULOP unary_expression
{
    if($2->get_name()=="%" &&
      ($1->get_data_type()!="int" || $3->get_data_type()!="int"))
        semantic_error("Operands of modulus must be integers");

    if(($2->get_name()=="/"||$2->get_name()=="%") && $3->get_name()=="0")
        semantic_error("Division by zero");

    if($1->get_data_type()=="float"||$3->get_data_type()=="float")
        $$=new symbol_info("","expr","float");
    else
        $$=new symbol_info("","expr","int");
}
;

unary_expression
: ADDOP unary_expression { $$=$2; }
| NOT unary_expression   { $$=new symbol_info("","expr","int"); }
| factor
;

factor
: variable { $$=$1; }
| ID LPAREN argument_list RPAREN
{
    symbol_info* f = lookup_symbol($1->get_name());
    if(!f) semantic_error("Undeclared function "+$1->get_name());
    else if(!f->get_is_function())
        semantic_error($1->get_name()+" is not a function");
    else if(f->get_return_type()=="void")
        semantic_error("Void function used in expression");

    $$=new symbol_info("","expr",f?f->get_return_type():"int");
}
| LPAREN expression RPAREN { $$=$2; }
| CONST_INT   { $$=new symbol_info($1->get_name(),"const","int"); }
| CONST_FLOAT { $$=new symbol_info($1->get_name(),"const","float"); }
;

variable
: ID
{
    symbol_info* v = lookup_symbol($1->get_name());
    if(!v) semantic_error("Undeclared variable "+$1->get_name());
    else if(v->get_is_array())
        semantic_error("Array used without index");

    $$ = v ? new symbol_info("", "var", v->get_data_type())
           : new symbol_info("", "var", "int");
}
| ID LTHIRD expression RTHIRD
{
    symbol_info* v = lookup_symbol($1->get_name());
    if(!v) semantic_error("Undeclared array "+$1->get_name());
    else if(!v->get_is_array())
        semantic_error("Indexing non-array "+$1->get_name());

    if($3->get_data_type()!="int")
        semantic_error("Array index not integer");

    $$ = v ? new symbol_info("", "var", v->get_data_type())
           : new symbol_info("", "var", "int");
}
;

argument_list
: arguments
|
;

arguments
: arguments COMMA logic_expression
| logic_expression
;

%%

int main(int argc,char* argv[]){
    yyin=fopen(argv[1],"r");
    outlog.open("output1818_log.txt");
    table=new symbol_table(10);
    yyparse();
    outlog<<"Total lines: "<<lines<<endl;
    outlog<<"Total errors: "<<error_count<<endl;
    outerror<<"Total errors: "<<error_count<<endl;
    return 0;
}

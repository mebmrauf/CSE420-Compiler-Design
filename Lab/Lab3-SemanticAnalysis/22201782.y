%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table* table;

string current_type;
vector<pair<string, string>> function_parameters;
vector<pair<string, string>> function_parameter_current;


ofstream outlog;
ofstream errorlog;
int lines = 1;
int total_error = 0;


void yyerror(char *s)
{
//	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
}

bool is_function_declared(string name){
	symbol_info* temp = new symbol_info(name, "ID");
	symbol_info* found = table->lookup(temp);
	delete temp;
	return found != NULL && found->get_is_function();
}

bool variable_in_current_scope(string name){
    symbol_info* temp = new symbol_info(name, "ID");
    symbol_info* is_found = table->lookup_current_scope(temp);
    delete temp;
    return is_found != NULL;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;

		// Print your whole symbol table here
		table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"program");
	};

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
			if(is_function_declared($2->get_name()) || variable_in_current_scope($2->get_name())) {
				errorlog<< "At line no: " << lines << " Multiple declaration of function " << $2->get_name() << endl << endl;
				outlog<< "At line no: " << lines << " Multiple declaration of function " << $2->get_name() << endl << endl;
				total_error++;
			}
			else{
				vector<pair<string, string> > parameters;
				parameters = function_parameter_current;
				symbol_info* func = new symbol_info($2->get_name(), $1->get_name());
				func->set_as_function($1->get_name(), parameters);
				table->insert(func);
				string current_function_name = $2->get_name();
				if(!function_parameters.empty()){
					for(auto parameter : function_parameters){
						errorlog<< "At line no: " << lines << " Multiple declaration of variable " << parameter.second << " in parameter of " << current_function_name << endl << endl;
						outlog<< "At line no: " << lines << " Multiple declaration of variable " << parameter.second << " in parameter of " << current_function_name << endl << endl;
						total_error++;
					}
					function_parameters.clear();
				}
			}

		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
			outlog << $1->get_name() << " " << $2->get_name() << "(" + $4->get_name() + ")\n" << $7->get_name() << endl << endl;

			$$ = new symbol_info($1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name(), "func_def");

			function_parameter_current.clear();
			current_type = "";
		}
		| type_specifier ID LPAREN RPAREN {
			if(!is_function_declared($2->get_name())) {
				vector<pair<string, string> > parameters;
				symbol_info* func = new symbol_info($2->get_name(), $1->get_name());
				func->set_as_function($1->get_name(), parameters);
				table->insert(func);
			}

		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
			outlog << $1->get_name() << " " << $2->get_name() << "()\n" << $6->get_name() << endl << endl;

			$$ = new symbol_info($1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name(), "func_def");
			current_type = "";
		}
		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");


			pair<string, string> parameter($3->get_name(), $4->get_name());
			if(!function_parameter_current.empty()){
				for(auto parameter : function_parameter_current){
					if(parameter.second == $4->get_name()){
						function_parameters.push_back(parameter);
					}
				}
			}
			function_parameter_current.push_back(parameter);

		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");

			pair<string, string> parameter($3->get_name(), "");
			function_parameter_current.push_back(parameter);
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");

			pair<string, string> parameter($1->get_name(), $2->get_name());
			function_parameter_current.push_back(parameter);
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"param_list");

			pair<string, string> parameter($1->get_name(), "");
			function_parameter_current.push_back(parameter);
		}
 		;

compound_statement : LCURL {
		table->enter_scope();

		if(!function_parameter_current.empty()) {
			for(auto parameter : function_parameter_current) {
				if(!parameter.second.empty()) {
					symbol_info* parameter_symbol = new symbol_info(parameter.second, parameter.first);
					table->insert(parameter_symbol);
				}
			}
		}
	} statements RCURL
	{
		outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
		outlog << "{\n" + $3->get_name() + "\n}" << endl << endl;

		table->print_current_scope();
		table->exit_scope();

		$$ = new symbol_info("{\n" + $3->get_name() + "\n}", "comp_stmnt");
	}
	| LCURL {
		// Enter a new scope
		table->enter_scope();
	} RCURL
	{
		outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
		outlog << "{\n}" << endl << endl;

		table->print_current_scope();
		table->exit_scope();

		$$ = new symbol_info("{\n}", "comp_stmnt");
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");

		 	if($1->get_name() == "void"){
				errorlog << "At line no: " << lines << " variable type can not be void" << endl << endl;
				outlog << "At line no: " << lines << " variable type can not be void" << endl << endl;
				total_error++;
			}
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;

			$$ = new symbol_info("int","type");
			current_type = "int";
			$$->set_type("int");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;

			$$ = new symbol_info("float","type");
			current_type = "float";
			$$->set_type("float");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;

			$$ = new symbol_info("void","type");
			current_type = "void";
			$$->set_type("void");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
 		  	outlog << $1->get_name() + "," << $3->get_name() << endl << endl;
			$$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");

            if(!variable_in_current_scope($3->get_name())) {
                symbol_info* temp = new symbol_info($3->get_name(), current_type);
                table->insert(temp);
            }
			else {
				errorlog << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
				total_error++;
            }
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
 		  	outlog << $1->get_name() + "," << $3->get_name() << "[" << $5->get_name() << "]" << endl << endl;
			$$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");

            if(!variable_in_current_scope($3->get_name())) {
                // Create and insert new array
                int size = stoi($5->get_name());
                symbol_info* temp = new symbol_info($3->get_name(), current_type, size);
                table->insert(temp);
            }
			else {
				errorlog << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
				total_error++;
            }
 		  }
 		  |ID
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
			outlog << $1->get_name() << endl << endl;
			$$ = new symbol_info($1->get_name(), "decl_list");

            if(!variable_in_current_scope($1->get_name())) {
                // Create and insert new variable
                symbol_info* temp = new symbol_info($1->get_name(), current_type);
                table->insert(temp);
            }
			else {
				errorlog << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
				total_error++;
            }
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
			outlog << $1->get_name() << "[" << $3->get_name() << "]" << endl << endl;
			$$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");

            // Check if array already declared in current scope
            if(!variable_in_current_scope($1->get_name())) {
                // Create and insert new array
                int size = stoi($3->get_name());
                symbol_info* temp = new symbol_info($1->get_name(), current_type, size);
                table->insert(temp);
            }
			else {
				errorlog << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
				total_error++;
            }
 		  }
 		  ;


statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;

statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");

	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;

			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;

			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl;
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");

			symbol_info* temp = new symbol_info($3->get_name(), "ID");
			symbol_info* found = table->lookup(temp);
			delete temp;
			if(!found){
				errorlog << "At line no: " << lines << " Undeclared variable " << $3->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Undeclared variable " << $3->get_name() << endl << endl;
				total_error++;
			}

	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;

			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
			current_type = $2->get_type();
	  }
	  ;

expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;

				$$ = new symbol_info(";","expr_stmt");
	        }
			| expression SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;

				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        }
			;

variable : ID
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;


		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* found = table->lookup(temp);
		delete temp;

		if(!found){
			errorlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			total_error++;
			$$ = new symbol_info($1->get_name(),"dummy_varbl");
			$$->set_undefined(true);
		}

		else{
			$$ = new symbol_info($1->get_name(),"varbl");
			$$->set_type(found->get_type());
		}

		if(found != NULL && found->get_is_array()){
			// if use !found && found->get_is_array() then it will not be able to access the array elements in the next line

			errorlog << "At line no: " << lines << " Variable is of array type : " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Variable is of array type : " << $1->get_name() << endl << endl;
			total_error++;
		}

	 }
	 | ID LTHIRD expression RTHIRD
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* found = table->lookup(temp);
		delete temp;

		$$->set_type(found->get_type());
		$$->set_is_array(found->get_is_array());

		if (!found) {
			errorlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			total_error++;
		}
		else if(!found->get_is_array()){

			errorlog << "At line no: " << lines << " Variable is not of array type: " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Variable is not of array type: " << $1->get_name() << endl << endl;
			total_error++;
		}
		else if($3->get_type() != "int"){
			errorlog << "At line no: " << lines << " Array index is not of integer type: " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Array index is not of integer type: " << $1->get_name() << endl << endl;
			total_error++;
		}

	}
	;

expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"expr");
			$$->set_type($1->get_type());
	   }
	   | variable ASSIGNOP logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;
			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");

			if(!variable_in_current_scope($3->get_name())){
				if($3->get_assign_op()){} //without this at line no : 56 give multiple error

				else if($3->get_is_function()){
					if($1->get_type() != $3->get_type()){
						errorlog << "At line no: " << lines << " operation on void type " << endl << endl;
						outlog << "At line no: " << lines << " operation on void type " << endl << endl;
						total_error++;
					}
				}
				else if($1->get_type() != $3->get_type()){
					if($1->get_undefined() == false && $3->get_undefined() == false){
						errorlog << "At line no: " << lines << " Warning: Assignment of " << $3->get_type() << " value into variable of integer type" << endl << endl;
						outlog << "At line no: " << lines << " Warning: Assignment of " << $3->get_type() << " value into variable of integer type" << endl << endl;
						total_error++;
					}
				}
			}
	   }
	   ;

logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"lgc_expr");

			$$->set_type($1->get_type());

			if($1->get_is_function()){
				string function_type = $1->get_type();
				vector<pair<string, string>> parameters = $1->get_parameters();
				$$->set_as_function(function_type, parameters);
			}
			else if($1->get_assign_op()){
				$$->set_assign_op(true);
			}
			else if($1->get_undefined()){
				$$->set_undefined(true);
			}
	     }
		 | rel_expression LOGICOP rel_expression
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");

			if($1->get_type() == "void" || $3->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
				total_error++;
			}
			else{
				$$->set_type("int");
			}
	     }
		 ;

rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"rel_expr");
			$$->set_type($1->get_type());

			if($1->get_is_function()){
				string function_type = $1->get_type();
				vector<pair<string, string>> parameters = $1->get_parameters();
				$$->set_as_function(function_type, parameters);
			}

			else if($1->get_assign_op()){
				$$->set_assign_op(true);
			}

			else if($1->get_undefined()){
				$$->set_undefined(true);
			}


	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");

			if($1->get_type() == "void" || $3->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
				total_error++;
			}
			else{
				$$->set_type("int");
			}

	    }
		;

simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"simp_expr");
			$$->set_type($1->get_type());

			if($1->get_is_function()){
				string function_type = $1->get_type();
				vector<pair<string, string>> parameters = $1->get_parameters();
				$$->set_as_function(function_type, parameters);
			}

			else if($1->get_assign_op()){
				$$->set_assign_op(true);
			}
			else if($1->get_undefined()){
				$$->set_undefined(true);
			}

	      }
		  | simple_expression ADDOP term
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");

			$$->set_assign_op(true);
			if($1->get_type() == "void" || $3->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
			}
			else if($1->get_type() == "float" || $3->get_type() == "float"){
				$$->set_type("float");
			}
			else{
				$$->set_type("int");
			}
	      }
		  ;

term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"term");

			$$->set_type($1->get_type());

			if($1->get_is_function()){
				string function_type = $1->get_type();
				vector<pair<string, string>> parameters = $1->get_parameters();
				$$->set_as_function(function_type, parameters);
			}

			if($1->get_undefined()){
				$$->set_undefined(true);
			}


	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");

			$$->set_assign_op(true);

			if($1->get_type() == "void" || $3->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
				total_error++;
			}
			else{
				if($2->get_name() == "/" && $3->get_name() == "0"){
						errorlog << "At line no: " << lines << " Division by 0" << endl << endl;
						outlog << "At line no: " << lines << " Division by 0" << endl << endl;
						total_error++;
				}
				else if($2->get_name() == "%"){
					if($3->get_name() == "0"){
						errorlog << "At line no: " << lines << " Modulus by 0" << endl << endl;
						outlog << "At line no: " << lines << " Modulus by 0" << endl << endl;
						total_error++;
					}
					else if($1->get_type() != "int" || $3->get_type() != "int"){
						errorlog << "At line no: " << lines << " Modulus operator on non integer type" << endl << endl;
						outlog << "At line no: " << lines << " Modulus operator on non integer type" << endl << endl;
						total_error++;
					}
				}
			}

			if($1->get_type() == "float" || $3->get_type() == "float"){
				$$->set_type("float");
			}
			else{
				$$->set_type("int");
			}
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");

			$$->set_assign_op(true);
			if($2->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
				total_error++;
			}
	     }
		 | NOT unary_expression
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;
			$$ = new symbol_info("!"+$2->get_name(),"un_expr");

			if($2->get_type() == "void"){
				errorlog << "At line no: " << lines << " operation on void type" << endl << endl;
				outlog << "At line no: " << lines << " operation on void type" << endl << endl;
				total_error++;
			}

	     }
		 | factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"un_expr");
			$$->set_type($1->get_type());


			if($1->get_is_function()){
				string function_type = $1->get_type();
				vector<pair<string, string>> parameters = $1->get_parameters();
				$$->set_as_function(function_type, parameters);
			}

			if($1->get_undefined()){
				$$->set_undefined(true);
			}
	     }
		 ;

factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_type($1->get_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;
		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* func = table->lookup(temp);
		delete temp;

		if(!func){
			errorlog << "At line no: " << lines << " Undeclared function: " << $1->get_name() << endl << endl;
			outlog << "At line no: " << lines << " Undeclared function: " << $1->get_name() << endl << endl;
			total_error++;
			$$->set_undefined(true);
		}
		else{
			string function_type = func->get_type();
			vector<pair<string, string>> parameters = func->get_parameters();
			$$->set_as_function(function_type, parameters);

			if(func->get_parameters().size() != function_parameter_current.size()){
				errorlog << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " << $1->get_name() << endl << endl;
				outlog << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " << $1->get_name() << endl << endl;
				total_error++;
			}
			else if(func->get_parameters().size() == function_parameter_current.size()){
				int i = 0;
				for(auto parameter : function_parameter_current){
					symbol_info* temp = new symbol_info(parameter.first, "ID");
					symbol_info* var = table->lookup(temp);
					delete temp;

					if(!var){
						if(parameter.second != func->get_parameters()[i].first){
							errorlog << "At line no: " << lines << " argument " << i + 1 << " type mismatch in function call: " << $1->get_name() << endl << endl;
							outlog << "At line no: " << lines << " argument " << i + 1 << " type mismatch in function call: " << $1->get_name() << endl << endl;
							total_error++;
						}
					}
					i++;
				}
			}
		}

		function_parameter_current.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info("("+$2->get_name()+")","fctr");
	}
	| CONST_INT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_type("float");
	}
	| variable INCOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"++","fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"--","fctr");
	}
	;

argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;

					$$ = new symbol_info($1->get_name(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;

					$$ = new symbol_info("","arg_list");
			  }
			  ;

arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				pair<string, string> arg($3->get_name(), $3->get_type());
				function_parameter_current.push_back(arg);

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				pair<string, string> arg($1->get_name(), $1->get_type());
				function_parameter_current.push_back(arg);

				$$ = new symbol_info($1->get_name(),"arg");
		  }
	      ;
%%

int main(int argc, char *argv[])
{
	if(argc != 2)
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}

	yyin = fopen(argv[1], "r");
	outlog.open("22201782_log.txt", ios::trunc);
	errorlog.open("22201782_error.txt", ios::trunc);

	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here

	table = new symbol_table(10);

	yyparse();

	delete table;

	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<total_error<<endl;
	errorlog<<"Total errors: "<<total_error<<endl;

	outlog.close();
	errorlog.close();

	fclose(yyin);

	return 0;
}

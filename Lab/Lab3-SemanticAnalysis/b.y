%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
symbol_table* table;

// You can store the pointer to your symbol table in a global variable
// or you can create an object

string current_type;

vector<pair<string, string>> current_func_params;
variable : ID
      {
		outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"varbl");

		// semantic: check declaration and array usage
		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* found = table->lookup(temp);
		delete temp;
		if(found == NULL){
			yyerror((string("Undeclared variable "+$1->get_name())).c_str());
			$$->set_data_type("int");
		} else {
			if(found->get_is_array()){
				yyerror((string("Array used without index: "+$1->get_name())).c_str());
			}
			$$->set_data_type(found->get_data_type());
		}

 }
 	 | ID LTHIRD expression RTHIRD
 	 {
 		outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
 		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

 		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

 		// semantic: check declaration and that index is integer
 		symbol_info* temp = new symbol_info($1->get_name(), "ID");
 		symbol_info* found = table->lookup(temp);
 		delete temp;
 		if(found == NULL){
 			yyerror((string("Undeclared variable "+$1->get_name())).c_str());
 			$$->set_data_type("int");
 		} else {
 			if(!found->get_is_array()){
 				yyerror((string("Subscripted value is not array: "+$1->get_name())).c_str());
 				$$->set_data_type(found->get_data_type());
 			} else {
 				$$->set_data_type(found->get_data_type());
 			}
 		}

 		// index type check
 		if($3->get_data_type() != "int"){
 			yyerror((string("Array index is not integer for "+$1->get_name())).c_str());
 		}
 	 }
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"program");
	}
	;

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
			// Create and insert function symbol before compound statement
			if(!is_function_declared($2->get_name())) {
				vector<pair<string, string> > params = current_func_params;
				symbol_info* func = new symbol_info($2->get_name(), "ID", $1->get_name());
				func->set_as_function($1->get_name(), params);
				table->insert(func);
			}


		    // The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
           // However, note that the scope of the function and the scope of the compound statement are different.

		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
			outlog << $1->get_name() << " " << $2->get_name() << "(" + $4->get_name() + ")\n" << $7->get_name() << endl << endl;

			$$ = new symbol_info($1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name(), "func_def");

			// Clear function parameters for next function
			current_func_params.clear();
		}
		| type_specifier ID LPAREN RPAREN {
			// Create and insert function symbol before compound statement
			if(!is_function_declared($2->get_name())) {
				vector<pair<string, string> > params;
				symbol_info* func = new symbol_info($2->get_name(), "ID", $1->get_name());
				func->set_as_function($1->get_name(), params);
				table->insert(func);
			}

		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
			outlog << $1->get_name() << " " << $2->get_name() << "()\n" << $6->get_name() << endl << endl;

			$$ = new symbol_info($1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name(), "func_def");
		}
		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");

            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			pair<string, string> param($3->get_name(), $4->get_name());
			current_func_params.push_back(param);
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");

            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			pair<string, string> param($3->get_name(), "");
			current_func_params.push_back(param);
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");

            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			pair<string, string> param($1->get_name(), $2->get_name());
			current_func_params.push_back(param);
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"param_list");

            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			pair<string, string> param($1->get_name(), "");
			current_func_params.push_back(param);
		}
 		;

compound_statement : LCURL {
		// Enter a new scope
		table->enter_scope();

		// If we're in a function definition, add parameters to current scope
		if(!current_func_params.empty()) {
			for(auto param : current_func_params) {
				if(!param.second.empty()) {
					symbol_info* param_symbol = new symbol_info(param.second, "ID", param.first);
					table->insert(param_symbol);
				}
			}
		}
	} statements RCURL
	{
		outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
		outlog << "{\n" + $3->get_name() + "\n}" << endl << endl;

		// Print current scope before exiting
		table->print_current_scope();

		// Exit the current scope
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

		// Print current scope before exiting
		table->print_current_scope();

		// Exit the current scope
		table->exit_scope();

		$$ = new symbol_info("{\n}", "comp_stmnt");
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");

			// Insert necessary information about the variables in the symbol table
			current_type = $1->get_name();

			if(current_type == "void"){
				yyerror("void type variable declaration is not allowed");
			}
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;

			$$ = new symbol_info("int","type");
			current_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;

			$$ = new symbol_info("float","type");
			current_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;

			$$ = new symbol_info("void","type");
			current_type = "void";
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
 		  	outlog << $1->get_name() + "," << $3->get_name() << endl << endl;
			$$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");

            // check if variable already declared in current scope
            if(variable_in_current_scope($3->get_name())) {

                $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");
            } else {
                // Create and insert new variable
                symbol_info* new_var = new symbol_info($3->get_name(), "ID", current_type);
                table->insert(new_var);
                $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");
            }
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
 		  	outlog << $1->get_name() + "," << $3->get_name() << "[" << $5->get_name() << "]" << endl << endl;
			$$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");

            // Check if array already declared in current scope
            if(variable_in_current_scope($3->get_name())) {
                // Silently ignore multiple declarations
                $$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");
            } else {
                // Create and insert new array
                int size = stoi($5->get_name());
                symbol_info* new_array = new symbol_info($3->get_name(), "ID", current_type, size);
                table->insert(new_array);
                $$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");
            }
 		  }
 		  |ID
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
			outlog << $1->get_name() << endl << endl;
			$$ = new symbol_info($1->get_name(), "decl_list");

            // Check if variable already declared in current scope
            if(variable_in_current_scope($1->get_name())) {
                // Silently ignore multiple declarations
                $$ = new symbol_info($1->get_name(), "decl_list");
            } else {
                // Create and insert new variable
                symbol_info* new_var = new symbol_info($1->get_name(), "ID", current_type);
                table->insert(new_var);
                $$ = new symbol_info($1->get_name(), "decl_list");
            }
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
			outlog << $1->get_name() << "[" << $3->get_name() << "]" << endl << endl;
			$$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");

            // Check if array already declared in current scope
            if(variable_in_current_scope($1->get_name())) {
                // Silently ignore multiple declarations
                $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");
            } else {
                // Create and insert new array
                int size = stoi($3->get_name());
                symbol_info* new_array = new symbol_info($1->get_name(), "ID", current_type, size);
                table->insert(new_array);
                $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");
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
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;

			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
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

		$$ = new symbol_info($1->get_name(),"varbl");

	 }
	 | ID LTHIRD expression RTHIRD
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
	 }
	 | ID
	  {
		outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		outlog<<"At line no: "<<lines<<" "<<s<<endl<<endl;
		if(errfile.is_open()){
			errfile<<"At line no: "<<lines<<" "<<s<<endl<<endl;
		}
		symbol_info* found = table->lookup(temp);
		delete temp;
		if(found == NULL){
			yyerror((string("Undeclared variable "+$1->get_name())).c_str());
			$$->set_data_type("int");
		} else {
			if(found->get_is_array()){
				yyerror((string("Array used without index: "+$1->get_name())).c_str());
			}
			$$->set_data_type(found->get_data_type());
		}
	 }
	 | ID LTHIRD expression RTHIRD
	 {
 		outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
 		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

 		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

		// semantic: check declaration and that index is integer
		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* found = table->lookup(temp);
		delete temp;
		if(found == NULL){
			yyerror((string("Undeclared variable "+$1->get_name())).c_str());
			$$->set_data_type("int");
		} else {
			if(!found->get_is_array()){
				yyerror((string("Subscripted value is not array: "+$1->get_name())).c_str());
				$$->set_data_type(found->get_data_type());
			} else {
				$$->set_data_type(found->get_data_type());
			}
		}

		// index type check
		if($3->get_data_type() != "int"){
			yyerror((string("Array index is not integer for "+$1->get_name())).c_str());
		}
 	 }
	 ;

expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"expr");
	   }
	   | variable ASSIGNOP logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");

		// semantic: type checking for assignment
		string lhs_type = $1->get_data_type();
		string rhs_type = $3->get_data_type();
		if(lhs_type == "" ) lhs_type = "int";
		if(rhs_type == "" ) rhs_type = "int";
		if(lhs_type == "void" || rhs_type == "void"){
			yyerror("Void type cannot be used in assignment");
		}
		if(lhs_type == "int" && rhs_type == "float"){
			// warning: float assigned to int
			yyerror("Possible loss of precision: assigning float to int");
		}
		// set resulting expr type as lhs type
		$$->set_data_type(lhs_type);
	   }
	   ;

logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"lgc_expr");
	     }
		 | rel_expression LOGICOP rel_expression
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
			// logical operations yield integer (0/1)
			$$->set_data_type("int");
	     }
		 ;

rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"rel_expr");
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
			// relational operations produce integer (true/false)
			$$->set_data_type("int");
	    }
		;

simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"simp_expr");
		$$->set_data_type($1->get_data_type());

	      }
		  | simple_expression ADDOP term
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
		// type propagation for ADD/SUB
		string t1 = $1->get_data_type();
		string t2 = $3->get_data_type();
		if(t1 == "float" || t2 == "float") $$->set_data_type("float");
		else $$->set_data_type("int");
	      }
		  ;

term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"term");
		$$->set_data_type($1->get_data_type());

	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");

		string op = $2->get_name();
		string left = $1->get_data_type();
		string right = $3->get_data_type();
		if(left == "" ) left = "int";
		if(right == "" ) right = "int";
		// modulus requires integer operands
		if(op == "%"){
			if(left != "int" || right != "int"){
				yyerror("Operands of modulus must be integers");
			}
		}
		// division/modulus second operand should not be 0 when constant
		if((op == "/" || op == "%") && $3->get_name() != ""){
			if($3->get_name() == "0" || $3->get_name() == "0.0"){
				yyerror("Division/modulus by zero");
			}
		}
		// type propagation: if either float -> float else int
		if(left == "float" || right == "float") $$->set_data_type("float");
		else $$->set_data_type("int");

	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
		$$->set_data_type($2->get_data_type());
	     }
		 | NOT unary_expression
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;

		$$ = new symbol_info("!"+$2->get_name(),"un_expr");
		$$->set_data_type("int");
	     }
		 | factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"un_expr");
		$$->set_data_type($1->get_data_type());
	     }
		 ;

factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type($1->get_data_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

		// semantic: function call checks
		symbol_info* temp = new symbol_info($1->get_name(), "ID");
		symbol_info* found = table->lookup(temp);
		delete temp;
		if(found == NULL){
			yyerror((string("Undeclared function "+$1->get_name())).c_str());
			$$->set_data_type("int");
		} else {
			if(!found->get_is_function()){
				yyerror((string($1->get_name()+" is not a function")).c_str());
				$$->set_data_type(found->get_data_type());
			} else {
				// check parameter count
				vector<pair<string,string>> params = found->get_parameters();
				if(params.size() != current_call_arg_types.size()){
					yyerror((string("Function call parameter count mismatch for "+$1->get_name())).c_str());
				} else {
					for(size_t i=0;i<params.size() && i<current_call_arg_types.size();i++){
						string expected = params[i].first;
						string actual = current_call_arg_types[i];
						if(expected != "" && actual != "" && expected != actual){
							yyerror((string("Function call argument type mismatch for " + $1->get_name())).c_str());
						}
					}
				}
				// set return type
				$$->set_data_type(found->get_return_type());
				// void function used in expression?
				if(found->get_return_type() == "void"){
					yyerror((string("Void function used in expression: "+$1->get_name())).c_str());
				}
			}
		}

		// clear current call arg types for next call
		current_call_arg_types.clear();
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
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("float");
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

				// no arguments: ensure current call arg types is empty
				current_call_arg_types.clear();

				$$ = new symbol_info("","arg_list");
			  }
			  ;

arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
				// push argument type
				current_call_arg_types.push_back($3->get_data_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"arg");
			current_call_arg_types.push_back($1->get_data_type());
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

	outlog.close();

	fclose(yyin);

	return 0;
}

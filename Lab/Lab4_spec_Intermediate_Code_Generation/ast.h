#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

// Helper to generate new temporary variables
static string new_temp(int& temp_count) {
    return "t" + to_string(temp_count++);
}

// Helper to generate new labels
static string new_label(int& label_count) {
    return "L" + to_string(label_count++);
}

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string get_name() const { return name; }

    ExprNode* get_index() const { return index; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        // If it's a simple variable (R-value context)
        if (!index) {
            string t = new_temp(temp_count);
            outcode << t << " = " << name << endl;
            return t;
        } else {
            // Array access a[i]
            string idx_temp = index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            string val_temp = new_temp(temp_count);
            outcode << val_temp << " = " << name << "[" << idx_temp << "]" << endl;
            return val_temp;
        }
    }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Return the constant value directly or load into temp
        string t = new_temp(temp_count);
        outcode << t << " = " << value << endl;
        return t;
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string t_left = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string t_right = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string t_result = new_temp(temp_count);
        
        outcode << t_result << " = " << t_left << " " << op << " " << t_right << endl;
        return t_result;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string t_expr = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string t_result = new_temp(temp_count);
        
        // Handle logic NOT (!) vs bitwise/arithmetic
        if(op == "!") {
             outcode << t_result << " = ! " << t_expr << endl;
        } else {
             outcode << t_result << " = " << op << t_expr << endl;
        }
        return t_result;
    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string t_rhs = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // Check if LHS is array or simple var
        if (lhs->has_index()) {
             string t_idx = lhs->get_index()->generate_code(outcode, symbol_to_temp, temp_count, label_count);
             outcode << lhs->get_name() << "[" << t_idx << "] = " << t_rhs << endl;
        } else {
             outcode << lhs->get_name() << " = " << t_rhs << endl;
        }
        
        return t_rhs; // Assignments return the value
    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {
            return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto stmt : statements) {
            stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        string t_cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        string label_else = new_label(label_count);
        string label_exit = new_label(label_count);
        
        // If condition is false, jump to else (or exit if no else)
        outcode << "if " << t_cond << " == 0 goto " << (else_block ? label_else : label_exit) << endl;
        
        // Then block
        then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << label_exit << endl;
        
        // Else block
        if (else_block) {
            outcode << label_else << ":" << endl;
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        
        outcode << label_exit << ":" << endl;
        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string label_start = new_label(label_count);
        string label_exit = new_label(label_count);
        
        outcode << label_start << ":" << endl;
        
        string t_cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << t_cond << " == 0 goto " << label_exit << endl;
        
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << label_start << endl;
        
        outcode << label_exit << ":" << endl;
        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        if(init) init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        string label_start = new_label(label_count);
        string label_exit = new_label(label_count);
        
        outcode << label_start << ":" << endl;
        
        if(condition) {
            string t_cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "if " << t_cond << " == 0 goto " << label_exit << endl;
        }
        
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        if(update) update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        outcode << "goto " << label_start << endl;
        outcode << label_exit << ":" << endl;
        
        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string t_expr = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "return " << t_expr << endl;
        return "";
    }
};

// Declaration node

class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for(auto v : vars) {
            outcode << "// Declaration: " << type << " " << v.first;
            if(v.second > 0) {
                outcode << "[" << v.second << "]";
            }
            outcode << endl;
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        outcode << endl << "// Function: " << return_type << " " << name << "(";
        for(size_t i=0; i<params.size(); ++i) {
            outcode << params[i].first << " " << params[i].second;
            if(i < params.size()-1) outcode << ", ";
        }
        outcode << ")" << endl;
        
        // Label for function entry could be added here if needed, 
        // e.g., outcode << name << ":" << endl;
        // But code1.txt format suggests implicit entry via source order for this assignment.
        
        if(body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        
        vector<string> arg_temps;
        // Evaluate arguments first
        for(auto arg : arguments) {
            arg_temps.push_back(arg->generate_code(outcode, symbol_to_temp, temp_count, label_count));
        }
        
        // Push parameters
        for(auto t : arg_temps) {
            outcode << "param " << t << endl;
        }
        
        string t_res = new_temp(temp_count);
        outcode << t_res << " = call " << func_name << ", " << arguments.size() << endl;
        
        return t_res;
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for(auto unit : units) {
            unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

#endif // AST_H
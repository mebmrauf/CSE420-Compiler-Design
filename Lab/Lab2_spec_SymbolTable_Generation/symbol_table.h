#include "scope_table.h"
#include <fstream>
#include <iostream>

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count) {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;
        current_scope = new scope_table(bucket_count, current_scope_id, nullptr);
    }

    void initialize_scope_1(vector<pair<string,string>>& params) {
        for(auto param : params) {
            symbol_info* param_symbol = new symbol_info(param.second, "ID");
            param_symbol->set_data_type(param.first);
            current_scope->insert_in_scope(param_symbol);
        }
    }

    void enter_scope() {
        current_scope_id++;
        scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;
    }


    void exit_scope() {
        if(current_scope != nullptr) {
            scope_table* parent = current_scope->get_parent_scope();
            delete current_scope;
            current_scope = parent;
        }
    }

    bool insert(symbol_info* symbol) {
        return current_scope->insert_in_scope(symbol);
    }

    int get_current_id() {
        return current_scope ? current_scope->get_unique_id() : 0;
    }

    symbol_info* lookup(symbol_info* symbol) {
        scope_table* temp = current_scope;
        while(temp != nullptr) {
            symbol_info* result = temp->lookup_in_scope(symbol);
            if(result != nullptr) {
                return result;
            }
            temp = temp->get_parent_scope();
        }
        return nullptr;
    }


    void print_current_scope(std::ofstream& outlog) {
        if(current_scope != nullptr) {
            current_scope->print_scope_table(outlog);
        }
    }


    void print_all_scopes(std::ofstream& outlog) {
        outlog << "################################" << std::endl << std::endl;
        scope_table* temp = current_scope;
        while(temp != nullptr) {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog << "################################" << std::endl << std::endl;
    }

    // Destructor
    ~symbol_table() {
        while(current_scope != nullptr) {
            exit_scope();
        }
    }

    scope_table* get_parent_scope() {
        if(current_scope) {
            return current_scope->get_parent_scope();
        }
        return nullptr;
    }

    scope_table* get_current_scope() {
        return current_scope;
    }
};

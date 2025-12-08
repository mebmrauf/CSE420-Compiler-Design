#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        int hash_val = 7; 
        for(char c : name) {
            hash_val = (hash_val + c) % bucket_count;
        }
        return hash_val;
    }

public:
    scope_table(int bucket_count, int unique_id, scope_table* parent_scope) {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table* get_parent_scope() {
        return parent_scope;
    }

    int get_unique_id() {
        return unique_id;
    }

    symbol_info* lookup_in_scope(symbol_info* symbol) {
        int index = hash_function(symbol->get_name());
        for(symbol_info* s : table[index]) {
            if(s->get_name() == symbol->get_name()) {
                return s;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info* symbol) {
        if(lookup_in_scope(symbol) != nullptr) {
            return false;  // Already exists
        }

        int index = hash_function(symbol->get_name());
        table[index].push_back(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info* symbol) {
        int index = hash_function(symbol->get_name());
        for(auto it = table[index].begin(); it != table[index].end(); ++it) {
            if((*it)->get_name() == symbol->get_name()) {
                table[index].erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream& outlog) {
        outlog << "ScopeTable # " << unique_id << endl;
        for(int i = 0; i < bucket_count; i++) {
            if(!table[i].empty()) {
                outlog << i << " --> " << endl;
                for(symbol_info* symbol : table[i]) {
                    outlog << "< " << symbol->get_name() << " : " << symbol->get_type() << " >" << endl;
                    if(symbol->is_array()) {
                        outlog << "Array" << endl;
                        outlog << "Type: " << symbol->get_data_type() << endl;
                        outlog << "Size: " << symbol->get_array_size();
                    } else if(symbol->is_function()) {
                        outlog << "Function Definition" << endl;
                        outlog << "Return Type: " << symbol->get_data_type() << endl;
                        outlog << "Number of Parameters: " << symbol->get_parameters().size() << endl;
                        outlog << "Parameter Details: ";
                        auto params = symbol->get_parameters();
                        for(int i = 0; i < params.size(); i++) {
                            outlog << params[i].first << " " << params[i].second;
                            if(i < params.size() - 1) outlog << ", ";
                        }
                    } else {
                        outlog << "Variable" << endl;
                        outlog << "Type: " << symbol->get_data_type();
                    }
                    outlog << endl << endl;
                }
            }
        }
    }

    ~scope_table() {
        for(auto& bucket : table) {
            for(auto symbol : bucket) {
                delete symbol;
            }
            bucket.clear();
        }
        table.clear();
    }
};

#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    // Additional attributes
    enum SymbolType { VARIABLE, ARRAY, FUNCTION };
    SymbolType symbol_type;
    string data_type;
    int array_size; 
    vector<pair<string, string>> parameters; 

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    // Write necessary attributes to store the parameters of a function
    // Write necessary attributes to store the array size if the symbol is an array

public:
    symbol_info(string name, string type) {
        this->name = name;
        this->type = type;
        this->symbol_type = VARIABLE;
        this->array_size = 0;
    }    

    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes
    void set_as_array(int size) {
        symbol_type = ARRAY;
        array_size = size;
    }

    void set_as_function(string return_type, vector<pair<string, string>> params) {
        symbol_type = FUNCTION;
        data_type = return_type;
        parameters = params;
    }

    void set_data_type(string type) {
        data_type = type;
        if(symbol_type != ARRAY && symbol_type != FUNCTION) {
            symbol_type = VARIABLE;
        }
    }

    bool is_array() { return symbol_type == ARRAY; }
    bool is_function() { return symbol_type == FUNCTION; }
    int get_array_size() { return array_size; }
    string get_data_type() { return data_type; }
    vector<pair<string, string>> get_parameters() { return parameters; }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};

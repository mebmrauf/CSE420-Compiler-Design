#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;  
    string type;

    string symbol_type = "NAN"; // variable, array, or function, initially none
    string return_type;
    vector<string> params;     // function parameters
    int size;   // array size

public:

    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
    }

    string getname()
    {
        return name;
    }

    string get_type()
    {
        return type;
    }

    string get_symbol_type()
    {
        return symbol_type;
    }

    string get_return_type()
    {
        return return_type;
    }

    int get_size()
    {
        return size;
    }

    vector<string> get_params()
    {
        return params;
    }

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }

    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }

    void set_size(int size)
    {
        this->size = size;
    }

    void add_param_type(string param)
    {
        params.push_back(param);
    }
};

#endif
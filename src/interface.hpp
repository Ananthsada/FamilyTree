#pragma once

class Interface
{
public:
    Interface& instance();
private:
    Interface();
    ~Interface();
};
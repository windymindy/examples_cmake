#include <iostream>

#include <library_1.hpp>
#include <library_2.hpp>
#include "library_3.hpp"

int main()
{
    std::cout << library_1() << std::endl;
    std::cout << library_2() << std::endl;
    std::cout << library_3() << std::endl;
    return 0;
}

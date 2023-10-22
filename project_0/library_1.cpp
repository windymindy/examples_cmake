#include "library_1.hpp"

int library_1()
{
#ifdef NDEBUG
    return 42;
#else
    return -42;
#endif
}

#include "library_2.hpp"

int library_2()
{
#ifdef NDEBUG
    return 24;
#else
    return -24;
#endif
}

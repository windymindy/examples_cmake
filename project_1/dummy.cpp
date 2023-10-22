#error

#if defined(_MSC_VER)
#if defined(dummy_exporting)
#define dummy_export __declspec(dllexport)
#else
#define dummy_export
#endif
#else
#define dummy_export
#endif

int dummy_export dummy()
{
    return 0;
}

#pragma once

#if defined(_MSC_VER)
#if defined(library_2_exporting)
#define library_2_export __declspec(dllexport)
#else
#define library_2_export __declspec(dllimport)
#endif
#else
#define library_2_export
#endif

int library_2_export library_2();

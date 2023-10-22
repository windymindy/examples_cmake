cmake_minimum_required(VERSION 3.24)

project(project_3 VERSION 1.2.3)

include(../cmake/settings.cmake)

find_package(project_2 1.2.3 REQUIRED)

add_executable(executable_1)
target_sources(
    executable_1 PRIVATE
    executable_1.cpp
)
target_link_libraries(executable_1 PRIVATE library_3)

install(TARGETS executable_1)
install(
    IMPORTED_RUNTIME_ARTIFACTS project_1_library_2
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_BINDIR}"
)

cmake_minimum_required(VERSION 3.24)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(project_1 VERSION 1.2.3)

include(CMakePackageConfigHelpers)
include(../cmake/settings.cmake)
include(../cmake/build_types.cmake)

set(project_0_location ../installed/project_0 CACHE STRING "")
find_path(
    project_0_location_
    .
    PATHS "${project_0_location}"
    NO_DEFAULT_PATH
    REQUIRED
)
find_path(
    project_0_location_headers
    .
    PATHS "${project_0_location_}/${CMAKE_INSTALL_INCLUDEDIR}"
    NO_DEFAULT_PATH
    REQUIRED
)
find_path(
    project_0_location_libraries
    .
    PATHS "${project_0_location_}/${CMAKE_INSTALL_LIBDIR}"
    NO_DEFAULT_PATH
    REQUIRED
)

set(save_ "${CMAKE_FIND_LIBRARY_SUFFIXES}")

# in practice there would be many libraries.
# the way is to compose a convinience function that
# checks suffixes for different build types,
set(CMAKE_FIND_LIBRARY_PREFIXES ";${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(CMAKE_FIND_LIBRARY_SUFFIXES "${CMAKE_STATIC_LIBRARY_SUFFIX}")
find_library(
    library_1_1
    NAMES library_1
    PATHS "${project_0_location_libraries}"
    NO_DEFAULT_PATH
    REQUIRED
)
find_library(
    library_1_2
    NAMES library_1${CMAKE_DEBUG_POSTFIX}
    PATHS "${project_0_location_libraries}"
    NO_DEFAULT_PATH
    REQUIRED
)

if(MSVC)
    set(CMAKE_FIND_LIBRARY_SUFFIXES "${CMAKE_STATIC_LIBRARY_SUFFIX}")
    find_library(
        library_2_1
        NAMES library_2
        PATHS "${project_0_location_libraries}"
        NO_DEFAULT_PATH
        REQUIRED
    )
    find_library(
        library_2_2
        NAMES library_2${CMAKE_DEBUG_POSTFIX}
        PATHS "${project_0_location_libraries}"
        NO_DEFAULT_PATH
        REQUIRED
    )
endif()
set(CMAKE_FIND_LIBRARY_SUFFIXES "${CMAKE_SHARED_LIBRARY_SUFFIX}")
find_library(
    library_2_3
    NAMES library_2
    PATHS "${project_0_location_libraries}"
    NO_DEFAULT_PATH
    REQUIRED
)
find_library(
    library_2_4
    NAMES library_2${CMAKE_DEBUG_POSTFIX}
    PATHS "${project_0_location_libraries}"
    NO_DEFAULT_PATH
    REQUIRED
)

set(CMAKE_FIND_LIBRARY_SUFFIXES "${save_}")

add_library(${PROJECT_NAME}_library INTERFACE)

file(GLOB_RECURSE headers_ "${project_0_location_headers}/*.hpp")
target_sources(
    ${PROJECT_NAME}_library INTERFACE FILE_SET HEADERS
    BASE_DIRS "${project_0_location_headers}"
    FILES "${headers_}"
)
#[[
target_include_directories(
    ${PROJECT_NAME}_library INTERFACE
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
]]

# excluding prevents artifacts from being overwritten by an accidental build command.
add_library(${PROJECT_NAME}_library_1 STATIC EXCLUDE_FROM_ALL)
target_sources(${PROJECT_NAME}_library_1 PRIVATE dummy.cpp)
# point the target to the existing library using
# <CONFIG>_POSTFIX, LIBRARY_OUTPUT_DIRECTORY_<CONFIG>, ARCHIVE_OUTPUT_DIRECTORY_<CONFIG>, RUNTIME_OUTPUT_DIRECTORY_<CONFIG>, ...
# use the result of find_library.
# create a reusable function for the use case.
set_target_properties(
    ${PROJECT_NAME}_library_1
    PROPERTIES
        OUTPUT_NAME library_1
        ARCHIVE_OUTPUT_DIRECTORY "${project_0_location_libraries}"
)
foreach(build_type IN LISTS build_types)
    set_target_properties(
        ${PROJECT_NAME}_library_1
        PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${build_type} "${project_0_location_libraries}"
    )
endforeach()

add_library(${PROJECT_NAME}_library_2 SHARED EXCLUDE_FROM_ALL)
target_sources(${PROJECT_NAME}_library_2 PRIVATE dummy.cpp)
set_target_properties(
    ${PROJECT_NAME}_library_2
    PROPERTIES
        OUTPUT_NAME library_2
        LIBRARY_OUTPUT_DIRECTORY "${project_0_location_libraries}"
        ARCHIVE_OUTPUT_DIRECTORY "${project_0_location_libraries}"
        RUNTIME_OUTPUT_DIRECTORY "${project_0_location_libraries}"
)
foreach(build_type IN LISTS build_types)
    set_target_properties(
        ${PROJECT_NAME}_library_2
        PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY_${build_type} "${project_0_location_libraries}"
            ARCHIVE_OUTPUT_DIRECTORY_${build_type} "${project_0_location_libraries}"
            RUNTIME_OUTPUT_DIRECTORY_${build_type} "${project_0_location_libraries}"
        )
endforeach()

target_link_libraries(
    ${PROJECT_NAME}_library INTERFACE
    ${PROJECT_NAME}_library_1
    ${PROJECT_NAME}_library_2
)

install(
    TARGETS ${PROJECT_NAME}_library
    EXPORT ${PROJECT_NAME}_import
    FILE_SET HEADERS
)

install(
    TARGETS ${PROJECT_NAME}_library_1
    EXPORT ${PROJECT_NAME}_import
)

install(
    TARGETS ${PROJECT_NAME}_library_2
    EXPORT ${PROJECT_NAME}_import
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBRARY_RUNTIME_DESTINATION}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(
    EXPORT ${PROJECT_NAME}_import
    DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)

file(
    WRITE "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}_package_input.cmake"
[[
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@_import.cmake")
check_required_components(@PROJECT_NAME@)
]]
)

configure_package_config_file(
    "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}_package_input.cmake"
    package/${PROJECT_NAME}-config.cmake
    INSTALL_DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)

write_basic_package_version_file(
    package/${PROJECT_NAME}-config-version.cmake
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)

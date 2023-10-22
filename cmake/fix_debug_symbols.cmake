# https://gitlab.kitware.com/cmake/cmake/issues/16932
# https://gitlab.kitware.com/cmake/cmake/issues/16935
# https://gitlab.kitware.com/cmake/cmake/issues/18393
# https://gitlab.kitware.com/cmake/cmake/issues/25244
# Qt qttargethelpers.cmake
# forexample/package-example foo/cmakelists.txt

# OBJECT_LIBRARY not implemented

if(NOT MSVC)
    return()
endif()

# by default, symbols are not copied to the output directory, even though generated.
# the buld system is supposed to set up all the properties, but those are just left out.
# simply setting the name properties is sufficient.

function(_fix_debug_symbols_check_symbols target)

    get_target_property(target_type ${target} TYPE)
    if(NOT target_type STREQUAL "STATIC_LIBRARY")
        return()
    endif()

    # some configurations are already inplace
    get_target_property(target_has_symbols_1 ${target} COMPILE_PDB_NAME)
    get_target_property(target_has_symbols_2 ${target} COMPILE_PDB_NAME_DEBUG)
    get_target_property(target_has_symbols_3 ${target} COMPILE_PDB_OUTPUT_DIRECTORY)
    get_target_property(target_has_symbols_4 ${target} COMPILE_PDB_OUTPUT_DIRECTORY_DEBUG)
    if(target_has_symbols_1 OR target_has_symbols_2 OR target_has_symbols_3 OR target_has_symbols_4)
        return()
    endif()

    function(create_build_types result)

        set(build_types "")

        get_cmake_property(is_multiple GENERATOR_IS_MULTI_CONFIG)
        if(is_multiple)
            if(CMAKE_CONFIGURATION_TYPES)
                foreach(build_type IN LISTS CMAKE_CONFIGURATION_TYPES)
                    string(TOUPPER "${build_type}" build_type)
                    list(APPEND build_types "${build_type}")
                endforeach()
            endif()
        else()
            if(CMAKE_BUILD_TYPE)
                string(TOUPPER "${CMAKE_BUILD_TYPE}" build_type)
                list(APPEND build_types "${build_type}")
            endif()
        endif()

        set(${result} ${build_types} PARENT_SCOPE)

    endfunction()

    function(create_symbols_output_name target build_type result)

        get_target_property(output_name ${target} OUTPUT_NAME_${build_type})
        if(output_name)
            set(${result} "${output_name}" PARENT_SCOPE)
            return()
        endif()

        get_target_property(output_name ${target} OUTPUT_NAME)
        if(NOT output_name)
            set(output_name "${target}")
        endif()

        get_target_property(output_name_suffix ${target} ${build_type}_POSTFIX)
        if(NOT output_name_suffix)
            set(output_name_suffix "")
        endif()

        set(${result} "${output_name}${output_name_suffix}" PARENT_SCOPE)

    endfunction()

    function(create_symbols_output_name_ target result)

        get_target_property(output_name ${target} OUTPUT_NAME)
        if(NOT output_name)
            set(output_name "${target}")
        endif()

        set(${result} "${output_name}" PARENT_SCOPE)

    endfunction()

    # check the build type specific settings and come up with what the symbols output name should be
    create_build_types(build_types)
    foreach(build_type IN LISTS build_types)
        create_symbols_output_name(${target} ${build_type} symbols_output_name)
        set_target_properties(${target} PROPERTIES "COMPILE_PDB_NAME_${build_type}" "${symbols_output_name}")
        # use 3.25 block for variable scope
        unset(symbols_output_name)
    endforeach()

    create_symbols_output_name_(${target} symbols_output_name)
    set_target_properties(${target} PROPERTIES COMPILE_PDB_NAME "${symbols_output_name}")

endfunction()

# to install the symbols seamlessly along with the target and only if it is installed,
# some means of finding out whether a target is installed or not are required.
# the alternative would be hooking install(TARGETS ...) or
# explicitly calling some install_symbols(target) function.
# cmake_file_api is the way to go.
# that would also enable using higher level install(FILES ...), instead of FILE(INSTALL ...).
# this just tries and guesses by reflecting upon the cmake_install.cmake (referenced as CMAKE_CURRENT_LIST_FILE in the script).
# should also consider writing into the install_manifest.txt.

function(_fix_debug_symbols_install_symbols target)

    get_target_property(target_type ${target} TYPE)
    if(NOT target_type STREQUAL "EXECUTABLE" AND NOT target_type STREQUAL "SHARED_LIBRARY" AND NOT target_type STREQUAL "STATIC_LIBRARY")
        return()
    endif()

    get_target_property(target_build_directory ${target} BINARY_DIR)

    if(target_type STREQUAL "EXECUTABLE" OR target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "MODULE_LIBRARY")

        if(target_type STREQUAL "EXECUTABLE")
            set(symbols_destination "${CMAKE_INSTALL_BINDIR}")
            if(NOT symbols_destination)
                set(symbols_destination bin)
            endif()
        else()
            set(symbols_destination "${CMAKE_INSTALL_LIBRARY_RUNTIME_DESTINATION}")
            if(NOT symbols_destination)
                set(symbols_destination "${CMAKE_INSTALL_LIBDIR}")
            endif()
            if(NOT symbols_destination)
                set(symbols_destination lib)
            endif()
        endif()

        set(
            script
            [[
                if(NOT _fix_debug_symbols_install_script)
                    file(READ "${CMAKE_CURRENT_LIST_FILE}" _fix_debug_symbols_install_script)
                endif()
                string(FIND "${_fix_debug_symbols_install_script}" "$<TARGET_FILE_NAME:@target@>\"" _fix_debug_symbols_target_installed)
                if(NOT _fix_debug_symbols_target_installed EQUAL -1)
                    file(
                        INSTALL
                        TYPE FILE
                        FILES "$<TARGET_PDB_FILE:@target@>"
                        DESTINATION "${CMAKE_INSTALL_PREFIX}/@symbols_destination@"
                        OPTIONAL
                    )
                endif()
            ]]
        )
        string(REPLACE "                " "" script ${script})
        string(CONFIGURE ${script} script @ONLY)
        install(CODE ${script})

    elseif(target_type STREQUAL "STATIC_LIBRARY")

        get_target_property(target_has_symbols ${target} COMPILE_PDB_NAME)
        if(NOT target_has_symbols)
            return()
        endif()

        set(symbols_destination "${CMAKE_INSTALL_LIBDIR}")
        if(NOT symbols_destination)
            set(symbols_destination lib)
        endif()

        set(
            script
            [[
                if(NOT _fix_debug_symbols_install_script)
                    file(READ "${CMAKE_CURRENT_LIST_FILE}" _fix_debug_symbols_install_script)
                endif()
                string(FIND "${_fix_debug_symbols_install_script}" "$<TARGET_FILE_NAME:@target@>\"" _fix_debug_symbols_target_installed)
                if(NOT _fix_debug_symbols_target_installed EQUAL -1)
                    set(_fix_debug_symbols_output_name "$<TARGET_PROPERTY:@target@,COMPILE_PDB_NAME_$<UPPER_CASE:$<CONFIG>>>")
                    $<$<NOT:$<BOOL:$<TARGET_PROPERTY:@target@,COMPILE_PDB_NAME_$<UPPER_CASE:$<CONFIG>>>>>:set(_fix_debug_symbols_output_name "$<TARGET_PROPERTY:@target@,COMPILE_PDB_NAME>")>
                    file(
                        INSTALL
                        TYPE FILE
                        FILES "$<TARGET_FILE_DIR:@target@>/${_fix_debug_symbols_output_name}.pdb"
                        DESTINATION "${CMAKE_INSTALL_PREFIX}/@symbols_destination@"
                        OPTIONAL
                    )
                    unset(_fix_debug_symbols_output_name)
                endif()
            ]]
        )
        string(REPLACE "                " "" script ${script})
        string(CONFIGURE ${script} script @ONLY)
        install(CODE ${script})

    endif()

endfunction()

function(_fix_debug_symbols)

    get_property(targets DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)
    foreach(target IN LISTS targets)
        _fix_debug_symbols_check_symbols(${target})
        _fix_debug_symbols_install_symbols(${target})
    endforeach()

endfunction()

cmake_language(DEFER CALL _fix_debug_symbols)

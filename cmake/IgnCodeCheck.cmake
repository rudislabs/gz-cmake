# Setup the codecheck target, which will run cppcheck and cppplint.
function(ign_setup_target_for_codecheck)

  find_program(CPPCHECK_PATH cppcheck)
  find_program(PYTHON_PATH python)
  find_program(FIND_PATH find)
  
  if(NOT CPPCHECK_PATH)
    message(STATUS "The program [cppcheck] was not found! Skipping codecheck setup")
    return()
  endif()
  
  if(NOT PYTHON_PATH)
    message(STATUS "python not found! Skipping codecheck setup.")
    return()
  endif()
  
  if(NOT FIND_PATH)
    message(STATUS "The program [find] was not found! Skipping codecheck setup.")
    return()
  endif()

  # Base set of cppcheck option
  set (CPPCHECK_BASE -q --inline-suppr -j 4 --language=c++ --std=c++14 --force)
  if (EXISTS "${PROJECT_BINARY_DIR}/cppcheck.suppress")
    set (CPPCHECK_BASE ${CPPCHECK_BASE} --suppressions-list=${PROJECT_BINARY_DIR}/cppcheck.suppress)
  endif()

  # Extra cppcheck option
  set (CPPCHECK_EXTRA --enable=style,performance,portability,information)

  # Rules for cppcheck
  set (CPPCHECK_RULES "-UM_PI --rule-file=${IGNITION_CMAKE_CODECHECK_DIR}/header_guard.rule --rule-file=${IGNITION_CMAKE_CODECHECK_DIR}/namespace_AZ.rule")

  # The find command
  set (CPPCHECK_FIND ${FIND_PATH} ${CPPCHECK_DIRS} -name '*.cc' -o -name '*.hh' -o -name '*.c' -o -name '*.h')

  # Command arguments
  set (CPPCHECK_COMMAND_1 ${CPPCHECK_EXTRA} -I ${CPPCHECK_INCLUDE_DIRS} ${CPPCHECK_RULES} `${CPPCHECK_FIND}`)
  set (CPPCHECK_COMMAND_2 --enable=missingInclude `${CPPCHECK_FIND}`)
  set (CPPLINT_COMMAND python ${IGNITION_CMAKE_CODECHECK_DIR}/cpplint.py --extensions=cc,hh --quiet)

  # xml output folder
  set (CPPCHECK_XMLDIR "${CMAKE_BINARY_DIR}/cppcheck_results")
  execute_process(COMMAND cmake -E remove_directory ${CPPCHECK_XMLDIR})
  execute_process(COMMAND cmake -E make_directory ${CPPCHECK_XMLDIR})

  message(STATUS "Adding codecheck target")

  # Setup the codecheck target
  add_custom_target(codecheck

    # First cppcheck
    COMMAND ${CPPCHECK_PATH} ${CPPCHECK_BASE} ${CPPCHECK_COMMAND_1}

    # Second cppcheck
    COMMAND ${CPPCHECK_PATH} ${CPPCHECK_BASE} ${CPPCHECK_COMMAND_2}

    # cpplint cppcheck
    COMMAND ${CPPLINT_COMMAND} `${CPPCHECK_FIND}`
  )

  # Setup custom commands for xml output
  add_custom_command(OUTPUT ${CPPCHECK_XMLDIR}/cppcheck.xml
    COMMAND ${CPPCHECK_PATH} ${CPPCHECK_BASE} ${CPPCHECK_COMMAND_1}
            --xml --xml-version=2 &> ${CPPCHECK_XMLDIR}/cppcheck.xml)

  add_custom_command(OUTPUT ${CPPCHECK_XMLDIR}/cppcheck-configuration.xml
    COMMAND ${CPPCHECK_PATH} ${CPPCHECK_BASE} ${CPPCHECK_COMMAND_2}
            --xml --xml-version=2 &> ${CPPCHECK_XMLDIR}/cppcheck-configuration.xml)

  add_custom_command(OUTPUT ${CPPCHECK_XMLDIR}/cpplint.xml
    COMMAND ${CPPLINT_COMMAND} --output=junit `${CPPCHECK_FIND}`
            &> ${CPPCHECK_XMLDIR}/cpplint.xml)

  # Setup the codecheck target with xml output that depends on the xml files
  add_custom_target(codecheck_xml
    DEPENDS
      ${CPPCHECK_XMLDIR}/cppcheck.xml
      ${CPPCHECK_XMLDIR}/cppcheck-configuration.xml
      ${CPPCHECK_XMLDIR}/cpplint.xml)

endfunction()

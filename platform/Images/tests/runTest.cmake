SET(ENV{IMAGE_IO_PLUGINS} "${CMAKE_CURRENT_BINARY_DIR}/../plugins/check.plugins")
UNSET(ENV{IMAGE_IO_PLUGINS_VERBOSE})

FUNCTION(COMPARE NAME OUTPUT REFERENCE)

    SET(COMPARISON_OUTPUT ${NAME}-Comparison.output)
    SET(COMPARISON_ERROR ${NAME}-Comparison.error)

    IF ("${REFERENCE}" STREQUAL "Null.output")
        FILE(READ ${OUTPUT} data)
        STRING(LENGTH "${data}" COMPARE_STATUS)
    ELSE()
        IF ("${TEST_COMPARISON}" STREQUAL "file_comparison")
            SET(COMPARISON_COMMAND ${CMAKE_COMMAND} -E compare_files)
        ELSE()
            SET(COMPARISON_COMMAND "${CMAKE_BINARY_DIR}/../../../bin/Compare")
        ENDIF()

        MESSAGE("${TEST_COMPARISON} ${OUTPUT} ${REFERENCE}")
        EXECUTE_PROCESS(COMMAND ${COMPARISON_COMMAND} ${OUTPUT} ${REFERENCE}
                        RESULT_VARIABLE COMPARE_STATUS
                        OUTPUT_FILE ${COMPARISON_OUTPUT}
                        ERROR_FILE ${COMPARISON_ERROR}
        )
    ENDIF()

    MESSAGE("${COMP_STATUS} | ${COMPARE_STATUS}")
    IF ("${COMP_STATUS}" MATCHES "^[0-9]+$" AND
        "${COMPARE_STATUS}" MATCHES "^[0-9]+$")
        MATH(EXPR COMP_STATUS "${COMP_STATUS} | ${COMPARE_STATUS}")
    ELSE()
        SET(COMP_STATUS 1)
    ENDIF()

    IF (${COMP_STATUS} STREQUAL "0")
        FILE(REMOVE ${COMPARISON_OUTPUT} ${COMPARISON_ERROR})
    ENDIF()

    SET(COMP_STATUS ${COMP_STATUS} PARENT_SCOPE)
ENDFUNCTION()

#   Tokenize input parameters with respect to simple shell rules.

SET(TEST_STRING "${TEST_PROGRAM} ${TEST_ARGS}")
SET(TEST_ARGUMENTS)
WHILE (TEST_ARGS)
    STRING(STRIP ${TEST_ARGS} TEST_ARGS)
    STRING(LENGTH ${TEST_ARGS} l)

    IF (NOT l EQUAL 0)
        STRING(SUBSTRING ${TEST_ARGS} 0 1 ESCAPE)
        IF ("${ESCAPE}" STREQUAL "'")
            STRING(REGEX REPLACE "'([^']*)'.*" "\\1" ARG       ${TEST_ARGS})
            STRING(REGEX REPLACE "'[^']*'(.*)" "\\1" TEST_ARGS ${TEST_ARGS})
        ELSEIF ("${ESCAPE}" STREQUAL "\"")
            STRING(REGEX REPLACE "(\"[^\"]*\").*" "\\1" ARG       ${TEST_ARGS})
            STRING(REGEX REPLACE "\"[^\"]*\"(.*)" "\\1" TEST_ARGS ${TEST_ARGS})
        ELSE()
            STRING(REGEX REPLACE "([^ \t]+)[ \t]*.*" "\\1" ARG       ${TEST_ARGS})
            STRING(REGEX REPLACE "[^ \t]+[ \t]*(.*)" "\\1" TEST_ARGS ${TEST_ARGS})
        ENDIF()
        SET(TEST_ARGUMENTS ${TEST_ARGUMENTS} ${ARG})
    ENDIF()
ENDWHILE()

IF ("${TEST_INPUT}" STREQUAL "")
    SET(EXTRA_PARAM)
    MESSAGE("${TEST_PROGRAM} ${TEST_ARGUMENTS}")
ELSE()
    SET(EXTRA_PARAM INPUT_FILE ${TEST_INPUT})
    MESSAGE("${TEST_PROGRAM} ${TEST_ARGUMENTS} <  ${TEST_INPUT}")
ENDIF()

EXECUTE_PROCESS(COMMAND ${TEST_WRAPPER} ${TEST_PROGRAM} ${TEST_ARGUMENTS}
                RESULT_VARIABLE COMP_STATUS
                OUTPUT_FILE     ${TEST_OUTPUT}
                ERROR_FILE      ${TEST_ERROR}
                ${EXTRA_PARAM}
)

STRING(REGEX REPLACE "[ \t]+" ";" TEST_REFERENCE "${TEST_REFERENCE}")
LIST(GET TEST_REFERENCE 0 REFERENCE)
COMPARE(${TEST_PROGRAM} ${TEST_OUTPUT} ${REFERENCE})
LIST(REMOVE_AT TEST_REFERENCE 0 ${TEST_REFERENCE})
FOREACH (reference ${TEST_REFERENCE})
    STRING(REGEX REPLACE "(images|results)/" "" test_file ${reference})
    COMPARE(${TEST_PROGRAM} ${test_file} ${reference})
ENDFOREACH()

IF (${COMP_STATUS} STREQUAL "0")
    MESSAGE(STATUS "Success")
    FILE(REMOVE ${TEST_OUTPUT})
ELSE()
    MESSAGE(STATUS "FAILURE")
ENDIF()

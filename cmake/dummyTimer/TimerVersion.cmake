# This is a basic version file for the Config-mode of find_package().
# It is used by write_basic_package_version_file() as input file for configure_file()
# to create a version-file which can be installed along a config.cmake file.
#
# The created file sets PACKAGE_VERSION_EXACT if the current version string and
# the requested version string are exactly the same and it sets
# PACKAGE_VERSION_COMPATIBLE if the current version is >= requested version,
# but only if the requested major version is the same as the current one.
# The variable CVF_VERSION must be set before calling configure_file().

SET( PACKAGE_VERSION "0.0.331" )

IF ( PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION )
    SET( PACKAGE_VERSION_COMPATIBLE FALSE )
ELSE()

    IF ( "0.0.331^([0-9]+)\\." )
        SET( CVF_VERSION_MAJOR "${CMAKE_MATCH_1}" )
        IF ( NOT CVF_VERSION_MAJOR VERSION_EQUAL 0 )
            STRING( REGEX REPLACE "^0+" "" CVF_VERSION_MAJOR "${CVF_VERSION_MAJOR}" )
        ENDIF()
    ELSE()
        SET( CVF_VERSION_MAJOR "0.0.331" )
    ENDIF()

    IF ( PACKAGE_FIND_VERSION_RANGE )
        # both endpoints of the range must have the expected major version
        MATH( EXPR CVF_VERSION_MAJOR_NEXT "${CVF_VERSION_MAJOR} + 1" )
        IF ( NOT PACKAGE_FIND_VERSION_MIN_MAJOR STREQUAL CVF_VERSION_MAJOR
            OR ( (PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "INCLUDE" AND NOT PACKAGE_FIND_VERSION_MAX_MAJOR STREQUAL CVF_VERSION_MAJOR )
                OR ( PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "EXCLUDE" AND NOT PACKAGE_FIND_VERSION_MAX VERSION_LESS_EQUAL CVF_VERSION_MAJOR_NEXT ) ) )
            SET( PACKAGE_VERSION_COMPATIBLE FALSE )
        ELSEIF ( PACKAGE_FIND_VERSION_MIN_MAJOR STREQUAL CVF_VERSION_MAJOR
                AND ( (PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "INCLUDE" AND PACKAGE_VERSION VERSION_LESS_EQUAL PACKAGE_FIND_VERSION_MAX )
                     OR ( PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "EXCLUDE" AND PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION_MAX ) ) )
            SET( PACKAGE_VERSION_COMPATIBLE TRUE )
        ELSE()
            SET( PACKAGE_VERSION_COMPATIBLE FALSE )
        ENDIF()
    ELSE()
        IF ( PACKAGE_FIND_VERSION_MAJOR STREQUAL CVF_VERSION_MAJOR )
            SET( PACKAGE_VERSION_COMPATIBLE TRUE )
        ELSE()
            SET( PACKAGE_VERSION_COMPATIBLE FALSE )
        ENDIF()

        IF ( PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION )
            SET( PACKAGE_VERSION_EXACT TRUE )
        ENDIF()
    ENDIF()
ENDIF()

# if the installed or the using project don't have CMAKE_SIZEOF_VOID_P set, ignore it:
IF ( "${CMAKE_SIZEOF_VOID_P}" STREQUAL "" OR "8" STREQUAL "" )
    RETURN()
ENDIF()

# check that the installed version has the same 32/64bit-ness as the one which is currently searching:
IF ( NOT CMAKE_SIZEOF_VOID_P STREQUAL "8" )
    MATH( EXPR installedBits "8 * 8" )
    SET( PACKAGE_VERSION "${PACKAGE_VERSION} (${installedBits}bit)" )
    SET( PACKAGE_VERSION_UNSUITABLE TRUE )
ENDIF()

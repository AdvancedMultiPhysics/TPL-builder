# This will configure and build QT
# Currently this only supports finding QT automatically (need to update)


# Find QT
IF ( NOT DEFINED QT_VERSION )
    SET( QT_VERSION "4" )
ENDIF()
IF ( ${QT_VERSION} EQUAL "4" )
    # Using Qt4
    SET( QT "QT4" )
    SET( Qt "Qt4" )
    SET( QT_COMPONENTS  QtCore QtGui QtOpenGL QtSvg QtSql QtChart )
    FIND_PACKAGE( ${Qt} COMPONENTS ${QT_COMPONENTS} REQUIRED )
ELSEIF ( ${QT_VERSION} EQUAL "5" )
    # Using Qt5
    SET( QT "QT5" )
    SET( Qt "Qt5" )
    SET( QT_COMPONENTS  Core Gui OpenGL Svg Sql )
    FIND_PACKAGE( ${Qt} COMPONENTS ${QT_COMPONENTS} REQUIRED )
    FIND_PACKAGE( Qt5Charts REQUIRED )
ELSE()
    MESSAGE( FATAL_ERROR "Unknown Qt version")
ENDIF()

SET( QT_FOUND ${Qt}_FOUND )
IF ( NOT ${Qt}_FOUND )
    RETURN()
ENDIF()
IF ( NOT DEFINED QT_LIB_DIR AND DEFINED Qt5Core_DIR )
    GET_FILENAME_COMPONENT( QT_LIB_DIR "${Qt5Core_DIR}/../.." ABSOLUTE )
ENDIF()
IF ( ${QT_VERSION} EQUAL "5" )
    GET_TARGET_PROPERTY( QT_QMAKE_EXECUTABLE ${Qt}::qmake IMPORTED_LOCATION )
ENDIF()
ADD_TPL_EMPTY( QT )


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find QT\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_QT AND NOT TPLs_QT_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QT_VERSION ${QT_VERSION} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QT ${QT} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Qt ${Qt} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QT_COMPONENTS ${QT_COMPONENTS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( ${Qt} COMPONENTS ${QT_COMPONENTS} REQUIRED )\n" )
IF ( ${QT_VERSION} EQUAL "5" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Qt5Charts )\n" )
ENDIF()
IF ( ${QT_VERSION} EQUAL "5" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    GET_TARGET_PROPERTY( QT_QMAKE_EXECUTABLE $\{Qt}::qmake IMPORTED_LOCATION )\n" )
ENDIF()
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QT_LIB_DIR ${QT_LIB_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( QT )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )





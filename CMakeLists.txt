project(cura-binary-data)

cmake_minimum_required(VERSION 2.8.12)

include(GNUInstallDirs)

option(BUILD_MARLIN_FIRMWARES "Build Marlin Firmware" ON)
option(PACK_URANIUM "Pack Uranium binary files" ON)
option(PACK_CURA_I18N "Pack Cura i18n files" ON)

unset(PACK_FIRMWARE CACHE)
if(DEFINED ENV{PACK_FIRMWARE})
	set(PACK_FIRMWARE $ENV{PACK_FIRMWARE} CACHE STRING "Pack firmware for Lulzbot, Ultimaker or all" FORCE)
else()
	set(PACK_FIRMWARE "ultimaker" CACHE STRING "Pack firmware for Lulzbot, Ultimaker or all")
endif()

set(MARLIN_BIN_OUT_DIR "${CMAKE_SOURCE_DIR}/build-marlin/out")
set(CURA_FIRMWARES_DIR "${CMAKE_INSTALL_DATADIR}/cura/resources/firmware")

if(BUILD_MARLIN_FIRMWARES)
	add_custom_target(BuildMarlin ALL
	DEPENDS ${MARLIN_BIN_OUT_DIR})

	add_custom_command(	PRE_BUILD
											COMMAND /bin/bash ${CMAKE_SOURCE_DIR}/build-marlin-firmwares.sh
											WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
											OUTPUT ${MARLIN_BIN_OUT_DIR})

 	if(PACK_FIRMWARE STREQUAL "lulzbot")
		install( DIRECTORY ${MARLIN_BIN_OUT_DIR}/
						 DESTINATION ${CURA_FIRMWARES_DIR}
						 FILES_MATCHING PATTERN "*"
						 REGEX ".*Ultimaker.*" EXCLUDE)
	elseif(PACK_FIRMWARE STREQUAL "ultimaker")
		install( DIRECTORY ${MARLIN_BIN_OUT_DIR}/
						 DESTINATION ${CURA_FIRMWARES_DIR}
					 	 FILES_MATCHING REGEX ".*Ultimaker.*")
	else()
		install( DIRECTORY ${MARLIN_BIN_OUT_DIR}/
						 DESTINATION ${CURA_FIRMWARES_DIR})
	endif()
endif()

if(PACK_FIRMWARE STREQUAL "lulzbot")
	install(DIRECTORY cura/resources/firmware/
					DESTINATION ${CURA_FIRMWARES_DIR}
					FILES_MATCHING PATTERN "*"
					REGEX ".*Ultimaker.*" EXCLUDE)
elseif(PACK_FIRMWARE STREQUAL "ultimaker")
	install(DIRECTORY cura/resources/firmware/
					DESTINATION ${CURA_FIRMWARES_DIR}
					FILES_MATCHING REGEX ".*Ultimaker.*" )
else()
	install(DIRECTORY cura/resources/firmware/ DESTINATION ${CURA_FIRMWARES_DIR})
endif()


if(PACK_CURA_I18N)
	install(DIRECTORY cura/resources/i18n/ DESTINATION ${CMAKE_INSTALL_DATADIR}/cura/resources/i18n)
endif()

if(PACK_URANIUM)
	install(DIRECTORY uranium DESTINATION ${CMAKE_INSTALL_DATADIR})
endif()

if(WIN32)
	install(FILES windows/vcredist_x64.exe DESTINATION ".")
	install(FILES windows/vcredist_x32.exe DESTINATION ".")
	install(DIRECTORY windows/arduino DESTINATION ".")
endif()

include(CPackConfig.cmake)

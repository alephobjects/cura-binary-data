project(cura-binary-data)

cmake_minimum_required(VERSION 2.8.12)

include(GNUInstallDirs)

option(BUILD_MARLIN_FIRMWARES "Build Marlin Firmware" ON)

if(BUILD_MARLIN_FIRMWARES)
	add_custom_target(BuildMarlin ALL
	DEPENDS ${CMAKE_SOURCE_DIR}/build-marlin-hex)

	add_custom_command(	PRE_BUILD
											COMMAND /bin/bash ${CMAKE_SOURCE_DIR}/build-marlin-firmwares.sh && mkdir ${CMAKE_SOURCE_DIR}/build-marlin-hex && mv ${CMAKE_SOURCE_DIR}/build-marlin/*.hex ${CMAKE_SOURCE_DIR}/build-marlin-hex
											WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
											OUTPUT ${CMAKE_SOURCE_DIR}/build-marlin-hex)

	install(DIRECTORY ${CMAKE_SOURCE_DIR}/build-marlin-hex/
	DESTINATION ${CMAKE_INSTALL_DATADIR}/cura/resources/firmware)
endif()


install(DIRECTORY cura DESTINATION ${CMAKE_INSTALL_DATADIR})
install(DIRECTORY uranium DESTINATION ${CMAKE_INSTALL_DATADIR})

if(WIN32)
	install(FILES windows/vcredist_x64.exe DESTINATION ".")
	install(FILES windows/vcredist_x32.exe DESTINATION ".")
	install(DIRECTORY windows/arduino DESTINATION ".")
endif()

include(CPackConfig.cmake)

if (LCM_FOUND)
  include_directories(${PROJECT_SOURCE_DIR}/pod-build/lcmgen)
  add_executable(carSimLCM simulateLCM.cpp)
  target_link_libraries(carSimLCM drakeRBSystem drakeLCMSystem)
#  add_test(NAME carSimLCM COMMAND carSimLCM WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/examples/Cars)

  add_executable(publishDrivingCommand publishDrivingCommand.cpp)
  pods_use_pkg_config_packages(publishDrivingCommand lcm)
  add_test(NAME publishDrivingCommand COMMAND publishDrivingCommand 1.0 0.0)
endif (LCM_FOUND)

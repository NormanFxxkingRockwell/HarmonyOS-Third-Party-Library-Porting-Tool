# Whether the utils lib was build.
set(CJSON_UTILS_FOUND OFF)

# The include directories used by cJSON
get_filename_component(CMAKE_CURRENT_LIST_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_prefix "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
set(CJSON_INCLUDE_DIRS "${_prefix}/include")
set(CJSON_INCLUDE_DIR "${_prefix}/include")

get_filename_component(_dir "${CMAKE_CURRENT_LIST_FILE}" PATH)

# The cJSON library
set(CJSON_LIBRARY "cjson")
if(ON)
  # Include the target
  include("${_dir}/cjson.cmake")
endif()

if(CJSON_UTILS_FOUND)
  # The cJSON utils library
  set(CJSON_UTILS_LIBRARY )
  # All cJSON libraries
  set(CJSON_LIBRARIES "" "cjson")
  if(ON)
    # Include the target
    include("${_dir}/cjson_utils.cmake")
  endif()
else()
  # All cJSON libraries
  set(CJSON_LIBRARIES "cjson")
endif()

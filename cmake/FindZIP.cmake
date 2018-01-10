#===============================================================================
# Copyright (C) 2018 Open Source Robotics Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
########################################
# Find zip.

include(IgnPkgConfig)
ign_pkg_check_modules(ZIP libzip)

# If that failed, then fall back to manual detection.
if(NOT ZIP_FOUND)

  if(NOT ZIP_FIND_QUIETLY)
    message(STATUS "Attempting manual search for zip")
  endif()

  find_path(ZIP_INCLUDE_DIRS zip.h ${YAML_INCLUDE_DIRS} ENV CPATH)
  find_library(ZIP_LIBRARIES NAMES zip)
  set(ZIP_FOUND true)

  if(NOT ZIP_INCLUDE_DIRS)
    if(NOT ZIP_FIND_QUIETLY)
      message(STATUS "Looking for zip headers - not found")
    endif()
    set(ZIP_FOUND false)
  endif()

  if(NOT ZIP_LIBRARIES)
    if(NOT ZIP_FIND_QUIETLY)
      message (STATUS "Looking for zip library - not found")
    endif()
    set(ZIP_FOUND false)
  endif()

  if(ZIP_FOUND)
    include(IgnImportTarget)
    ign_import_target(ZIP)
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(
    ZIP
    REQUIRED_VARS ZIP_FOUND)

endif()

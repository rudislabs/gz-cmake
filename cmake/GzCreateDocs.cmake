#.rst
# GzCreatePackage
# ----------------
#
# gz_create_docs
#
# Creates documentation for a Gazebo library project.
#
#===============================================================================
# Copyright (C) 2017 Open Source Robotics Foundation
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

#################################################
# gz_create_docs(
#     [API_MAINPAGE_MD <api_markdown_mainpage>]
#     [AUTOGENERATED_DOC <generated doc dir>]
#     [TUTORIALS_MAINPAGE_MD <tutorials_markdown_mainpage>]
#     [ADDITIONAL_INPUT_DIRS <directory_list>]
#     [TAGFILES <tagfile_list>])
#
# This function will configure doxygen templates and install them.
#
# API_MAINPAGE_MD: Optional. Specify a Markdown page to use as the main page
# for API documentation.
# AUTOGENERATED_DOC: Optional. Directory with the generated code.
# TUTORIALS_MAINPAGE_MD: Optional. Specify a Markdown page to use as the
# main page for tutorial documentation.
# ADDITIONAL_INPUT_DIRS: Optional. Specify additional input directories to parse when generating documentation.
# IMAGE_PATH_DIRS: Optional. Specify additional input directories where images are located
# TAGFILES: Optional. Specify tagfiles for doxygen to use. It should be a list of strings like:
#           "${GZ-<DESIGNATION>_DOXYGEN_TAGFILE} = ${GZ-<DESIGNATION>_API_URL}"
function(gz_create_docs)

  option(BUILD_DOCS "Build docs" ON)
  if (NOT ${BUILD_DOCS})
    message(STATUS "Building Documentation disabled via BUILD_DOCS=OFF")
    return()
  endif()

  # Deprecated, remove skip parsing logic in version 4
  if (NOT gz_create_docs_skip_parsing)
    #------------------------------------
    # Define the expected arguments
    set(options)
    set(oneValueArgs API_MAINPAGE_MD AUTOGENERATED_DOC TUTORIALS_MAINPAGE_MD)
    set(multiValueArgs "TAGFILES" "ADDITIONAL_INPUT_DIRS" "IMAGE_PATH_DIRS")

    #------------------------------------
    # Parse the arguments
    _gz_cmake_parse_arguments(gz_create_docs "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  endif()

  set(required_html_files
    "doxygen/html/annotated.html"
    "doxygen/html/classes.html"
    "doxygen/html/files.html"
    "doxygen/html/functions.html"
    "doxygen/html/functions_func.html"
    "doxygen/html/functions_vars.html"
    "doxygen/html/functions_type.html"
    "doxygen/html/functions_enum.html"
    "doxygen/html/functions_eval.html"
    "doxygen/html/hierarchy.html"
    "doxygen/html/index.html"
    "doxygen/html/namespaces.html"
    "doxygen/html/namespacemembers.html"
    "doxygen/html/namespacemembers_func.html"
    "doxygen/html/namespacemembers_type.html"
    "doxygen/html/namespacemembers_vars.html"
    "doxygen/html/namespacemembers_enum.html"
    "doxygen/html/namespacemembers_eval.html"
  )

  # Add an html file for each required_html_files, which guarantees that
  # all the links in header.html are valid. This is needed because
  # doxygen does not generate an html file if the necessary content is not
  # present in a project. For example, the "hierarchy.html" may not be
  # generated in a project that has no class hierarchy.
  file(READ "${GZ_CMAKE_DOXYGEN_DIR}/header.html" doxygen_header)
  file(READ "${GZ_CMAKE_DOXYGEN_DIR}/footer.html" doxygen_footer)
  string(REGEX REPLACE "\\$projectname" "Gazebo ${GZ_DESIGNATION_CAP}"
    doxygen_header ${doxygen_header})
  string(REGEX REPLACE "\\$projectnumber" "${PROJECT_VERSION_FULL}"
    doxygen_header ${doxygen_header})
  string(REGEX REPLACE "\\$title" "404"
    doxygen_header ${doxygen_header})

  foreach(required_file ${required_html_files})
    file(WRITE ${CMAKE_BINARY_DIR}/${required_file} ${doxygen_header})
    file(APPEND ${CMAKE_BINARY_DIR}/${required_file}
      "<div class='header'><div class='headertitle'>
       <div class='title'>No Documentation</div>
       </div></div>
       <div class='contents'>
       <p>This library does not contain the selected type of documentation.</p>
       <p><a href='#' onClick='history.go(-1);return true;'>Back</a></p>
       </div>")

    file(APPEND ${CMAKE_BINARY_DIR}/${required_file} ${doxygen_footer})
  endforeach()

  #--------------------------------------
  # Configure documentation uploader
  configure_file("${GZ_CMAKE_DIR}/upload_doc.sh.in"
    ${CMAKE_BINARY_DIR}/upload_doc.sh @ONLY)

  #--------------------------------------
  # Create man pages
  include(GzRonn2Man)
  gz_add_manpage_target()

  set(GZ_DOXYGEN_API_MAINPAGE_MD ${gz_create_docs_API_MAINPAGE_MD})
  set(GZ_DOXYGEN_AUTOGENERATED_DOC ${gz_create_docs_AUTOGENERATED_DOC})
  set(GZ_DOXYGEN_TUTORIALS_MAINPAGE_MD
    ${gz_create_docs_TUTORIALS_MAINPAGE_MD})

  set(GZ_DOXYGEN_TAGFILES " ")

  foreach(tagfile ${gz_create_docs_TAGFILES})
    gz_string_append(GZ_DOXYGEN_TAGFILES "\"${tagfile}\"" DELIM " \\\\\\\\\n    ")
  endforeach()

  set(GZ_DOXYGEN_ADDITIONAL_INPUT_DIRS " ")

  foreach(dir ${gz_create_docs_ADDITIONAL_INPUT_DIRS})
    gz_string_append(GZ_DOXYGEN_ADDITIONAL_INPUT_DIRS "${dir}")
  endforeach()

  set(GZ_DOXYGEN_IMAGE_PATH " ")

  foreach(dir ${gz_create_docs_IMAGE_PATH_DIRS})
    gz_string_append(GZ_DOXYGEN_IMAGE_PATH "${dir}")
  endforeach()

  find_package(Doxygen)
  if (DOXYGEN_FOUND AND EXISTS ${GZ_CMAKE_DOXYGEN_DIR}/api.in)

    if(EXISTS ${CMAKE_SOURCE_DIR}/tutorials)
      set(GZ_DOXYGEN_TUTORIALS_DIR ${CMAKE_SOURCE_DIR}/tutorials)
    else()
      set(GZ_DOXYGEN_TUTORIALS_DIR "")
    endif()

    # Configure the main API+Tutorials doxygen configuration file. This
    # configuration file is not used to generate the doxygen tag file,
    # see below.
    set(GZ_DOXYGEN_GENHTML "YES")

    # Be careful when manipulating GZ_DOXYGEN_INPUT. Doxygen is finicky
    # about the spaces between input files/directories. If you put each cmake
    # variable on a separate line to make this `set` command more readable,
    # then doxygen will not generate the correct/complete output.
    set(GZ_DOXYGEN_INPUT "${GZ_DOXYGEN_API_MAINPAGE_MD} ${GZ_DOXYGEN_AUTOGENERATED_DOC} ${GZ_DOXYGEN_TUTORIALS_DIR} ${GZ_DOXYGEN_TUTORIALS_MAINPAGE_MD} ${gz_doxygen_component_input_dirs} ${GZ_DOXYGEN_ADDITIONAL_INPUT_DIRS}")
    configure_file(${GZ_CMAKE_DOXYGEN_DIR}/api.in
                   ${CMAKE_BINARY_DIR}/api.dox @ONLY)

    # The doxygen tagfile should not contain tutorial information. If tutorial
    # information is included in the tagfile and a downstream package also has
    # a page called "tutorials", then doxygen will silently fail to generate
    # tutorial content for the downstream package. In order to
    # satisfy this constraint we generate another doxygen configuration file
    # whose sole purpose is the generation of a project's doxygen tagfile that
    # contains only API information.
    set(GZ_DOXYGEN_GENHTML "NO")
    set(GZ_DOXYGEN_GENTAGFILE
      "${CMAKE_BINARY_DIR}/${PROJECT_NAME_LOWER}.tag.xml")
    set(GZ_DOXYGEN_INPUT "${gz_doxygen_component_input_dirs} ${GZ_DOXYGEN_AUTOGENERATED_DOC}")
    configure_file(${GZ_CMAKE_DOXYGEN_DIR}/api.in
                   ${CMAKE_BINARY_DIR}/api_tagfile.dox @ONLY)

    add_custom_target(doc ALL
      # Generate the API tagfile
      ${DOXYGEN_EXECUTABLE} ${CMAKE_BINARY_DIR}/api_tagfile.dox
      # Generate the API documentation
      COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_BINARY_DIR}/api.dox
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}

      COMMENT "Generating API documentation with Doxygen" VERBATIM)

    install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME_LOWER}.tag.xml
      DESTINATION ${GZ_DATA_INSTALL_DIR})
  endif()

  #--------------------------------------
  # If we're configuring only to build docs, stop here
  if (DOC_ONLY)
    message(WARNING "Configuration was done in DOC_ONLY mode."
    " You can build documentation (make doc), but nothing else.")
    return()
  endif()

endfunction()

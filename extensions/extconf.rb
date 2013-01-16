#!/usr/bin/env ruby
require 'mkmf'

extension_name = 'hadope_backend'
dir_config(extension_name)
have_header('hadope.h')
have_library('OpenCL')
create_makefile(extension_name)

#!/usr/bin/env ruby
require 'mkmf'

$LIBS << ' -framework OpenCL'

extension_name = 'hadope_backend'
dir_config(extension_name)
have_header('hadope.h')
have_header('oclerrorexplain.h')
#have_library('OpenCL')
create_makefile(extension_name)

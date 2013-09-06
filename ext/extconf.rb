#!/usr/bin/env ruby
require 'mkmf'

$LIBS << ' -framework OpenCL'
$objs = %w{lib/hadope.o hadope_backend.o}

extension_name = 'hadope_backend'

dir_config(extension_name)

have_header('lib/hadope.h')
have_header('lib/oclerrorexplain.h')
have_header('lib/prefix_sum/prescan.h')

create_header
create_makefile(extension_name)

#!/usr/bin/env ruby
require 'mkmf'

extension_name = 'hadope_backend'
dir_config(extension_name)
create_makefile(extension_name)

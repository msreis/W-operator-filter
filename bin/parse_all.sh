#!/bin/bash

#
#    Bash script to parse all available samples for all available windows.
#
#    This file is part of the W-operator-filter package.
#    Copyright (C) 2017 Marcelo S. Reis.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

for sample in 06 07 08 09 10
do

  for window in 007 008 009 010 011 012 013 014 015 016 017 025 049 081 121 169
  do
    src/parse_image.pl sample_$sample W_$window
  done

done

exit 0

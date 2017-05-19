#!/usr/bin/perl -w

#
#    This program receives a .dat file, a subset of a window, and designs
#    the W-operator for the filtering step (using the filter_image.pl program).
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

use strict;
use warnings;

# Syntax example: 
#
# ./design_w_operator.pl sample_01_W_05 01011
#
@ARGV == 2 or die "Syntax: $0 dat_file characteristic_vector\n";

my $file = $ARGV[0];
my $subset = $ARGV[1];   # e.g.: for six features, $subset = "101001".

my $INPUT_DAT_DIR       = "output/dat/";
my $OUTPUT_OPERATOR_DIR = "output/operators/";
 
open (INPUT, $INPUT_DAT_DIR . $file . ".dat")
  or die "Could not open input file!\n";

my %frequency_0 = ();
my %frequency_1 = ();

print "Calculating probabilities of the subset: $subset... ";

while (<INPUT>)
{
  chomp $_;
  my $realization = "";

  for (my $i = 0; $i < length ($subset); $i++)
  {
    if (substr ($subset, $i, 1) == '1')
    {
      $realization = $realization . substr ($_, 2 * $i, 1) . " ";
    }
    else
    {
      $realization = $realization . "X" . " ";
    }
  }

  if ((! defined $frequency_0{$realization}) ||
      (! defined $frequency_1{$realization}))
  {
    $frequency_0{$realization} = 0;
    $frequency_1{$realization} = 0;
  }
    
  $_ =~ /.*\s(\d+)\s(\d+)$/;
  $frequency_0{$realization} += $1;
  $frequency_1{$realization} += $2;
}

print "[done]\n";

close (INPUT);

printf "Printing into a DAT file the frequencies of a window of size %d... ",
       length $subset;

open (OUTPUT, ">" . $OUTPUT_OPERATOR_DIR . $file . ".operator");

foreach my $realization (sort keys %frequency_0)
{
  if ($frequency_0{$realization} > $frequency_1{$realization})
  {
    printf OUTPUT "%s 0\n", $realization;
  }
  else
  {
    printf OUTPUT "%s 1\n", $realization;
  }
}

close (OUTPUT);

print "[done]\n";

# End of program.
#
exit 0;


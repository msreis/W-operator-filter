#!/usr/bin/perl -w

#
#    Program to carry out integration tests on the W-operator-filter files.
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
use Test;


# Number of planned tests and number of the tests
#
BEGIN { plan tests => 3 }
    

# Helpful notes. All note-lines must start with a "#".
#
print "# I'm testing the programs stored in '/src'!\n";

#-------------------------------------------------------------------------------

print "\n# It should parse images...\n";


my @images = ("sample_01");

#my @images = ("sample_01", "sample_02", "sample_03", "sample_04", "sample_05",
#              "sample_06", "sample_07", "sample_08", "sample_09", "sample_10");


my @windows = ("W_03", "W_07", "W_08", "W_09", "W_10", "W_11",
               "W_12", "W_13", "W_14", "W_16", "W_17");


foreach my $image (@images)
{
  foreach my $window (@windows)
  {
    system ("src/parse_image.pl $image $window 1> out 2> err");
  }
}
system ("rm out");
system ("rm err");

my $created_files = 0;

system ("ls output/images/ > created_files.txt");
system ("ls output/dat/ >> created_files.txt");

open (INPUT, "created_files.txt") or die "Error: could not read file!\n";
while (<INPUT>)
{
  $created_files++;
}
close (INPUT);

system ("rm created_files.txt");

# For each image, it is created one dat file per window, and also a pair
# of binary ideal and observed images.
#
my $expected_files = (scalar @images * scalar @windows) + (2 * scalar @images); 

ok ($created_files == $expected_files);


#-------------------------------------------------------------------------------

# Before this point, the user can perform feature selection using the featsel
# framework and use the characteristic vector of the best subset for the 
# W-operator design. In this test procedure, we did not carry out feature
# selection and adopted the complete subset for all window files, with the
# exception of W_15 -- thanks to that, the user can visually inspect the 
# filtered images and see the impact of feature selection on the filtering
# process! :-)
#

print "\n# It should design W-operator filters...\n";

my %vectors = ("W_03" => "111",
               "W_07" => "1111111",
               "W_08" => "11111111",
               "W_09" => "111111111",
               "W_10" => "1111111111",
               "W_11" => "11111111111",
               "W_12" => "111111111111",
               "W_13" => "1111111111111",
               "W_14" => "11111111111111",
               "W_15" => "100011100000001",
               "W_16" => "1111111111111111",
               "W_17" => "11111111111111111");

push @windows, "W_15";

foreach my $image (@images)
{
  foreach my $window (@windows)
  {
    my $dat = $image . "_" . $window;
    my $vector = $vectors{$window};
    system ("src/design_W_operator.pl $dat $vector 1> out 2> err");
  }
}
system ("rm out");
system ("rm err");

$created_files = 0;

system ("ls output/operators/ > created_files.txt");

open (INPUT, "created_files.txt") or die "Error: could not read file!\n";
while (<INPUT>)
{
  $created_files++;
}
close (INPUT);

system ("rm created_files.txt");

# For each image, it is designed one W-operator per window file.
#
$expected_files = scalar @windows; 

ok ($created_files == $expected_files);

#-------------------------------------------------------------------------------

print "\n# It should filter images with the designed W-operators...\n";

foreach my $image (@images)
{
  foreach my $window (@windows)
  {
    system ("src/filter_image.pl $image $window 1> out 2> err");
  }
}
system ("rm out");
system ("rm err");

$created_files = 0;

system ("ls output/images/ > created_files.txt");

open (INPUT, "created_files.txt") or die "Error: could not read file!\n";
while (<INPUT>)
{
  $created_files++;
}
close (INPUT);

system ("rm created_files.txt");

# For each image, we should count the pair of ideal, observed images created
# previously and additionally one filtered image file per window file.
#
$expected_files = (2 * scalar @images) + (scalar @windows * scalar @images); 

ok ($created_files == $expected_files);

#-------------------------------------------------------------------------------

print "\n# End of tests.\n\n"; 



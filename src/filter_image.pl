#!/usr/bin/perl -w

#
#    This program receives a file, a window, and filters the observed image.
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

# GD is not called automatically in Mac OS X environment! Instead call as
# perl -I/opt/local/lib/perl5/5.8.9 ./filter_image.pl sample_0X W_XX
#
use GD;

# for floor and ceiling functions
#
use POSIX;

my $INPUT_IMAGE_DIR = "output/images/";     # Observed image is created here.
my $OUTPUT_IMAGE_DIR = "output/images/"; 
my $OPERATOR_DIR    = "output/operators/";
my $WINDOW_DIR      = "input/windows/";

# Syntax example: 
#
# ./src/filter_image.pl sample_01 W_03
#
@ARGV == 2 or die "Syntax: $0 sample_file window_file\n";


my $image_file  = $ARGV[0];
my $window_name = $ARGV[1];   # "W_03", "W_05", etc.

my $filtered_image = [];
my $observed_image = [];

my $gdimg = GD::Image->newFromPng
  ($INPUT_IMAGE_DIR . $image_file . "_observed.png");

my ($width, $height) = $gdimg->getBounds ();

print "Loading the image '" . $image_file . "_observed.png' from file... ";

my $x = 0;

while ($x < $width) 
{
  my $y = 0;
  while ($y < $height) 
  {
    my $index = $gdimg->getPixel ($x, $y);
    my ($r, $g,$ b) = $gdimg->rgb ($index);
    $observed_image->[$y]->[$x] = ($r + $g + $b) / 3;

    # 0..127 / 128..255
    #
    if ($observed_image->[$y]->[$x] >= 128)
    {
      $observed_image->[$y]->[$x] = 0;
    }
    else
    {
      $observed_image->[$y]->[$x] = 1;
    }
    $y++;
  }
  $x++;
}

print "[done]\n";

print "Loading the W-operator file... ";

my %operator = ();
my $masking = "";

open (ARQ, $OPERATOR_DIR . $image_file . "_" . $window_name . ".operator")
  or die "Could not open W-operator file!\n";

while (<ARQ>)
{
  chomp $_;
  if ($_ =~ /(.*\s)\s(\d)$/)
  {
    $operator{$1} = $2;
    $masking = $1;
  }
}
close (ARQ);

print "[done]\n";

print "Loading window shape data... ";

open (ARQ, $WINDOW_DIR . $window_name)
  or die "Could not open $window_name file!\n";

my $lines = <ARQ>;
my $columns = <ARQ>;

my @window;
my $line = 0;

while (<ARQ>)
{
  chomp $_;
  if ($_ =~ /\S+/)  # avoid trying to load blank lines
  {
    @{$window[$line]} = split " " , $_;
    $line++;
  }
}

print "[done]\n";


# Create a new image.
#
my $im = new GD::Image ($width, $height);

# Allocate binary colors.
#
my $white = $im->colorAllocate (255,255,255);
my $black = $im->colorAllocate (0,0,0);  

my $middle_column = floor ($columns / 2);
my   $middle_line = floor ($lines / 2);

print "Scanning the observed matrix and applying the filter $window_name... ";

for (my $x = 0 + 1; $x < $width - 1; $x++)
{
  for (my $y = 0 + 1; $y < $height - 1; $y++)
  {
    my $realization = "";
    my $i = 0;

    for (my $xx = - $middle_column; $xx <= $middle_column; $xx++)
    {
      for (my $yy = - $middle_line; $yy <= $middle_line; $yy++)
      {
        if ($window[$yy]->[$xx] == 1)
        {
          (substr ($masking, $i, 1) eq "X")
            and $realization .=  "X "
             or $realization .= $observed_image->[$y + $yy]->[$x + $xx] . " ";
           $i += 2;
        }
      }
    }

    if (defined $operator{$realization})
    {
      $filtered_image->[$y]->[$x] = $operator{$realization};
    }
    else
    {
      $filtered_image->[$y]->[$x] = $observed_image->[$y]->[$x];
    }

    if ($filtered_image->[$y]->[$x] == 0)
    {
      $im->setPixel ($x, $y, $white);
    }
    else
    {
      $im->setPixel ($x, $y, $black);
    }

  }  # for $y
}  # for $x 
	 

print "[done]\n";


# Convert the image to PNG and print it on output file.
#
open (ARQ,">" . $OUTPUT_IMAGE_DIR . $image_file . "_filtered_" .
      $window_name . ".png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close (ARQ);

# End of program.
#
exit 0;



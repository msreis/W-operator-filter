#!/usr/bin/perl -w

#
#    This program parses an image, creating the binary ideal image, the binary
#    observed image with a given amount of salt-and-pepper noise, and some given
#    amount of samples for windows of a given size.
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
use Data::Dumper;  # Useful to dump a data structure in order to inspect it.

# GD is not called automatically in Mac OS X environment! Instead call as
# perl -I/opt/local/lib/perl5/5.8.9 ./parse_image.pl
#
use GD;

# Allows the usage of floor and ceiling functions;
#
use POSIX;

# This is useful for shuffling arrays.
#
use List::Util 'shuffle';

# This constant defines the proportion of salt and pepper noise that will be
# applied on the observed image
#
my $PROBABILITY_OF_NOISE = 0.3; 


my $INPUT_IMAGES_DIR  = "input/images/";
my $INPUT_WINDOWS_DIR = "input/windows/";

my $OUTPUT_IMAGES_DIR  = "output/images/";
my $OUTPUT_DAT_DIR     = "output/dat/";


# Sample file must be without directory and extension. Example:
#
#  ./src/parse_image.pl sample_01 W_03
#
@ARGV == 2 or die "\nSyntax: $0 sample_file window_file\n\n";

my $file = $ARGV[0];

$| = 1;

# WARNING: W-operator window MUST have an odd number of lines and columns!
#
# A W-operator window file is in the format:
#
# 3
# 5
# 1 0 1 0 1
# 0 1 1 1 0 
# 1 0 1 0 1
#
# where the first integer (in this example, 3) is the number of window lines,
# the second integer (in this example, 5) is the number of window columns, and
# the remaining data is the window itself, in which 1s and 0s represent
# presence/absence of a given pixel, respectively.
#
my $window = $ARGV[1];

$window =~ /(\d+)/;
my $number_of_features = $1;

print "Screening image with a window of size $number_of_features.\n";

my $ideal_image = [];
my $observed_image = [];

my $gdimg = GD::Image->newFromPng ($INPUT_IMAGES_DIR . $file . ".png");
my ($width, $height) = $gdimg->getBounds ();


# This constant defines the proportion of the observations that will be used
# to generate the samples. Observe that a reduction in the size of the stored
# samples leads to an increase on the estimation error! 
#
my $alpha = 0.25;
my $SIZE_OF_SAMPLING = int (($width * $height) ** $alpha * $number_of_features);

printf "Loading the image '" . $file . ".png' from file... ";

my $x = 0;
while ($x < $width) 
{
  my $y = 0;
  while ($y < $height) 
  {
    my $index = $gdimg->getPixel ($x, $y);
    my ($r, $g,$ b) = $gdimg->rgb ($index);
    $ideal_image->[$y]->[$x] = ($r + $g + $b) / 3;

    # Converting the colored image into a binary one using the following
    # criterion for each pixel:
    #
    #   0..127 => white pixel
    # 128..255 => black pixel
    #
    if ($ideal_image->[$y]->[$x] >= 114)  # 128
    {
      $ideal_image->[$y]->[$x] = 0;
    }
    else
    {
      $ideal_image->[$y]->[$x] = 1;
    }
    $y++;
  }
  $x++;
}

print "[done]\n";

printf "Image with width = $width and height = $height (%d pixels)\n",
       $width * $height;

# Create a new image.
#
my $im = new GD::Image ($width, $height);

# Allocate the used colors.
#
my $white = $im->colorAllocate (255,255,255);
my $black = $im->colorAllocate (0,0,0);  

print "Loading the ideal image matrix and creating the ideal image file... ";

for (my $x = 0; $x < $width; $x++)
{
  for (my $y = 0; $y < $height; $y++)
  {
    if ($ideal_image->[$y]->[$x] == 0)
    {
      $im->setPixel ($x, $y, $white);
    }
    else
    {
      $im->setPixel ($x, $y, $black);
    }
  }
}

# Convert the image to PNG and print it on output file.
#
open(ARQ,">" . $OUTPUT_IMAGES_DIR . $file . "_ideal.png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close(ARQ);

print "[done]\n";


print "Loading the observed image matrix (with salt and pepper noise) " . 
      "and creating the observed image file... ";

for (my $x = 0; $x < $width; $x++)
{
  for (my $y = 0; $y < $height; $y++)
  {
    if ($ideal_image->[$y]->[$x] == 0)
    {
      $im->setPixel ($x, $y, $white);
      $observed_image->[$y]->[$x] = 0;
    }
    else
    {
      $im->setPixel ($x, $y, $black);
      $observed_image->[$y]->[$x] = 1;
    }

    # Print some noise.
    #
    if (rand (1) <= $PROBABILITY_OF_NOISE)  # Should we put noise on this pixel?
    {
      if (rand (1) <= ($PROBABILITY_OF_NOISE / 2))
      {
        $im->setPixel ($x, $y, $white);      # Salt!
        $observed_image->[$y]->[$x] = 0;
      }
      else
      {
        $im->setPixel ($x, $y, $black);      # Pepper!
        $observed_image->[$y]->[$x] = 1;
      }
    }
  }   # for (my $y...
}   # for (my $x...

# Convert the image to PNG and print it on output file
#
open (ARQ, ">" . $OUTPUT_IMAGES_DIR . $file . "_observed.png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close (ARQ);

print "[done]\n";

# Now, we scan the the pair of images (<observed, ideal>), 
# in order to produce the W-operator sample files!
#
print "Loading W-operator window data... ";

open (ARQ, $INPUT_WINDOWS_DIR . $window)
  or die "Could not open $window file!\n";

my $lines = <ARQ>;
my $columns = <ARQ>;

my @W_operator;
my $line = 0;

while (<ARQ>)
{
  chomp $_;
  if ($_ =~ /\S+/)  # avoid trying to load blank lines
  {
    @{$W_operator[$line]} = split " " , $_;
    $line++;
  }
}

print "[done]\n";

print "Scanning the matrices and counting the frequencies of the " . 
      "W-operator window... ";

my $middle_column = floor ($columns / 2);
my $middle_line = floor ($lines / 2);

my @list_of_observations;

my $sample_counter = 0;

for (my $x = 0 + $middle_column; $x < $width - $middle_column; $x++)
{
  for (my $y = 0 + $middle_line; $y < $height - $middle_line; $y++)
  {
    $sample_counter++;
	  
    my $realization = get_realization ($observed_image, $x,$y, $middle_column,
                                       $middle_line, \@W_operator);	    

    if ($ideal_image->[$y]->[$x] == 0)
    {
      push @list_of_observations, "$realization 1 0";
    }
    else
    {
      push @list_of_observations, "$realization 0 1";
    }

  }  # for $y
}  # for $x 

print "[done]\n";

print "Verified $sample_counter realizations of the window through this image.";
print "\n";
print "However, only $SIZE_OF_SAMPLING of them will be saved into DAT file!\n";
print "Printing into a DAT file the frequencies of the W-operator window... ";

$file =~ /(\d+)/;
my $test_number = sprintf "%02d", $1;

my $features_string = sprintf "%03d", $number_of_features;

open(ARQ,">" . $OUTPUT_DAT_DIR . "Test_" . $features_string . "_" . $test_number
             . ".dat");

foreach my $index (shuffle (0..$#list_of_observations))
{
  if ($SIZE_OF_SAMPLING > 0)
  {
    printf ARQ "%s\n", $list_of_observations[$index];

    $SIZE_OF_SAMPLING--;
  }
  else
  {
    close(ARQ);

    print "[done]\n";
    print "\nEnd of execution.\n\n";

    # End of program.
    #
    exit 0;
  }
}

close(ARQ);

print "[done]\n";
print "\nEnd of execution.\n\n";

# End of program.
#
exit 0;


#------------------------------------------------------------------------------#
#
# Sub that returns the realization of the window for the current image position.
#
sub get_realization
{
  my ($observed_image, $x0,$y0, $middle_column, $middle_line, $W_operator) = @_;   
  my $realization = "";

  for (my $x = - $middle_column; $x <= $middle_column; $x++)
  {
    for (my $y = - $middle_line; $y <= $middle_line; $y++)
    {
      # The W-operator window might have "holes", hence we need to verify
      # if a given position actually belongs to the window area!
      #
      if ($W_operator[$y]->[$x] == 1) 
      {
        $realization .= $observed_image->[$y0 + $y]->[$x0 + $x] . " ";
      }
    }
  }
  return $realization;
}

#------------------------------------------------------------------------------#


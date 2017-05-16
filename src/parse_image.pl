#!/usr/bin/perl -w

# Parse an image, creating the binary ideal image, the binary observed image
# with a given amount of salt-and-pepper noise, and some given amount of samples
# for windows of size 3, 5, 9, 13, 17, 21, 25, and 33.
#
# M.S.Reis, June 8, 2014.

# call as ./parse_image.pl sample_0X

use strict;
use warnings;
use Data::Dumper;     # useful to dump a data structure in order to inspect it 

# GD is not called automatically in Mac OS X environment! Instead call as
# perl -I/opt/local/lib/perl5/5.8.9 ./parse_image.pl sample_0X
#
use GD;

# for floor and ceiling functions
#
use POSIX;

#
# W-operator window is in the format W_05, W_17, etc.
#
# Sample file must be without directory and extension. Example:
#
#  ./parse_image.pl sample_01 W_03
#
@ARGV == 2 or die "\nSyntax: $0 sample_file w_operator_window\n\n";

my $file       = $ARGV[0];

$| = 1;

# WARNING: W-operator window MUST have an odd number of lines and columns!
#
#
my $W_operator = $ARGV[1];

#
# To generate an image with salt and pepper noise
#
my $probability_of_noise = 0.3;   # x % of noise

# Reduction in the size of the stored samples leads to an increasing on the estimation error! 
#
# my $size_of_sampling = 0.001;   # stores $size_of_sampling * 100 % of the samples
my $size_of_sampling = 0.0004;   # stores $size_of_sampling * 100 % of the samples



my $ideal_image = [];
my $observed_image = [];

my $gdimg = GD::Image->newFromPng ("input/" . $file . ".png");
my ($width, $height) = $gdimg->getBounds ();

print "Loading the image '" . $file . ".png' from file... ";
my $x = 0;
while ($x < $width) 
  {
    my $y = 0;
    while ($y < $height) 
      {
        my $index = $gdimg->getPixel ($x, $y);
        my ($r, $g,$ b) = $gdimg->rgb ($index);
        $ideal_image->[$y]->[$x] = ($r + $g + $b) / 3;

	# 0..127 / 128..255
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

# create a new image
my $im = new GD::Image($width, $height);

# allocate some colors
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);  

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
# Convert the image to PNG and print it on output file
open(ARQ,">output/" . $file . "_ideal.png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close(ARQ);
print "[done]\n";


print "Loading the observed image matrix (with salt and pepper noise) and creating the observed image file... ";
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

	  # print some noise
	  #
	  if (rand(1) <= $probability_of_noise)
	  {
	    if (rand(1) <= ($probability_of_noise / 2))
	    {
		    $im->setPixel ($x, $y, $white);
		    $observed_image->[$y]->[$x] = 0;
	    }
	    else
	    {
		    $im->setPixel ($x, $y, $black);
		    $observed_image->[$y]->[$x] = 1;
	    }
	  }
  }   # for (my $y...
}     # for (my $x...

# Convert the image to PNG and print it on output file
#
open (ARQ, ">output/" . $file . "_observed.png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close (ARQ);
print "[done]\n";


# Now, we scan the the pair of images (<observed, ideal>), 
# in order to produce the W-operator sample files!
#
print "Loading W-operator window data... ";

open (ARQ, "windows/" . $W_operator) or die "Could not open $W_operator file!\n";

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

print "Scanning the matrices and counting the frequencies of the W-operator window... ";

my $middle_column = floor ($columns / 2);
my $middle_line = floor ($lines / 2);

my %frequency_0;
my %frequency_1;

my $sample_counter = 0;

for (my $x = 0 + $middle_column; $x < $width - $middle_column; $x++)
{
  for (my $y = 0 + $middle_line; $y < $height - $middle_line; $y++)
  {
	  if (rand(1) < $size_of_sampling)  # counts only a fraction of the image
	  {
	    $sample_counter++;
	  
	    my $realization = get_realization ($observed_image, $x, $y, $middle_column, $middle_line, \@W_operator);
	    
	    if ($ideal_image->[$y]->[$x] == 0)
	    {
		    $frequency_0{$realization}++;
		    defined $frequency_1{$realization} or $frequency_1{$realization} = 0;
	    }
	    else
	    {
		    $frequency_1{$realization}++;
		    defined $frequency_0{$realization} or $frequency_0{$realization} = 0;
	    }
	  }
  }  # for $y
}    # for $x 

print "[done]\n";
print "It verified $sample_counter realizations of the window through this image.\n";
print "Printing into a DAT file the frequencies of the W-operator window... ";

open(ARQ,">output/" . $file . "_" . $W_operator . ".dat");

foreach my $realization (sort keys %frequency_0)
{
  printf ARQ "%s %d %d\n", $realization,  $frequency_0{$realization},  $frequency_1{$realization};
}

close(ARQ);

print "[done]\n";
print "\nEnd of execution.\n\n";

exit 0;


#
# it returns the realization of the window for the current image position (x0, y0)
#
sub get_realization
{
  my ($observed_image, $x0, $y0, $middle_column, $middle_line, $W_operator) = @_;   
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


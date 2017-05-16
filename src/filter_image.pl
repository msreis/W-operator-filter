#!/usr/bin/perl -w

# call as ./parse_png_into_txt.pl sample_0X

use strict;
use warnings;

# GD is not called automatically in Mac OS X environment! Instead call as
# perl -I/opt/local/lib/perl5/5.8.9 ./filter_image.pl sample_0X W_XX
#
use GD;


# This program receives a file, a window, and filter
# the observed image
#
# Sintaxe example: 
#
# ./filter_image.pl sample_01 W_09
#


@ARGV == 2 or die "Sintaxe: ./filter_image.pl sample_01 W_09\n";

my $file = $ARGV[0];
my $window_size = $ARGV[1];   # "W_03", "W_05", etc.

my $filtered_image = [];
my $observed_image = [];

my $gdimg = GD::Image->newFromPng ($file . "_observed.png");
my ($width, $height) = $gdimg->getBounds ();

print "Loading the image '" . $file . "_observed.png' from file... ";
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
open(ARQ, $file . "_" . $window_size . ".dat.subset") or die "Could not open W-operator file!\n";
while (<ARQ>)
  {
    chomp $_;
    if ($_ =~ /(.*\s)\s(\d)$/)
      {
	$operator{$1} = $2;
	$masking = $1;
      }
  }
close(ARQ);
print "[done]\n";

# create a new image
my $im = new GD::Image($width, $height);

# allocate some colors
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);  

print "Scanning the observed matrix and applying the filter $window_size... ";

elsif ($window_size eq "W_09")
  {
    for (my $x = 0 + 1; $x < $width - 1; $x++)
      {
	for (my $y = 0 + 1; $y < $height - 1; $y++)
	  {
	    my $realization = "";
	    my $i  = 0;

	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y-1]->[$x-1] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y-1]->[$x] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y-1]->[$x+1] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y]->[$x-1] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y]->[$x] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y]->[$x+1] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y+1]->[$x-1] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y+1]->[$x] . " ";
	    $i += 2;
	    (substr($masking, $i, 1) eq "X") and $realization .=  "X " or $realization .= $observed_image->[$y+1]->[$x+1] . " ";
	    
	    if (defined $operator{$realization})
	      {
		$filtered_image->[$y]->[$x] = $operator{$realization};
	      }
	    else
	      {
		$filtered_image->[$y]->[$x] = int(rand(2)) % 2;  # it is either 0 or 1
	      }
	    if ($filtered_image->[$y]->[$x] == 0)
	      {
		$im->setPixel ($x, $y, $white);
	      }
	    else
	      {
		$im->setPixel ($x, $y, $black);
	      }
	  }
      }
  }


print "[done]\n";


# Convert the image to PNG and print it on output file
#
open(ARQ,">" . $file . "_filtered_" . $window_size . ".png");
binmode ARQ;   # may be binmode STDOUT
printf ARQ "%s", $im->png;
close(ARQ);

# End of program.
#
exit 0;



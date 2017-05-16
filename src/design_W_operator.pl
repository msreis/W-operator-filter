#!/usr/bin/perl -w

use strict;
use warnings;


# This program receives a .dat file, a subset of a window, and designs
# the W-operator for the filtering step (filter_image.pl)
#
# Sintaxe example: 
#
# ./design_w_operator.pl sample_01_W_05.dat 01011
#


@ARGV == 2 or die "Sintaxe: ./design_w_operator.pl sample_01_W_05.dat 01011\n";

my $file = $ARGV[0];
my $subset = $ARGV[1];        # e.g., for W_05, an element X of P(S), for instance, X = 01011
 
open (ARQ, $file) or die "Could not open input file!\n";

my %frequency_0 = ();
my %frequency_1 = ();

print "Calculating probabilities of the subset: $subset... ";
while (<ARQ>)
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
    if ((!defined $frequency_0{$realization}) || (!defined $frequency_1{$realization}))
      {
	$frequency_0{$realization} = 0;
	$frequency_1{$realization} = 0;
      }
    
    $_ =~ /.*\s(\d+)\s(\d+)$/;
    $frequency_0{$realization} += $1;
    $frequency_1{$realization} += $2;
   }
print "[done]\n";
close(ARQ);

printf "Printing into a DAT file the frequencies of a window of size %d... ", length $subset;
open (ARQ, ">" . $file . ".subset");
foreach my $realization (sort keys %frequency_0)
  {
    if ($frequency_0{$realization} > $frequency_1{$realization})
      {
	printf ARQ "%s 0\n", $realization;
      }
    else
      {
	printf ARQ "%s 1\n", $realization;
      }
  }
close(ARQ);
print "[done]\n";

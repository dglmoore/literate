# Copyright 2014 Douglas Moore. All rights reserved.
# Use of this source code is governed by the MIT
# license that can be found in the LICENSE file.

#!/bin/env perl

use Getopt::Long;

my $tabs = '';
my $tabstop = 2;

GetOptions("tabstop=i", \$tabstop,
					 "tabs!", \$tabs)
or die("error in command line arguments");

if ($#ARGV != 0)
{
	print STDERR "must provide exactly one chunk\n";
	exit(1);
}

my $chunkname = @ARGV[0];
my @array = <STDIN>;
my $linecount = printchunk($chunkname, \@array, "");
print STDERR "Read \"$chunkname\": $linecount line(s)\n";

my @chunkstack = qw();
sub printchunk {
	my $linenum = 0;
	my $chunkname = $_[0];
	my $context = $_[1];
	my $indent = $_[2];
	my $inside = 0;
	my $linecount = 0;
	my $chunkstartline = 0;
	if (!$tabs && $tabstop) {
		$indent =~ s/\t/' ' x $tabstop/eg;
	} elsif ($tabs && $tabstop) {
		$indent =~ s/ {$tabstop}/\t/g;
	}
	foreach (@{$context}) {
		$linenum += 1;
		if (/^\s*\\chunk\{$chunkname\}\s*$/) {
			$inside = 1;
			$chunkstartline = $linenum;
			push(@chunkstack,$chunkname);
		} elsif ($inside && /^\s*\\getchunk\{\s*\}\s*$/) {
			print STDERR "WARNING: empty chunk request found at $linenum\n";
		} elsif ($inside && /^(\s*)\\getchunk\{([^\}]+)\}\s*$/) {
			if (grep(/^$2$/,@chunkstack)) {
				printf STDERR "circular chunk inclusion found:\n";
				foreach (@chunkstack) {
					print STDERR "$_ -> ";
				}
				print STDERR "$2\n";
				exit(4);
			}
			$linecount += printchunk($2,$context,$indent.$1);
		} elsif ($inside && /^\s*\\endchunk\s*$/) {
			if ($chunkstartline == $linenum - 1) {
				print STDERR "WARNING: empty chunk ($chunkname) ".
					"found on line $chunkstartline\n";
			}
			$inside = 0;
			pop @chunkstack;
		} elsif ($inside && /^(\s*)(.*)$/) {
			if (!$tabs && $tabstop) {
				$_ =~ s/\t/' ' x $tabstop/eg; 
			} elsif ($tabs && $tabstop) {
				$_ =~ s/ {$tabstop}/\t/g;
			}
			$_ =~ s/\\\|/|/g;
			print "$indent$_";
			$linecount += 1;
		}
	}
	if ($chunkstack[-1] =~ $chunkname) {
		print STDERR "never exited chunk \"$chunkname\"\n";
		exit(3);
	}
	if ($linecount == 0 && $line != 0) {
		print STDERR "WARNING: empty chunk ($chunkname) found on line $chunkstartline\n";
	} else if ($linecount == 0) {
		print STDERR "ERROR: no chunk ($chunkname) found\n";
		exit(2);
	}
	$linecount;
}

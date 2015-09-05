#!/usr/bin/env perl

# Copyright 2014 Douglas Moore. All rights reserved.
# Use of this source code is governed by the MIT
# license that can be found in the LICENSE file.

use Getopt::Long;

my $tabs = '';
my $tabstop = 2;
my $linemacro = "#line %L \"%F\"";

GetOptions("tabstop=i", \$tabstop,
					 "tabs!", \$tabs,
					 "line=s", \$linemacro)
or die("error in command line arguments: $!");

if ($#ARGV != 1)
{
	print STDERR "must provide exactly one chunk and one filename\n";
	exit(1);
}

my $chunkname = @ARGV[0];
my $filename = @ARGV[1];
open(my $FH, "<", $filename)
	or die("cannot open < file ($filename): $!");
my @array = <$FH>;
close($FH);
$linemacro =~ s/%F/$filename/g;
my $linecount = printchunk($chunkname, \@array, "");
print STDERR "Read \"$chunkname\" from \"$filename\": $linecount line(s)\n";

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
		if (/^\s*\\chunk\{\Q$chunkname\E\}\s*$/) {
			$inside = 1;
			$chunkstartline = $linenum;
			push(@chunkstack,$chunkname);
			if ($linemacro) {
				(my $l = $linemacro) =~ s/%L/($linenum+1)/ge;
				print "$l\n";
			}
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
			if ($linemacro) {
				(my $l = $linemacro) =~ s/%L/($linenum+1)/ge;
				print "$l\n";
			}
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
	if ($chunkstack[-1] =~ /^\Q$chunkname\E$/) {
		print STDERR "never exited chunk \"$chunkname\"\n";
		exit(3);
	}
	if ($linecount == 0 && $linenum != 0) {
		print STDERR "WARNING: empty chunk ($chunkname) found on line $chunkstartline\n";
	} elsif ($linecount == 0) {
		print STDERR "ERROR: no chunk ($chunkname) found\n";
		exit(2);
	}
	$linecount;
}

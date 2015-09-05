#!/usr/bin/env perl

# Copyright 2014 Douglas Moore. All rights reserved.
# Use of this source code is governed by the MIT
# license that can be found in the LICENSE file.

my %roots;
my %leaves;

my $linenum = 0;
while (<>) {
  $linenum += 1;
  if (/^\s*\\chunk\{([^\}]+)\}\s*$/) {
    $roots{$1} = 1;
  } elsif (/^\s*\\chunk\{\s*\}\s*$/) {
    print STDERR "WARNING: unnamed chunk found on line $linenum\n";
  } elsif (/^\s*\\getchunk\{([^\}]+)\}\s*$/) {
    $leaves{$1} = 1;
  } elsif (/^\s*\\getchunk\{\s*\}\s*$/) {
    print STDERR "WARNING: unnamed chunk requested on line $linenum\n";
  }
}

for (keys %roots) {
	print "$_\n" if not exists $leaves{$_};
}


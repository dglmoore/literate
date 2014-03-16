# Copyright 2014 Douglas Moore. All rights reserved.
# Use of this source code is governed by the MIT
# license that can be found in the LICENSE file.

#!/bin/env perl

my $linenum = 0;
while (<>) {
  $linenum += 1;
  if (/^\s*\\chunk\{([^\} ]+)\}\s*$/) {
    print "$1\n";
  } elsif (/^\s*\\chunk\{\s*\}\s*$/) {
    print STDERR "WARNING: unnamed chunk found on line $linenum\n";
  }
}

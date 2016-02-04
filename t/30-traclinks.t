use strict;
use warnings;

use Test::More tests => 2;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
See issue #4.
EOG
$expect = <<EOE;
See issue #4.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'simple ticket link');

$give = <<EOG;
Prefix ticket:5. Another bug:3.
EOG
$expect = <<EOE;
Prefix #5. Another #3.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'prefix style ticket link');


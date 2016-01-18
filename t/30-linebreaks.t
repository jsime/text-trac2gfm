use strict;
use warnings;

use Test::More tests => 1;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = "foo\r\nbar";
$expect = "foo\nbar";
cmp_ok(trac2gfm($give), 'eq', $expect, 'linebreak translation');


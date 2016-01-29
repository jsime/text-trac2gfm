use strict;
use warnings;

use Test::More tests => 2;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
This sentence contains a CamelCase link to another page.
EOG
$expect = <<EOE;
This sentence contains a [CamelCase](camel-case) link to another page.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'camel-case wiki link');

$give = <<EOG;
This contains a blocked !CamelCase word that should not be a link.
EOG
$expect = <<EOE;
This contains a blocked CamelCase word that should not be a link.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'non-linked camel-case word');


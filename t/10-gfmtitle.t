use strict;
use warnings;

use Test::More tests => 5;

use Text::Trac2GFM qw( gfmtitle );

cmp_ok(gfmtitle('Foo'),                'eq', 'foo');
cmp_ok(gfmtitle('Foo/Bar'),            'eq', 'foo-bar');
cmp_ok(gfmtitle('Foo & Bar'),          'eq', 'foo-and-bar');
cmp_ok(gfmtitle('Multiple    Spaces'), 'eq', 'multiple-spaces');
cmp_ok(gfmtitle('[Invalid)^Chars!'),   'eq', 'invalid-chars');

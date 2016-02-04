use strict;
use warnings;
package Text::Trac2GFM;
# ABSTRACT: Converts TracWiki formatted text to GitLab-flavored Markdown (GFM).

use Exporter::Easy (
    OK => [ 'trac2gfm', 'gfmtitle' ]
);

=head1 NAME

Text::Trac2GFM

=head1 SYNOPSIS

As a Perl library:

    use Text::Trac2GFM qw( trac2gfm gfmtitle );

    # GitLab Wiki compatible title: 'api-users-and-accounts'
    my $gitlab_wiki_title = gfmtitle('API/Users & Accounts');

    my $gfm_page = trac2gfm($tracwiki_markup);

Using the included C<trac2gfm> command line program:

    $ trac2gfm <path to tracwiki file>

Or piped to C<STDIN>:

    $ cat <trac wiki file> | trac2gfm

=head1 DESCRIPTION

This module provides functions which ease the migration of TracWiki formatted
wikis (or any other content, such as ticket descriptions, which use TracWiki
markup) to GitLab projects using GitLab Flavored Markdown (GFM).

For the most part, this module assumes that your input TracWiki text is fairly
well-formed and valid. Some concessions are made for whitespace in markup that
may not be optional in TracWiki, but which we can reliably treat as such.
However, blatant violations such as an opening C<{{{> for a pre-formatted code
block that is never followed by a closing C<}}}> will break your output.
Similar breakage can occur with horribly mis-nested emphasis markup, or wildly
malformed links.

If your TracWiki markup renders properly on a Trac wiki, this module I<should>
convert it correctly (barring any special exceptions noted below). If it does
not, please file a bug (or better yet, submit a patch)!

=head1 EXPORTED FUNCTIONS

This module does not export any functions by default. You must select the ones
you wish you use explicitly during module import. The following functions are
available for importing:

=head2 trac2gfm ($markup, $title_options)

Provided a scalar containing TracWiki markup, returns a scalar containing GFM
compliant markup. As many markup features as can be converted are, but please
note that GitLab-flavored Markdown does not support absolutely everything that
TracWiki does.

An optional hash reference of title options may be provided as the second
argument. The contents should be the same as what may be passed to C<gfmtitle>
and will be passed unaltered to that function whenever necessary. This ensures
that any internal wiki links which are converted as part of the markup
translation follow the same rules you may be using in your own direct
invocations of C<gfmtitle>.

If being performed as part of a wholesale Trac to GitLab migration (which is
probably the case), you will be responsible for updating the various internal
links which use identifiers that may have changed (ticket numbers, commit IDs,
etc.). Internal Wiki links will be corrected to use the GFM title format,
however, so as long as your entire wiki is converted using these functions, the
page references will come out intact. If you had been using Git repositories in
Trac, then your commit IDs will likely also remain the same (as that process
should be accomplished by simply switching remotes). Trac to GitLab conversions
which go from SVN to Git will require additional massaging to maintain the
C<[n]> changeset references.

Things that do get converted:

=over

=item * Paragraphs (should have gone without saying)

=item * Headings

=item * Emphasis (bold, italic, and underline; including nesting)

=item * Lists (numbered, bulleted, and lettered; latter being converted to bulleted)

=item * Pre-formatted text and code blocks

=item * Blockquotes

=item * Links

=item * TracLinks

=back

Things that do I<not> convert (at least not yet):

=over

=item * Definition Lists

=item * Tables

=back

=cut

sub trac2gfm {
    my ($trac, $title_opts) = @_;

    # To properly convert TracLinks using the same title conversions the caller
    # may be supplying when using gfmtitle directly, we need to accept the same
    # here and pass it along to any of our own invocations to that function.
    $title_opts = {} unless defined $title_opts && ref($title_opts) eq 'HASH';

    # Enforce UNIX linebreaks
    $trac =~ s{\r\n}{\n}gs;

    # Headings ('=== Foo ===' -> '### Foo')
    $trac =~ s{^(=+)([^=]+)=*$}{ ('#' x length($1)) . ' ' . _trim($2) }gme;

    # Paragraph spacing
    $trac =~ s{\n{2,}}{\n\n}gs;

    # Numbered, lettered, and bulleted lists (preserving nesting/indentation)
    $trac =~ s{^(\s*\d+)[.)\]]\s*}{$1. }gm;
    $trac =~ s{^(\s*)[a-z]+[.)\]]\s*}{$1* }gm;
    $trac =~ s{^(\s*)\*\s*([^\*]+)$}{$1* $2}gm;

    # Various forms of emphasis
    $trac =~ s{__([^\n_]+|[^\n_]+_?[^\n_]+)__}{<ul>$1</ul>}g;
    my $edge = 0;
    $trac =~ s{'''''}{ ++$edge % 2 == 1 ? '**_' : '_**' }ge;
    $trac =~ s{'''}{**}g;
    $trac =~ s{''}{_}g;

    # Preformatting blocks (including highlighter selection)
    $trac =~ s|^}}}$|```|gm;
    $trac =~ s|^{{{(?:#!(\w+))?| '```' . (defined $1 ? $1 : '') |gme;

    # In-line preformatting
    $trac =~ s/({{{|}}})/`/g;

    # CamelCase internal wiki links
    $trac =~ s{
        (^|\s) ( !? ([A-Z][a-z0-9]+){2,} ) \b
    }{
        substr($2, 0, 1) eq '!'
            ? $1 . substr($2, 1)
            : $1 . '[' . $2 . '](' . gfmtitle($2, $title_opts) . ')'
    }gxe;

    # Explicit wiki links
    $trac =~ s{
        \[wiki: ([^\s]+) \s* ([^\]]+)? \]
    }{
        my $l_title = gfmtitle($1, $title_opts);
        defined $2 && length($2) > 0
            ? '[' . $2 . '](' . $l_title . ')'
            : '[' . $l_title . '](' . $l_title . ')'
    }gmex;

    # Named URLs
    $trac =~ s{
        \[ (\w+://[^\]\s]+) \s* ([^\]]+)? \]
    }{
        defined $2 && length($2) > 0
            ? '[' . $2 . '](' . $1 . ')'
            : $1
    }gmex;

    ## Trac project links (issues, commits, users, etc.)
    # Tickets
    $trac =~ s{(?:#|ticket:|bug:)(\d+)}{#$1}g;

    # Manual linebreaks cleanup
    $trac =~ s{\n?(\[\[BR\s*\]\])+}{  }gs;

    return $trac;
}

=head2 gfmtitle ($title_string, $options)

Provided a single line string, C<$title_string>, returns a variant suitable for
use as the title of a GitLab Wiki page. Default mutations include replacement
of all whitespace and disallowed characters with dashes along with a reduction
to non-repeating kebab casing.

Some common technical terms that would otherwise render strangely within the
restrictions of GFM titles are replaced with more verbose versions (e.g. 'C++'
becomes 'c-plus-plus' instead of 'c-' as it would without special handling).

You may also pass in an optional hash reference containing the following
options to override some of the default behavior:

=over

=item * downcase

Defaults to true. Providing any false-y value will cause C<gfmtitle> to retain
the case of your input string, instead of lower-casing it.

=item * unslash

Defaults to true. Providing any false-y value will cause slashes (C</>) to be
retained in the output, instead of converting them to dashes (C<->). Note that
this can cause problems if you are committing your converted wiki pages into a
local Git repository - special care will be needed to escape the retained
slashes so that they are treated as part of the filename itself instead of as a
directory separator.

=item * terms

Allows you to supply your own special term conversions, or override any default
ones provided by this module. This is helpful in the event that your wiki uses
words or phrases which are mangled in unfortunate ways. The keys of the hashref
should be the terms (case-insensitive) as they appear in your wiki titles and
the values should be the form to which they should be converted. For example,
to keep a sane version of 'C++' in your wiki titles for GitLab (where the plus
sign is not allowed), you might do:

    gfmtitle('Languages/C++', { terms => { 'c++' => 'c-plus-plus' } });

=back

=cut

sub gfmtitle {
    my ($title, $opts) = @_;

    my $defaults = {
        downcase => 1,
        unslash  => 1,
        terms    => {},
    };

    return unless defined $title && length($title) > 0;

    # Special-case WikiStart, since TracWiki uses that as the homepage of a wiki
    # and GitLab uses 'home'.
    return 'home' if $title eq 'WikiStart';

    # Override our defaults if caller has provided anything.
    if (defined $opts && ref($opts) eq 'HASH') {
        foreach my $k (keys %{$opts}) {
            $defaults->{$k} = $opts->{$k};
        }
    }

    # Not terrifically wonderful, but some developer/tech/etc. terms that would
    # otherwise convert in very unfortunate ways. Keys are case-insensitive.
    # Values are what we'll mutate them into for GitLab wikis. These are done
    # before any other mangling, so the values don't necessarily have to be
    # perfect "GitLab" identifiers.
    my %special_terms = (
        '&'    => '-and-',
        '@'    => '-at-',
        'c++ ' => 'C-Plus-Plus',
        'a#'   => 'A-Sharp',
        'c#'   => 'C-Sharp',
        'f#'   => 'F-Sharp',
        'j#'   => 'J-Sharp',
        '.net' => '-Dot-Net',
    );

    # Add any user-supplied replacement terms.
    if (exists $defaults->{'terms'} && ref($defaults->{'terms'}) eq 'HASH') {
        $special_terms{$_} = $defaults->{'terms'}{$_} for keys %{$defaults->{'terms'}};
    }

    # GitLab wiki titles are restricted to (roughly) [a-zA-Z0-9_-/].
    # Additionally, they encourage kebab-casing in their examples.
    $title =~ s{/}{-}g  if $defaults->{'unslash'};
    $title =~ s{(^\s+|\s+$)}{}gs;
    $title =~ s{$_}{ $special_terms{$_} }ige for keys %special_terms;
    $title =~ s{[^a-zA-Z0-9/]+}{-}gs;

    if ($defaults->{'downcase'}) {
        $title =~ s{([A-Z][a-z])}{-$1}g if $title =~ m{\b([A-Z][a-z0-9]+){2,}\b}s;
        $title = lc($title);
    }

    $title =~ s{-+}{-}g;
    $title =~ s{(^-+|-+$)}{}gs;

    return $title;
}

=head1 BUGS

There are no known bugs at the time of this release. There may well be some
misfeatures, though.

Please report any bugs or deficiencies you may discover to the module's GitHub
Issues page:

L<https://github.com/jsime/text-trac2gfm/issues>

Pull requests are welcome.
=cut

sub _trim {
    my ($text) = @_;

    $text =~ s{(^\s+|\s+$)}{}ogs;

    return $text;
}

=head1 AUTHORS

Jon Sime <jonsime@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2016 by Jon Sime.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

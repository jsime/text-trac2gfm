# NAME

Text::Trac2GFM

# SYNOPSIS

As a Perl library:

    use Text::Trac2GFM qw( trac2gfm gfmtitle );

    # GitLab Wiki compatible title: 'api-users-and-accounts'
    my $gitlab_wiki_title = gfmtitle('API/Users & Accounts');

    my $gfm_page = trac2gfm($tracwiki_markup);

Using the included `trac2gfm` command line program:

    $ trac2gfm <path to tracwiki file>

# DESCRIPTION

This module provides functions which ease the migration of TracWiki formatted
wikis (or any other content, such as ticket descriptions, which use TracWiki
markup) to GitLab projects using GitLab Flavored Markdown (GFM).

For the most part, this module assumes that your input TracWiki text is fairly
well-formed and valid. Some concessions are made for whitespace in markup that
may not be optional in TracWiki, but which we can reliably treat as such.
However, blatant violations such as an opening `{{{` for a pre-formatted code
block that is never followed by a closing `}}}` will break your output.
Similar breakage can occur with horribly mis-nested emphasis markup, or wildly
malformed links.

If your TracWiki markup renders properly on a Trac wiki, this module _should_
convert it correctly (barring any special exceptions noted below). If it does
not, please file a bug (or better yet, submit a patch)!

# EXPORTED FUNCTIONS

This module does not export any functions by default. You must select the ones
you wish you use explicitly during module import. The following functions are
available for importing:

## trac2gfm

Provided a scalar containing TracWiki markup, returns a scalar containing GFM
compliant markup. As many markup features as can be converted are, but please
note that GitLab-flavored Markdown does not support absolutely everything that
TracWiki does.

Additionally, if being performed as part of a wholesale Trac to GitLab migration
(which is probably the case), you will be responsible for updating the various
internal links which use identifiers that may have changed (ticket numbers,
commit IDs, etc.). Internal Wiki links will be corrected to use the GFM title
format, however, so as long as your entire wiki is converted using these
functions, the page references will come out intact. If you had been using Git
repositories in Trac, then your commit IDs will likely also remain the same
(as that process should be accomplished by simply switching remotes). Trac to
GitLab conversions which go from SVN to Git will require additional massaging
to maintain the `[n]` changeset references.

Things that do get converted:

- Paragraphs (should have gone without saying)
- Headings
- Emphasis (bold, italic, and underline; including nesting)
- Lists (numbered, bulleted, and lettered; latter being converted to bulleted)
- Pre-formatted text and code blocks
- Blockquotes
- Links
- TracLinks

Things that do _not_ convert (at least not yet):

- Definition Lists
- Tables

## gfmtitle

Provided a single line string, returns a variant suitable for use as the title
of a GitLab Wiki page. Mutations include replacement of all whitespace and
disallowed characters with dashes along with a reduction to non-repeating
kebab casing.

Some common technical terms that would otherwise render strangely within the
restrictions of GFM titles are replaced with more verbose versions (e.g. 'C++'
becomes 'c-plus-plus' instead of 'c-' as it would without special handling).

# BUGS

There are no known bugs at the time of this release. There may well be some
misfeatures, though.

Please report any bugs or deficiencies you may discover to the module's GitHub
Issues page:

[https://github.com/jsime/text-trac2gfm/issues](https://github.com/jsime/text-trac2gfm/issues)

Pull requests are welcome.

# AUTHORS

Jon Sime <jonsime@gmail.com>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2016 by Jon Sime.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
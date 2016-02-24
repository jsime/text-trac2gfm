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

Or piped to `STDIN`:

    $ cat <trac wiki file> | trac2gfm

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

## trac2gfm ($markup, $options)

Provided a scalar containing TracWiki markup, returns a scalar containing GFM
compliant markup. As many markup features as can be converted are, but please
note that GitLab-flavored Markdown does not support absolutely everything that
TracWiki does.

An optional (though important) hash reference of options may be provided as the
second argument.

- commits

    A hash containing the mappings for any repository changeset/commit references
    in your wiki pages. This is crucial if you are migrating a project from Trac's
    Subversion module to a Gitlab project (which is, obviously, in Git). All of
    yuor SVN changesets will have been converted to Git commits. For this option,
    the keys are your original Subversion changeset numbers and the values are the
    new Git commit IDs (you may use the full hashes or the shortened ones). These
    mappings should be extracted from the output of the `git svn clone` command.

- image\_base

    A string with the base URL where any embedded or attached images are located.
    For Gitlab this will generally be https://<yourgitlabdomain>/<namespace>/<project>/uploads/<hash>
    where the domain, namespace, and project should hopefully be self-explanatory,
    and the hash is simply a randomized string. Note that this URL should map to
    the appropriate uploads directory on your Gitlab server where you have copied
    the images/attachments.

These options are used both for markup conversion as well as any necessary
title rewriting, so in addition to the keys just mentioned, you will likely
also need to pass in the options documented for `gfmtitle` below.

Things that do get converted:

- Paragraphs (should have gone without saying)
- Headings
- Emphasis (bold, italic, and underline; including nesting)
- Lists (numbered, bulleted, and lettered; latter being converted to bulleted)
- Pre-formatted text and code blocks
- Blockquotes
- Links
- TracLinks
    - Issues/Tickets
    - Changesets (including mapping SVN changeset numbers to Git commit IDs)
- Image macross (for images on the current wiki page only)
- Tables

Things that do _not_ convert (at least not yet):

- Definition Lists
- Images from anywhere other than the current wiki page
- Macros

## gfmtitle ($title\_string, $options)

Provided a single line string, `$title_string`, returns a variant suitable for
use as the title of a GitLab Wiki page. Default mutations include replacement
of all whitespace and disallowed characters with dashes along with a reduction
to non-repeating kebab casing.

Some common technical terms that would otherwise render strangely within the
restrictions of GFM titles are replaced with more verbose versions (e.g. 'C++'
becomes 'c-plus-plus' instead of 'c-' as it would without special handling).

You may also pass in an optional hash reference containing the following
options to override some of the default behavior:

- downcase

    Defaults to true. Providing any false-y value will cause `gfmtitle` to retain
    the case of your input string, instead of lower-casing it.

- unslash

    Defaults to true. Providing any false-y value will cause slashes (`/`) to be
    retained in the output, instead of converting them to dashes (`-`). Note that
    this can cause problems if you are committing your converted wiki pages into a
    local Git repository - special care will be needed to escape the retained
    slashes so that they are treated as part of the filename itself instead of as a
    directory separator.

- terms

    Allows you to supply your own special term conversions, or override any default
    ones provided by this module. This is helpful in the event that your wiki uses
    words or phrases which are mangled in unfortunate ways. The keys of the hashref
    should be the terms (case-insensitive) as they appear in your wiki titles and
    the values should be the form to which they should be converted. For example,
    to keep a sane version of 'C++' in your wiki titles for GitLab (where the plus
    sign is not allowed), you might do:

        gfmtitle('Languages/C++', { terms => { 'c++' => 'c-plus-plus' } });

# LIMITATIONS

This module makes a few concessions to sloppiness (and tolerated, though not
official, markup), but for the most part it assumes your source content in the
TracWiki markup is generally well-formed and valid.

## Tables

Tables, specifically, will face known limitations in their conversion. GFM
tables do not support row or column spanning, and cannot handle multi-line
contents in the markup (the newline will terminate the current cell's content).
As a result, complicated table markup from TracWiki pages will likely need to
be hand-wrangled after the conversion.

In addition to the lack of spanning in GFM, this converter will base the cell
alignment on the contents of the first row. While TracWiki markup allows each
cell to have its own independent alignment, GFM tables set the alignment on a
per-column basis using markup in the headers.

Headers are also mandatory in GFM tables, whereas they are optional in TracWiki.
The first row of every TracWiki table will be used as the header in the GFM
table, regardless of whether it included the `||=Foo=||` markup.

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

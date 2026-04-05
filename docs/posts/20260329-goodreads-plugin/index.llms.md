# Recently Read, Automated

A Custom Bash Plugin To Keep My Goodreads Posts Flipping

Automation

Books

Published

March 29, 2026

In the [last post](../../posts/20260328-discogs-plugin/index.llms.md), I showed off my Discogs plugin that auto-generates my *New Records* posts. The Goodreads equivalent follows the same general pattern: fetch data, diff against a local hacky NDJSON-based DB, write a Quarto post; however, the data fetching is a bit more creative, since Goodreads doesn’t have a public API (anymore!).

## Widgets and Scraping

Goodreads does still offer embeddable shelf widgets, which are served as a JavaScript file containing an HTML string assigned to a variable.

It’s not the prettiest thing in the world, but it’s something to fetch and work with:

``` numberSource
curl -sS "$GOODREADS_WIDGET" -o "$tmpdir/widget.js"
```

The widget URL encodes your shelf preferences as query parameters (number of books, sort order, which fields to show, &c).

This script uses a default URL pointed at my `read` shelf, but it can be overridden via the first argument or a `GOODREADS_WIDGET` environment variable, which means you could generate posts for other shelves like `to-be-read`, or the like.

## Extracting the HTML

The JS file looks roughly like:

``` numberSource
var widget_code = '<div>...escaped HTML...</div>'
```

First, we need to strip the JS wrapper and “unescape” the four escape patterns Goodreads uses (`\n`, `\/`, `\"`, `\'`). I had never used `sed` all that much, but it’s pretty powerful with a touch of regex:

``` numberSource
head -1 "$tmpdir/widget.js" \
  | sed "s/^[[:space:]]*var widget_code = '//; s/'[[:space:]]*$//" \
  | sed 's/\\n/\n/g' \
  | sed "s/\\\\\"/\"/g" \
  | sed "s/\\\\'/'/g" \
  | sed 's|\\\/|/|g' \
  > "$tmpdir/widget.html"
```

The whole widget is on one line, so the shorthand `head -1` pulls the entire thing. Once that line is in stdout, it’s fairly straightforward to pipe `sed` substitutions until we have readable HTML.

## Parsing the Books

Each book in the widget HTML is wrapped in a `gr_custom_each_container` div. `csplit` splits the HTML into individual files on that pattern:

``` numberSource
csplit -sz -f "$tmpdir/book_" "$tmpdir/widget.html" '/gr_custom_each_container/' '{*}'
```

Then we loop over those files and extract the pieces we need with `grep` and fancy regex:

``` numberSource
full_title=$(grep -oP '<a title="\K[^"]+' "$block" | head -1)
title=$(grep -A2 'gr_custom_title' "$block" | grep -oP '>\K[^<]+(?=</a>)' | head -1)
author=$(grep -A2 'gr_custom_author' "$block" | grep -oP '>\K[^<]+(?=</a>)' | head -1)
img=$(grep 'gr_custom_book_container' -A5 "$block" | grep -oP 'src="\K[^"]+' | head -1)
rating=$(grep -o 'gr_red_star_active' "$block" | wc -l)
```

The rating is derived by counting active star images rather than reading a numeric value; granted, it’s a little roundabout and brittle, but it works.

Each book gets written out as a line of NDJSON with `jq -nc`.

## Finding What’s New

The comparison logic here is slightly different from the Discogs plugin. There is no date field explicitly, but the data is returned by date descending, so we can rely on the order of the keys to determine what’s new. We first build a composite key for each book in both the fetched collection and the local DB, which is just the author and title joined with `||`.

``` numberSource
for f in "$l_keys" "$f_keys"; do
  sed 's/\r$//; s/[[:space:]]\+$//' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
grep -Fvxf "$l_keys" "$f_keys" > "$tmpdir/new.keys"
```

Then we trim any trailing whitespace and standardize line endings to avoid false mismatches, which allows us to do a simple `grep` to find the new keys based on line mismatches:

## Building the Post

One piece the Goodreads plugin has that Discogs doesn’t is a small helper to render a numeric rating as a Unicode star string:

``` numberSource
stars() {
  local r=$1 s=""
  for ((i=1; i<=5; i++)); do
    [ "$i" -le "$r" ] && s+="★" || s+="☆"
  done
  echo "$s"
}
```

The rest of the post-building follows the same pattern as my Discogs plugin (frontmatter, then a block per book with cover image, title, author, and stars):

``` numberSource
echo "![]($img){width=150px}"
echo "## $title"
echo "**${author}**"
echo "Rating: $star_display"
```

New books get prepended to the local NDJSON database, and off we go!

------------------------------------------------------------------------

Scraping a widget is obviously less reliable than a real API; however, the alternative is a manual solution which isn’t nearly as fun.

-CH

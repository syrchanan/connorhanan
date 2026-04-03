# New Records, Automated

A Custom Bash Plugin To Keep My Discogs Posts Spinning

Automation

Music

Published

March 28, 2026

Lately, there have been quite a few posts titled *Automated Updates*. I’ve been playing around with some bash, so those are the result of custom scripts that I am calling my blog website “plugins”.

They are generated, entirely automatically, as part of my publishing workflow – of course aside from updating my ever-expanding [Discogs collection](https://www.discogs.com/user/syrchanan/collection).

I thought it would be fun to walk through the process…

## Setup

The whole process lives in `plugins/discogs.sh`, a Bash script invoked by my top-level (and very creatively named) plugin manager `publish.sh`, which loads environment variables and fires each plugin in sequence:

``` numberSource
./discogs.sh syrchanan db
```

The script accepts two positional arguments:

1.  A Discogs username (in this case, `syrchanan`).
2.  An output directory (in this case, `db`).

It also looks for two optional environment variables:

- `DISCOGS_API_TOKEN`: A personal API token for the Discogs API, which allows for higher rate limits than the free usage allotment.
- `PAGELIM`: A limit on how many pages of collection data to fetch (each page contains 100 records, the default of 1 should be plenty for sporadic updates).

## Fetching the Collection

The [Discogs API](https://www.discogs.com/developers/#) exposes a user’s collection at `/users/{username}/collection/folders/0/releases`, sorted by date added descending.

The script iterates through the pages (up to `$PAGELIM`), writing each release as a compact JSON object to a temporary NDJSON[^1] file:

``` numberSource
jq -c '.releases[]? as $r | $r.basic_information as $b | {
  added:    $r.date_added,
  title:    $b.title,
  year:     (try ($b.year|tonumber) catch null),
  formats:  $b.formats[0],
  labels:   $b.labels[0],
  artists:  $b.artists[0],
  genres:   $b.genres,
  styles:   $b.styles,
  img:      $b.cover_image
}' "$resp" >> "$outfile"
```

This results in a file with one line per release, such that each line is a cleaned up JSON object with the fields I care about. Since the API returns your collection sorted by date descending, the newest releases are at the top of the file – a feature that becomes important for the next step.

## Looking for New Records

The local “database” is also just an NDJSON file on disk, which contains every release that has already been posted[^2]. Also, rather than comparing full objects, I build a composite key for each release, comprised of the date added, artist name, and title — joined with `||`:

``` numberSource
jq -r '[(.added // ""), ((.artists.name) // ""), (.title // "")]
  | map(gsub("\\n"; " ") | gsub("\\r"; ""))
  | join("||")' "$fetched" | sort -ur > "$f_keys"
```

Both the fetched collection and the local DB get this same format. Next, the script walks through the fetched keys from newest to oldest, writing any that don’t match the most recent local key into a `new.keys` file. It stops at the first match, which is a little fragile, but still works because everything is sorted by date descending.

If `new.keys` is empty, the script exits cleanly with no output.

## Building the Automated Post

For each new record in our newly minted `new.keys` file, we pull the full object back out of the fetched data, extracts the fields, and append a markdown block to a new Quarto document:

``` numberSource
filename="posts/auto/$(date -I)-discogs.qmd"

cat > "$filename" << QMD_HEAD
---
title: "New Records"
date: $(date -I)
categories:
  - Automated Updates
  - Music
draft: false
---
QMD_HEAD
```

Each record then gets a cover image, an H2 markdown (`##`) heading, and a markdown table with the label, year, catalog number, format, and genre:

``` numberSource
echo "![]($img){width=300px}"
echo "## $title"
echo "**$artists**"
echo "| Label  | $label |"
echo "| Year   | $year  |"
# ...&c &c
```

## Updating the Local DB

Once the post is written, the new releases get prepended to the local NDJSON database so we don’t double count any records the next time the script runs:

``` numberSource
cat "$tmpdir/updated_db.ndjson" "$local" > "$tmpdir/combined.ndjson"
mv "$tmpdir/combined.ndjson" "$local"
```

------------------------------------------------------------------------

The whole thing runs pretty quick, and produces a clean `.qmd` file; it requires nothing beyond `bash`, `curl`, and `jq`. From there, Quarto renders it into the site like any other post (with a special tag so you all can ignore them if you want).

I have a similar plugin for Goodreads that follows the same pattern — a post for another day.

-CH

## Footnotes

[^1]: NDJSON (Newline-Delimited JSON) - I chose this format because it makes it far easier to diff my local “database” with `jq` and `sort`.

[^2]: One optimization I’ve been considering is to clean up the local DB to remove all but the latest record posted, that way I can do a simpler `grep` to find where the break point is. Or, you, know, use a real sqlite DB. But I was lazy.

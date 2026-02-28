#!/usr/bin/env bash

# Usage: ./discogs.sh <username> [outdir]

set -euo pipefail

# set vars and defaults
username=${1:-}
outdir=${2:-db}
per_page=100
page=1
pageLim=${PAGELIM:-1}
token=${DISCOGS_API_TOKEN:-}

# if no username provided, print usage and exit
if [ -z "$username" ]; then
  cat <<USAGE
Usage: $0 <discogs-username> [outdir]

Environment:
  DISCOGS_API_TOKEN  (optional) Discogs personal token for authenticated requests
  PAGELIM            (optional) max pages to fetch (default: ${pageLim})

Example:
  DISCOGS_API_TOKEN=xxxx $0 syrchanan db
USAGE
  exit 1
fi

# make output and temp dir, trap to cleanup on exit
mkdir -p "$outdir"
outfile="$outdir/discogs_${username}_update.ndjson"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Writing to $outfile"
: > "$outfile"

# init totalPages to enter loop, then update
totalPages=1

# fetch pages of collection until limit hit
# starting with limit of 1 since there are 100 items per page
while [ "$page" -le "$totalPages" ]; do
  url="https://api.discogs.com/users/${username}/collection/folders/0/releases?per_page=${per_page}&page=${page}&sort=added&sort_order=desc"
  echo "Fetching page ${page} of ${totalPages}..."
  resp="$tmpdir/resp.json"

  # if there is no token passed, then try to make unauth call to api (lower rate limit)
  if [ -n "$token" ]; then
    curl -sS -H "User-Agent: DiscogsUpdateBlog/0.1" -H "Authorization: Discogs token=${token}" "$url" -o "$resp"
  else
    curl -sS -H "User-Agent: DiscogsUpdateBlog/0.1" "$url" -o "$resp"
  fi

  # bail if API message received
  msg=$(jq -r '.message // empty' "$resp") || true
  if [ -n "$msg" ]; then
    echo "API error: $msg"
    exit 1
  fi

  # get total pages from pagination (default to 1 if not present)
  totalPages=$(jq -r '.pagination.pages // 1' "$resp")

  # Convert each release to a compact object (similar shape used in the site JS)
  jq -c '.releases[]? as $r | $r.basic_information as $b | {added:$r.date_added, title:$b.title, year:(try ($b.year|tonumber) catch null), formats:$b.formats[0], labels:$b.labels[0], artists:$b.artists[0], genres:$b.genres, styles:$b.styles, img:$b.cover_image}' "$resp" >> "$outfile"

  # page++ then see if limit has been reached
  page=$((page+1))
  if [ "$page" -gt "$pageLim" ]; then
    echo "pageLim reached (${pageLim}), stopping early"
    break
  fi
  sleep 1
done

echo "Saved $(wc -l < "$outfile") releases to $outfile"

# Comparing to local DB and printing new releases

fetched=$outfile
local="$outdir/discogs_${username}_db.ndjson"
if [ ! -f "$local" ]; then
  : > "$local"
fi

# extract composite keys for comparison between fetched data and local db
# composite key is added date + artist name + title
f_keys="$tmpdir/fetched.keys"
l_keys="$tmpdir/local.keys"
jq -r '[(.added // ""), ((.artists.name) // ""), (.title // "")] | map(gsub("\\n"; " ") | gsub("\\r"; "")) | join("||")' "$fetched" | sort -ur > "$f_keys"
jq -r '[(.added // ""), ((.artists.name) // ""), (.title // "")] | map(gsub("\\n"; " ") | gsub("\\r"; "")) | join("||")' "$local" | sort -ur > "$l_keys"

echo "Comparing fetched collection ${fetched} with local DB ${local}"

# loop through mapfile of fetched keys and write out new keys until a match is reached
# IMPORTANT - this relies on sort being with most recent at the top
mapfile -t fkeys < "$f_keys"
TOMATCH=$(head -n 1 "$l_keys")
for key in "${fkeys[@]}"; do
  if [ "$key" == "$TOMATCH" ]; then
    break
  else
    echo "$key" >> "$tmpdir/new.keys"
  fi
done

# if there are no new keys, exit early
if [ ! -s "$tmpdir/new.keys" ]; then
  echo "No new releases found."
  rm -rf "$tmpdir" "$outfile"
  exit 0
fi

echo "New keys found: $(wc -l < "$tmpdir/new.keys")"
echo "Creating new post at $filename"

# create new quarto doc with frontmatter for post
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

# loop through each new key, fill markdown template and append to post content
while IFS= read -r key; do
  release=$(jq -c --arg k "$key" 'select(([(.added // ""), ((.artists.name) // ""), (.title // "")] | map(gsub("\\n"; " ") | gsub("\\r"; "")) | join("||")) == $k)' "$fetched")
  title=$(echo "$release" | jq -r '.title')
  artists=$(echo "$release" | jq -r '.artists.name' | paste -sd ", ")
  anv=$(echo "$release" | jq -r '.artists.anv // empty')
  catno=$(echo "$release" | jq -r '.labels.catno // empty')
  label=$(echo "$release" | jq -r '.labels.name // empty')
  year=$(echo "$release" | jq -r '.year // empty')
  format=$(echo "$release" | jq -r '.formats.name // empty')
  descriptions=$(echo "$release" | jq -r '.formats.descriptions // [] | join(", ")')
  genres=$(echo "$release" | jq -r '.genres // [] | join(", ")')
  img=$(echo "$release" | jq -r '.img // empty')
  added=$(echo "$release" | jq -r '.added')

  # format each release into markdown and append to post content
  {
    echo ""
    if [ -n "$img" ]; then
      echo "![]($img){width=300px}"
      echo ""
    fi
    echo "## $title"
    echo "**$artists**  "
    if [ -n "$anv" ]; then
      echo "*${anv}*"
    fi
    echo ""
    echo "| | |" 
    echo "|----------|-------|"
    [ -n "$label" ] && echo "| Label    | $label |"
    [ -n "$year" ] && echo "| Year     | $year |"
    [ -n "$catno" ] && echo "| Catalog   | $catno |"
    [ -n "$format" ] && [ -n "$descriptions" ] && echo "| Format   | $format ($descriptions) |"
    [ -n "$genres" ] && echo "| Genres   | $genres |"
    if [ -n "$added" ]; then
      pretty_added=$(date -d "$added" "+%b %d, %Y" 2>/dev/null || echo "$added")
      echo "| Added    | $pretty_added |"
    fi
    echo "<br/>"
  } >> "$filename"

  # save release to updated DB
  echo "$release" >> "$tmpdir/updated_db.ndjson"

done < "$tmpdir/new.keys"

# append footer to post content
cat <<QMD_FOOTER >> "$filename"

------------------------------------------------------------------------

*This post was automatically generated from [my Discogs collection](https://www.discogs.com/user/syrchanan/collection).*

-CH

QMD_FOOTER

# prepend new releases to local DB (newest first), then clean up all files
cat "$tmpdir/updated_db.ndjson" "$local" > "$tmpdir/combined.ndjson"
mv "$tmpdir/combined.ndjson" "$local"
rm -rf "$tmpdir" "$outfile"

exit 0
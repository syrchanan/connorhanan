#!/usr/bin/env bash

# Usage: ./goodreads.sh [widget-url] [outdir]

set -euo pipefail

DEFAULT_WIDGET="https://www.goodreads.com/review/custom_widget/98547221.Connor's%20bookshelf:%20read?cover_position=left&cover_size=medium&num_books=100&order=d&shelf=read&show_author=1&show_cover=1&show_rating=1&show_review=1&show_tags=1&show_title=1&sort=date_added&widget_bg_color=FFFFFF&widget_bg_transparent=&widget_border_width=1&widget_id=1774149908&widget_text_color=000000&widget_title_size=medium&widget_width=medium"
GOODREADS_WIDGET="${1:-$DEFAULT_WIDGET}"
outdir="${2:-db}"

mkdir -p "$outdir"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Fetching data from Goodreads..."
echo "URL: $GOODREADS_WIDGET"

# fetch the widget JS
curl -sS "$GOODREADS_WIDGET" -o "$tmpdir/widget.js"

# extract the HTML from the JS variable and unescape it
# the response has four escape patterns: \n, \/, \", \'
head -1 "$tmpdir/widget.js" \
  | sed "s/^[[:space:]]*var widget_code = '//; s/'[[:space:]]*$//" \
  | sed 's/\\n/\n/g' \
  | sed "s/\\\\\"/\"/g" \
  | sed "s/\\\\'/'/g" \
  | sed 's|\\\/|/|g' \
  > "$tmpdir/widget.html"

if [ ! -s "$tmpdir/widget.html" ]; then
  echo "Failed to extract widget HTML"
  exit 1
fi

# parse each book block into ndjson
# split on each_container divs, then extract fields
outfile="$outdir/goodreads_update.ndjson"
: > "$outfile"

# split HTML into individual book blocks
csplit -sz -f "$tmpdir/book_" "$tmpdir/widget.html" '/gr_custom_each_container/' '{*}' 2>/dev/null || true

for block in "$tmpdir"/book_*; do
  # skip blocks that don't contain a book
  grep -q 'gr_custom_title' "$block" || continue

  # full title (from the <a title="..."> in book container)
  full_title=$(grep -oP '<a title="\K[^"]+' "$block" | head -1 || echo "")

  # display title (from the title div <a> text)
  title=$(grep -A2 'gr_custom_title' "$block" | grep -oP '>\K[^<]+(?=</a>)' | head -1 || echo "")

  # author
  author=$(grep -A2 'gr_custom_author' "$block" | grep -oP '>\K[^<]+(?=</a>)' | head -1 || echo "")

  # cover image
  img=$(grep 'gr_custom_book_container' -A5 "$block" | grep -oP 'src="\K[^"]+' | head -1 || echo "")

  # rating - count active star images
  rating=$(grep -o 'gr_red_star_active' "$block" | wc -l || echo "0")
  rating=$(echo "$rating" | tr -d '[:space:]')

  # rating text from span title
  rating_text=$(grep -oP 'staticStars notranslate" title="\K[^"]+' "$block" || echo "")

  # skip if no title found
  [ -z "$title" ] && continue

  # write as ndjson
  jq -nc \
    --arg title "$title" \
    --arg full_title "$full_title" \
    --arg author "$author" \
    --arg img "$img" \
    --argjson rating "$rating" \
    --arg rating_text "$rating_text" \
    '{title:$title, full_title:$full_title, author:$author, img:$img, rating:$rating, rating_text:$rating_text}' \
    >> "$outfile"
done

count=$(wc -l < "$outfile")
echo "Parsed $count books from widget"

if [ "$count" -eq 0 ]; then
  echo "No books found in widget response."
  rm -f "$outfile"
  exit 0
fi

# Compare with local DB to find new books
local="$outdir/goodreads_db.ndjson"
if [ ! -f "$local" ]; then
  : > "$local"
fi

# composite key: author + title (preserve fetch order, no sorting)
f_keys="$tmpdir/fetched.keys"
l_keys="$tmpdir/local.keys"
jq -r '[(.author // ""), (.title // "")] | join("||")' "$outfile" > "$f_keys"
jq -r '[(.author // ""), (.title // "")] | join("||")' "$local" > "$l_keys"

echo "Comparing fetched books with local DB..."

# loop through fetched keys in order, keeping only those not in local DB
: > "$tmpdir/new.keys"
while IFS= read -r key; do
  if ! grep -qFx "$key" "$l_keys"; then
    echo "$key" >> "$tmpdir/new.keys"
  fi
done < "$f_keys"

if [ ! -s "$tmpdir/new.keys" ]; then
  echo "No new books found."
  rm -f "$outfile"
  exit 0
fi

new_count=$(wc -l < "$tmpdir/new.keys")
echo "New books found: $new_count"

# create new quarto doc
filename="posts/auto/$(date -I)-goodreads.qmd"
echo "Creating new post at $filename"

cat > "$filename" << QMD_HEAD
---
title: "Recently Read"
date: $(date -I)
categories:
  - Automated Updates
  - Books
draft: false
---
QMD_HEAD

# helper to convert rating number to stars
stars() {
  local r=$1 s=""
  for ((i=1; i<=5; i++)); do
    if [ "$i" -le "$r" ]; then
      s+="★"
    else
      s+="☆"
    fi
  done
  echo "$s"
}

# loop through new keys and build post
while IFS= read -r key; do
  release=$(jq -c --arg k "$key" 'select(([(.author // ""), (.title // "")] | join("||")) == $k)' "$outfile")
  [ -z "$release" ] && continue

  title=$(echo "$release" | jq -r '.title')
  full_title=$(echo "$release" | jq -r '.full_title // empty')
  author=$(echo "$release" | jq -r '.author')
  img=$(echo "$release" | jq -r '.img // empty')
  rating=$(echo "$release" | jq -r '.rating')

  star_display=$(stars "$rating")

  {
    echo ""
    if [ -n "$img" ]; then
      echo "![]($img){width=150px}"
      echo ""
    fi
    echo "## $title"
    if [ -n "$full_title" ] && [ "$full_title" != "$title" ]; then
      echo "*${full_title}*"
      echo ""
    fi
    echo "**${author}**"
    echo ""
    echo "Rating: $star_display"
    echo ""
    echo "<br/>"
  } >> "$filename"

  # save to updated DB
  echo "$release" >> "$tmpdir/updated_db.ndjson"

done < "$tmpdir/new.keys"

# append footer
cat <<QMD_FOOTER >> "$filename"

------------------------------------------------------------------------

*This post was automatically generated from [my Goodreads shelf](https://www.goodreads.com/review/list/98547221-connor-hanan?shelf=read).*

-CH

QMD_FOOTER

# prepend new books to local DB, then clean up
if [ -f "$tmpdir/updated_db.ndjson" ]; then
  cat "$tmpdir/updated_db.ndjson" "$local" > "$tmpdir/combined.ndjson"
  mv "$tmpdir/combined.ndjson" "$local"
fi
rm -rf "$tmpdir" "$outfile"

echo "Done! Post created at $filename"
exit 0

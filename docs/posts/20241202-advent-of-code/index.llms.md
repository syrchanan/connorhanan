# 2024 Day 2: Red-Nosed Reports

Advent of Code

Advent of Code

R

Published

December 2, 2024

Time for some [day 2](https://adventofcode.com/2024/day/2) action!

### Part 1

``` r
check_validity <- function(vec) {
    # check if vec == sort(vec) or rev(sort(vec)), we know it is asc or desc
    if ( !identical(sort(vec), vec) && !identical(rev(sort(vec)), vec) ) {
      return(0)
    }
    # if it is, subtract each from the value that comes before it
    diffs <- vec[1:length(vec)-1] - lead(vec)[!is.na(lead(vec))]
    # check all diffs are ints -3 <= x <= 3, where x != 0
    if ( all(abs(diffs) %in% c(1:3)) ) {
      return(1)
    } else {
      return(0)
    }
}
```

Since we are repeating the same operation across each input row, let’s create a function to map across each row:

- First, we need to check that all sequences are either ascending or descending – and we accomplish that by using `sort()` and `rev()`. If the input vector doesn’t match the sorted or reverse sorted vector, then we know it is out of order and can skip it. However, if it matches one of them, then we can proceed.

- The next step is to subtract each number from the one that precedes it, which we accomplish with `lead()`. It could also be done coming from the other side with `lag()`, just preference to come at it from this side. Once we have all of our diffs (and have ditched the NAs from the `lead()` shift), we can take the absolute value of each and check that they are all either 1, 2, or 3.

``` r
raw %>% 
  str_split('\\n') %>% 
  list_c() %>% 
  str_trim() %>% 
  str_split("\\s+") %>% 
  # map our function across each input row
  map(~ check_validity(as.numeric(.x))) %>% 
  list_c() %>% 
  sum()
```

    [1] 326

Now that our function is complete, all we have to do for this part is clean up the input, split on each row, and map our function across each item in the list! Since we encoded the function output as 1’s and 0’s, we can easily sum to get the count of passing rows.

⭐

### Part 2

``` r
build_shift_list <- function(vec) {

  all_variations <- list(vec)

  # for each step subset a different portion
  for (shift in 1:length(vec)) {    
    append(
      all_variations, 
      # head counts from the front, tail counts from the back
      list( c( head(vec, shift-1), tail(vec, length(vec)-shift) ) )
    ) -> all_variations
  }
  
  return(all_variations)

}
```

In part two, we have to consider each variation of the input sequence created by deleting each number from that sequence. This calls for another function, which is pretty straightforward – we first count the length of the row, and then iterate through the row, removing each number at a time (and not forgetting to include the original vector in the return list).

``` r
raw %>% 
  str_split('\\n') %>% 
  list_c() %>% 
  str_trim() %>% 
  str_split('\\s+') %>% 
  # map across each to build a list of options within the outer list
  map(~ build_shift_list(as.numeric(.x))) %>% 
  # at depth 2 (list of lists), run function from before
  map_depth(.depth = 2, check_validity) %>% 
  # summarise each sublist -- if any are 1, then count all as 1
  map(~ ifelse( any(.x == 1), 1, 0 )) %>% 
  list_c() %>% 
  sum()
```

    [1] 381

Now that that is sorted, we can do almost the exact same as for Part 1; however, we need two new lines to:

- Get our shifted lists, which will create a hierarchy of lists

  - ex: `[ [1, 2, 3], [2, 3], [1, 3], [1, 2] ]`

- Map our first function across those sublists (which are depth 2 on our traversal tree)

Easy enough!

⭐

------------------------------------------------------------------------

Perhaps we mix up the language for tomorrow?

-CH

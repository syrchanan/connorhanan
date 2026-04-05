# 2024 Day 1: Historian Hysteria

Advent of Code

Advent of Code

OJS

R

Published

December 1, 2024

Let’s get started with [day 1](https://adventofcode.com/2024/day/1)!

Today, after reading the problem, I feel like OJS will be easiest to handle all of these lists, so without further ado, let’s begin:

### Part 1

``` js
{
  const parsed = raw.split('\n')
      .map(d => {
        return d.trimStart()
                .replace(/\s+/, '|')
                .split('|')
                .map(d => +d)
      })

  return parsed.map((d, i, me) => {
      const diff = me.map(elem => elem[0]).sort()[i] - 
                   me.map(elem => elem[1]).sort()[i]
      return diff < 0 ? diff * -1 : diff
    }).reduce((nxt, acc) => nxt + acc, 0)
}
```

First we need to parse out the input. I split on each newline, and used some regex to replace all the extra whitespace between the numbers with a delimeter, making splitting it into arrays quite simple.

However, we need to map across the arrays and find the paired difference between the elements - after sorting - which I chose to do in one step using the `this` property of arrays when mapping.

A simple conditional brings us home to our first star of the year!

Just for fun, let’s do the same in R:

``` r
raw %>% 
  str_split("\\n") %>% 
  .[[1]] %>% 
  map(str_squish) %>% 
  map(~ str_split(.x, " ")) %>%
  list_flatten() -> parsed

parsed %>% 
  map(~ as.numeric(.x[[1]])) %>% 
  list_c() %>% 
  sort() %>% 
  tibble(part_1 = .) %>% 
  bind_cols({
    parsed %>% 
      map(~ as.numeric(.x[[2]])) %>% 
      list_c() %>% 
      sort() %>% 
      tibble(part_2 = .)
  }) -> clean_data

clean_data %>% 
  mutate(diff = abs(part_2 - part_1)) %>% 
  summarise(total = sum(diff)) %>% 
  pull(total)
```

    [1] 2164381

Similar strategy as the OJS - parse the input and map across each set separately. However, this time, we’ll be taking advantage of the dataframe system in R, doing our calculations across columns, since the two lists are the same lengths.

⭐

### Part 2

So for this part, we are tasked with counting the appearances of the first number list in the second, then multiplying across:

``` js
{
  const parsed = raw.split('\n')
      .map(d => {
        return d.trimStart()
                .replace(/\s+/, '|')
                .split('|')
                .map(d => +d)
      })
  
  const part_1 = parsed.map(d => d[0])
  const part_2 = parsed.map(d => d[1])
  
  return part_1.reduce((acc, nxt) => {
    return acc + nxt * ( part_2.filter(elem => elem === nxt).length )
  }, 0)
}
```

Not too bad of a solution, just copied/pasted the parsing from above, and actually split it into two arrays now instead of doing it all at once. That way, a basic accumulation across the first array (which we are treating as the ‘keys’ in this case), nets us our answer. Another way to do it would be create an object from list \#2, with each number as a key and each count as a value, which would eliminate the repeating lookups.

And again in R:

``` r
parsed %>% 
  map(~ as.numeric(.x[[1]])) %>% 
  list_c() %>% 
  sort() %>% 
  tibble(part_1 = .) %>% 
  left_join({
    parsed %>% 
      map(~ as.numeric(.x[[2]])) %>% 
      list_c() %>% 
      sort() %>% 
      tibble(part_2 = .) %>% 
      count(part_2)
  }, join_by(part_1 == part_2)) %>% 

  mutate(prod = part_1 * n) %>% 
  summarise(total = sum(prod, na.rm = T)) %>% 
  pull(total)
```

    [1] 20719933

Easy enough – just need to join the groups together into a dataframe rather than binding columns straight across. This way, the summarised totals will dupe themselves as needed per number.

⭐

------------------------------------------------------------------------

Not too hard for day 1…

-CH

# 2024 Day 3: Mull it Over

Advent of Code

Advent of Code

OJS

Published

December 3, 2024

Back for [day 3](https://adventofcode.com/2024/day/3)!

### Part 1

Hopping back in OJS for today, felt like the regex is more natural to do in OJS than R.

``` js
{
  return [...raw.matchAll(/mul\(\d+,\d+\)/g)]
    .reduce((acc, nxt) => {
      const nums = [...nxt[0].matchAll(/\d+/g)].map(elem => +elem[0])
      return (nums[0] * nums[1]) + acc
    }, 0)
}
```

The first part here is pretty quick – we take our input and use regex to extract all `mult(#, #)` patterns in the string. Once we have all those extracted, all we have to do is pull out the numbers and multiply them together, and reduce to get our final answer.

Not too shabby.

⭐

### Part 2

In part 2, we have to only calculate the `mult()` tags that come after a `do()` instruction, but not after `don't()` tags.

The first cell below was my initial attempt to get the answer, but after thinking through my process, I was able to refactor and simplify it WAY down.

``` js
{
  const instructions = [...raw.matchAll(/mul\(\d+,\d+\)|do\(\)|don\'t\(\)/g)]
      .map(d => d[0])

  let enable = true // set flag
  
  return instructions.reduce( (acc, nxt) => {
      if ( /do\(\)/.test(nxt) ) { // matches do()
        enable = true
        return acc
      } else if ( /don\'t\(\)/.test(nxt) ) { // matches don't()
        enable = false
        return acc
      } else { // matches mult
        if (enable) { // if enabled add
          const nums = [...nxt.matchAll(/\d+/g)]
              .map(elem => +elem[0])
          return (nums[0] * nums[1]) + acc
        } else { // otherwise skip
          return acc
        }
      }
    }, 0)
}
```

First up, the long solution. I basically modified the Part 1 regex to also extract all `do()` and `don't()` tags, as well as `mult()`.

Then, all we have to do is keep an `enable` boolean flag in memory, and as we map across the extracted commands, toggle it as needed. This way, we can skip all the unneeded `mult()`s and just sum up the products that we need.

``` js
{
  const cleaned_input = raw
      .replaceAll(/\n|\r/g, '')
      .replaceAll( /\n|don\'t\(\).*?do\(\)|don\'t\(\).*/g, '')
  return [...cleaned_input.matchAll(/mul\(\d+,\d+\)/g)]
      .reduce((acc, nxt) => {
        const nums = [...nxt[0].matchAll(/\d+/g)]
            .map(elem => +elem[0])
        return (nums[0] * nums[1]) + acc
      }, 0)
}
```

In a much cleaner (and quicker?) solution, I realized I could remove all the `don't()...do()` instruction sets. Notably, this includes the special case of an unbounded `don't()` tag – the very last one that does not have a `do()` after it.

This way, the input is as clean as Part 1, and we can apply the same solution – extracting and mapping across the resultant `mult()` tags.

Keen eyes might notice an extra line removing all line breaks and carriage returns. They were causing issues with some `don't()` tags not allowing the regex to carry into the next line, so adios to those!

⭐

------------------------------------------------------------------------

-CH

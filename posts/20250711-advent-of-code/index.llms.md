# 2024 Day 9: Disk Fragmenter

Advent of Code

Advent of Code

OJS

Published

July 11, 2025

[Day 9](https://adventofcode.com/2024/day/9)!

### Part 1

To begin, we need a function that will let us partition our disk based on the rules of the problem. In the input, numbers alternate between being a file or being free space, so we need to split up which are which with an odd/even split:

``` js
function partition(disk_map) {
  const disk = []
  // for all numbers
  for (let i = 0; i < disk_map.length; i++) {
    // even case
    if (i % 2 === 0) {
      // file, repeat number
      for (let j = 0; j < disk_map[i]; j++) disk.push( String(i / 2) )
    //odd case
    } else {
      // spacer, print "." instead
      for (let k = 0; k < disk_map[i]; k++) disk.push('.')
    }
  }
  return disk
}
```

Now that we are actually able to build out what the disk looks like, it gets a whole lot easier to solve, especially if we work backwards. Working forwards, we would keep expanding the string, and our indices would be off; however, by working backwards, we can insert whatever we want and still keep track of where we are in the string.

With that in mind, it’s really not difficult – we just map through the empty spaces, and fill with whatever needs to go there!

``` js
part_1 = {

  // partition disk into array of pieces
  const disk = partition(raw)

  // work backwards
  for (let i = disk.length - 1; i >= 0; i--) {

    // get index of next spacer in seq
    const next_space = disk.indexOf('.')
    
    // if next digit is a '.' or if index is below last '.' in array
    if (disk[i] === '.') {
      continue // skip
    }

    // if no more spacers before our current position
    if (next_space > i) {
      break // exit early to avoid cycling through a bunch of continue reps
    }

    // replace that position with the digit we are on
    disk[next_space] = disk[i]

    // replace with '.' to mark it is now empty
    disk[i] = '.'
    
  }
  
  return disk.reduce((acc, nxt, i) => {
    return nxt === '.' ?
      acc :
      acc + Number(nxt)*i
  }, 0)
}
```

``` js
part_1
```

⭐

### Part 2

In part 2, we can no longer move one file (character in our string) at a time – we have to move whole blocks at once. While this may seem daunting, it’s fairly similar to what we did before, but instead of iterating through characters, we are now going to iterate through blocks.

To make this easier, let’s first parse the input a little more than before, and create an object with the blocks, and empty arrays as our spacers. That way, as we iterate through, we can dump the blocks into available spacers all by manipulating our arrays.

``` js
part_2 = {
  const disk_map = raw.split("").map(Number)

  // split into blocks and empty array spacers
  const disk = {
    blocks: disk_map.filter( (d, i) => i % 2 === 0 ).map( (d, i) => [d, i]),
    spacers: disk_map.filter( (d, i) => i % 2 !== 0 ).map( (d, i) => [d, []])
  }
  
  // going backwards (without doing the last one, as that will lead our array)
  for (let i = disk.blocks.length - 1; i > 0; i--) {
    
    // go through gaps up to the backwards run
    for (let j = 0; j < i; j++) {

      // check if block space is <= available spacer size 
      if (disk.blocks[i][0] <= disk.spacers[j][0]) {
        
        // decrement the space counter
        disk.spacers[j][0] -= disk.blocks[i][0]

        // fill space with block
        disk.spacers[j][1].push( 
            ...new Array(disk.blocks[i][0]).fill(disk.blocks[i][1]) 
        )

        // replace block empty char
        disk.blocks[i][1] = "."

        // exit because slot found for block
        break
      } // no else statement since we want to leave as-is if no space
    }
  }

  // output arr
  const defrag = []

  // build output arr
  for (let i = 0; i < disk.spacers.length; i++) {

    // push block
    defrag.push(...new Array(disk.blocks[i][0])
               .fill(disk.blocks[i][1]) )

    // push spacer fill
    defrag.push(...disk.spacers[i][1])

    // push remaining unfilled spacers
    defrag.push(...new Array(disk.spacers[i][0]).fill(".") )
    
  }

  return defrag.reduce((acc, nxt, i) => nxt === '.' ? acc : acc + nxt*i, 0)
}
```

``` js
part_2
```

⭐

------------------------------------------------------------------------

The hardest part here was deciding to work backwards through the disk. Initially, I took a recursive-heavy approach to work forwards, and that became a pain fast. The good news is, other days benefit from this reversed approach, so it was a good reminder to keep it as an option.

-CH

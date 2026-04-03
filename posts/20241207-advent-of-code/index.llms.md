# 2024 Day 7: Bridge Repair

Advent of Code

Advent of Code

OJS

Published

December 7, 2024

[Day 7](https://adventofcode.com/2024/day/7)!

``` js
input = {
  const clean = raw.split("\n")
  clean.pop()

  return clean.map(d => {
    const parsed = [...d.matchAll(/\d+/g)].map(elem => elem[0])
    return {
      target: +parsed[0].slice(),
      operands: parsed.slice(1).map(elem => +elem)
    }
  })
}
```

### Part 1

In this puzzle, we are given a bunch of numbers, and have to figure out how to reach the result by different operations. Those pesky elves stole all the operators!

``` js
// go backwards along input -- if mod div === 0 then it's multiply, else add
check_eq_step = (target, operands) => {
  // final check
  if (operands.length === 1) return operands[0] === target

  // see if div by last factor
  const div = target % operands[0] === 0
  // see if subtractable by last factor
  const sub = target >= operands[0]

  // if can't divide or subtract evenly then fail upwards
  if (!div && !sub) return false

  return (
    // div case
    (div && check_eq_step(  target / operands[0], operands.slice(1) )) ||
    // sub case
    (sub && check_eq_step( target - operands[0], operands.slice(1) ))
  )
}
```

I first thought of trying to work through the equation recursively, left to right, but it quickly expanded into so many possible routes of combinations. After a while of tinkering, I landed on the above – working backwards through the equation. I realized that if the operation doesn’t cleanly work, then it’s invalid, and we can trim that route of options.

This way, we can prune the options as we go, without having to calculate to the end of the equation. For example, if we know the result is 200, and we know the last number in the equation is 201, we know the calculation is impossible because (a) 200 / 201 is not an integer, and (b) 200 - 201 is negative. Therefore, with one check, we can toss the whole equation, instead of only realizing it at the end!

``` js
input.filter(d => check_eq_step(d.target, d.operands.slice().reverse()))
    .reduce((acc, nxt) => {
      return acc + nxt.target
    }, 0)
```

Once we have our function, it’s as easy as recursively applying it across the equation, and accumulating the result.

⭐

### Part 2

In part 2, we now have to worry about string concatenation as a possible operator, instead of only multiplication and addition.

``` js
// go backwards again, but add check for string end
check_eq_step_2 = (target, operands) => {
  // final check
  if (operands.length === 1) return operands[0] === target

  // see if div by last factor
  const div = target % operands[0] === 0
  // see if subtractable by last factor
  const sub = target >= operands[0]
  // see if concat happened
  const cat = String(target).endsWith(operands[0])

  // if can't divide or subtract evenly then fail upwards
  if (!div && !sub && !cat) return false
  
  return (
    // div case
    (div && check_eq_step_2( target / operands[0], operands.slice(1) )) ||
    // sub case
    (sub && check_eq_step_2( target - operands[0], operands.slice(1) )) ||
    // concat case
    (cat && check_eq_step_2( Number(String(target).slice(0, -String(operands[0]).length)), 
                             operands.slice(1) ))
  )
}
```

However, this ends up being not too bad, as we can add an extra recursive step, and check the result and operator via slicing. For example, if the target is 156, and our operand is 6, then we have a match, since that would leave us with 15 (still working backwards here).

``` js
input.filter(d => check_eq_step_2(d.target, d.operands.slice().reverse()))
  .reduce((acc, nxt) => {
    return acc + nxt.target
  }, 0)
```

With that little adjustment, we are all set!

⭐

------------------------------------------------------------------------

Not too bad once you recognize going backwards will prune your sample space.

-CH

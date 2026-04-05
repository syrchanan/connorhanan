# 2024 Day 5: Print Queue

Advent of Code

Advent of Code

OJS

Published

December 5, 2024

[Day 5](https://adventofcode.com/2024/day/4)!

### Part 1

Let’s jump in – today’s parts are both quite similar.

``` js
{
  const input = raw.split("\n\n").map(d => d.split("\n"))
  
  const pages = {
    numbers: new Set(), // unique pages
    orders: new Map() // page => before
  }
  
  // add all inputs to set & map
  input[0].reduce(({numbers, orders}, nxt) => {
    const [from, to] = nxt.match(/(\d+)|(\d+)/g)
    numbers.add(+from)
    numbers.add(+to)
    orders.set( +from, (orders.get(+from) || new Array()).concat(+to) )
    return pages
  }, pages)

  // clean up all books
  const updates = input[1].map(d => d.split(",").map(elem => +elem))

  // custom sort function
  const page_sort = (update, order) => {
    return update.slice().sort((a, b) => order.get(b)?.includes(a) ? 1 : -1)
  }

  // see if all are in order, if yes, then sum middle numbers
  return updates
    .filter((d) => {
      return d.every((elem, i) => elem === page_sort(d, pages.orders)[i])
    })
    .map((d) => d[(d.length - 1)/2])
    .reduce((acc, nxt) => acc + nxt, 0)
}
```

For the first part, the parsing was the most diffcult part. And by difficult, I just mean more involved than usual – I opted to read it all into one object that has both a Set and a Map. This is my standard read option when we have ordering in the input. The set will give us all unique options, and the Map will maintain orderings and relationships, which comes in great use for this part.

To start, we have to use all the page numbering rules to check the orders of the updates (which I will call books going forward, since it flows better). This is fairly easy, all we have to do is sort the pages in each book using our custom comparator, then make sure that that array matches the initial array. All we have to do then is filter on those books that pass the test, extract their middle number (thankfully all of them are odd in length), and sum!

⭐

### Part 2

Part 2 was one of the easiest by far – all we have to do is negate our comparator function results. This time, we only want to keep the ones that are out of order, sort them, then pull out the middle numbers and sum!

``` js
{
  const input = raw.split("\n\n").map(d => d.split("\n"))

  const pages = {
    numbers: new Set(),
    orders: new Map()
  }
  
  input[0].reduce(({numbers, orders}, nxt) => {
    const [from, to] = nxt.match(/(\d+)|(\d+)/g)
    numbers.add(+from)
    numbers.add(+to)
    orders.set( +from, (orders.get(+from) || new Array()).concat(+to) )
    return pages
  }, pages)

  const updates = input[1].map(d => d.split(",").map(elem => +elem))

  const page_sort = (update, order) => {
    return update.slice().sort((a, b) => order.get(b)?.includes(a) ? 1 : -1)
  }

  // negate the every() statement from part 1
  return updates
    .filter((d) => {
      return !d.every((elem, i) => elem === page_sort(d, pages.orders)[i])
    })
    // sort then count since they are in wrong order
    .map(d => page_sort(d, pages.orders))
    .map((d) => d[(d.length - 1)/2])
    .reduce((acc, nxt) => acc + nxt, 0)
}
```

⭐

------------------------------------------------------------------------

-CH

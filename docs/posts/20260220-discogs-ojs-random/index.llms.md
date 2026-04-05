# Discogs Randomizer

Don’t know what to listen to? Let the randomizer decide for you!

OJS

Music

Published

February 20, 2026

This tool will import your discogs collection and offer a randomized selection of which record to play, with filters for your convenience.

Enter username below (case-sensitive) to get started.\*

\*Please note it may take up to a minute to load your collection depending on size.

``` js
viewof username = guard(
  ({ template }) => Inputs.form(
    {
      username: Inputs.text({ label: 'Discogs Username: ', required: true, placeholder: 'e.g., syrchanan' })
    },
    { template }
  ),
  { resetLabel: "Reset to Previous", required: true, resubmit: false }
)

md`## Filters`
```

``` js
viewof filters = guard(
  ({ template }) => Inputs.form(
    {
      year: interval(
        d3.extent(cleanCollection.map(d => d.year > 0 ? d.year : null)), 
        {label: 'Year', step: 1, value: 0, disabled: !username.username}
      ),
      label: Inputs.search(
        new Set(cleanCollection.map(d => d?.labels?.name)),
        {label: md`Record Label <br/> (leave empty to include all)`, disabled: !username.username}
      )
    },
    { template }
  ),
  { 
    submitLabel: "Reroll",
    resetLabel: "Reset to Previous", 
    required: false, 
    resubmit: true
  }
)
```

``` js
{

  // reload on username.submit
  username
  
  if (!username.username) return md``
  
  // retrigger on button press
  filters.reroll

  // subsetting and TODO markdown output
  let subset = cleanCollection.filter(d => {
    return (d.year >= filters.year[0] && d.year <= filters.year[1]) && 
      (filters.label.includes(d?.labels?.name))
  })

  let record = getRandomItem(subset)

  return !record ? md`
  <br/>
  Invalid filters resulted in an empty search. 
  <br/> 
  Please adjust and try again.` :

  md`
<br/>
<br/>
Your selection is...
<br/>
<br/>

## ${record.title}
**${record.artists.name}**  
${record.artists.anv ? `*${record.artists.anv}*` : ''}

<div style="
  display: flex;
  flex-wrap: wrap;
  gap: 2rem;
  align-items: flex-start;
  flex-direction: row;
">
  <div style="flex: 0 0 300px; min-width: 150px; text-align: center;">
    <img src="${record.img}" alt="${record.title}" style="height:300px;object-fit:contain;max-width:100%;">
  </div>
  <div style="flex: 1 1 300px; min-width: 250px; max-width: 400px;">
    <table>
      <tr><th style='text-align:left;'>Year</th><td>${record.year}</td></tr>
      <tr><th style='text-align:left;'>Label</th><td>${record.labels.name} · Cat# ${record.labels.catno}</td></tr>
      <tr><th style='text-align:left;'>Format</th><td>${record.formats.name} (${record.formats.descriptions.join(', ')})</td></tr>
      <tr><th style='text-align:left;'>Genre</th><td>${record.genres?.join(', ') ?? '—'}</td></tr>
      <tr><th style='text-align:left;'>Style</th><td>${record.styles?.join(', ') ?? '—'}</td></tr>
    </table>
  </div>
</div>
<style>
@media (max-width: 700px) {
  div[style*="display: flex"] {
    flex-direction: column !important;
    gap: 1rem !important;
  }
}
table th, table td {
  padding: 0.5em 1.5em 0.5em 0.5em;
}
</style>
`
}
```

``` js
function guard(fn, options = {}) {
  const {
    submitLabel = "Submit",
    resetLabel = "Reset",
    required = false,
    resubmit = true,
    width = "fit-content",
    justify = "start",
    valid = input => !input.querySelector(":invalid"),
  } = options;

  const onSubmit = () => {
    value = input.value;
    submit.disabled = !resubmit || invalid;
    reset.disabled = true;
    wrapper.dispatchEvent(new Event("input", { bubbles: true }));
  };
  const onReset = () => {
    input.value = value;
    submit.disabled = !resubmit || invalid;
    reset.disabled = true;
  };
  const onInnerInputCapture = () => {
    invalid = true;
    submit.disabled = true;
  };
  const onInnerInput = e => {
    e.stopPropagation();
    invalid = !valid(input);
    submit.disabled = invalid ? true : false;
    reset.disabled = false;
  };
  
  const submit = htl.html`<button ${{disabled: !resubmit && !required, onclick: onSubmit}}>${submitLabel}`;
  const reset = htl.html`<button ${{disabled: true, onclick: onReset}}>${resetLabel}`;
  const footer = htl.html`<div><hr style="padding:0;margin:10px 0"><div style="display:flex;gap:1ch;justify-content:${justify}">${submit} ${reset}`;
  const template = inputs => htl.html`<div>${
    Array.isArray(inputs) ? inputs : Object.values(inputs)
  }${footer}`;
  
  const input = fn({submit, reset, footer, template, onSubmit, onReset});
  let invalid = !!input.querySelector(":invalid");
  submit.disabled = !resubmit || invalid;

  input.addEventListener("input", onInnerInputCapture, {capture: true});
  input.addEventListener("input", onInnerInput);
  let value = required ? undefined : input.value;
  const wrapper = htl.html`<div style="width:${width}">${input}`;
  wrapper.addEventListener("submit", onSubmit);
  return Object.defineProperty(wrapper, "value", {
    get: () => value,
    set: (v) => { input.value = v },
  });
}

function interval(range = [], options = {}) {
  const [min = 0, max = 1] = range;
  const {
    step = .001,
    label = null,
    value = [min, max],
    format = ([start, end]) => `${start} … ${end}`,
    color,
    width = 360,
    theme,
    __ns__ = randomScope(),
  } = options;

  const css = `
#${__ns__} {
  font: 13px/1.2 var(--sans-serif);
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  max-width: 100%;
  width: auto;
}
@media only screen and (min-width: 30em) {
  #${__ns__} {
    flex-wrap: nowrap;
    width: ${cssLength(width)};
  }
}
#${__ns__} .label {
  width: 120px;
  padding: 5px 0 4px 0;
  margin-right: 6.5px;
  flex-shrink: 0;
}
#${__ns__} .form {
  display: flex;
  width: 100%;
}
#${__ns__} .range {
  flex-shrink: 1;
  width: 100%;
}
#${__ns__} .range-slider {
  width: 100%;
}
  `;
  
  const $range = rangeInput({min, max, value: [value[0], value[1]], step, color, width: "100%", theme});
  const $output = html`<output>`;
  const $view = html`<div id=${__ns__}>
${label == null ? '' : html`<div class="label">${label}`}
<div class=form>
  <div class=range>
    ${$range}<div class=range-output>${$output}</div>
  </div>
</div>
${html`<style>${css}`}
  `;

  const update = () => {
    const content = format([$range.value[0], $range.value[1]]);
    if(typeof content === 'string') $output.value = content;
    else {
      while($output.lastChild) $output.lastChild.remove();
      $output.appendChild(content);
    }
  };
  $range.oninput = update;
  update();
  
  return Object.defineProperty($view, 'value', {
    get: () => $range.value,
    set: ([a, b]) => {
      $range.value = [a, b];
      update();
    },
  });
}

function rangeInput(options = {}) {
  const {
    min = 0,
    max = 100,
    step = 'any',
    value: defaultValue = [min, max],
    color,
    width,
    theme = theme_Flat,
  } = options;
  
  const controls = {};
  const scope = randomScope();
  const clamp = (a, b, v) => v < a ? a : v > b ? b : v;

  // Will be used to sanitize values while avoiding floating point issues.
  const input = html`<input type=range ${{min, max, step}}>`;
  
  const dom = html`<div class=${`${scope} range-slider`} style=${{
    color,
    width: cssLength(width),
  }}>
  ${controls.track = html`<div class="range-track">
    ${controls.zone = html`<div class="range-track-zone">
      ${controls.range = html`<div class="range-select" tabindex=0>
        ${controls.min = html`<div class="thumb thumb-min" tabindex=0>`}
        ${controls.max = html`<div class="thumb thumb-max" tabindex=0>`}
      `}
    `}
  `}
  ${html`<style>${theme.replace(/:scope\b/g, '.'+scope)}`}
</div>`;

  let value = [], changed = false;
  Object.defineProperty(dom, 'value', {
    get: () => [...value],
    set: ([a, b]) => {
      value = sanitize(a, b);
      updateRange();
    },
  });

  const sanitize = (a, b) => {
    a = isNaN(a) ? min : ((input.value = a), input.valueAsNumber);
    b = isNaN(b) ? max : ((input.value = b), input.valueAsNumber);
    return [Math.min(a, b), Math.max(a, b)];
  }
  
  const updateRange = () => {
    const ratio = v => (v - min) / (max - min);
    dom.style.setProperty('--range-min', `${ratio(value[0]) * 100}%`);
    dom.style.setProperty('--range-max', `${ratio(value[1]) * 100}%`);
  };

  const dispatch = name => {
    dom.dispatchEvent(new Event(name, {bubbles: true}));
  };
  const setValue = (vmin, vmax) => {
    const [pmin, pmax] = value;
    value = sanitize(vmin, vmax);
    updateRange();
    // Only dispatch if values have changed.
    if(pmin === value[0] && pmax === value[1]) return;
    dispatch('input');
    changed = true;
  };
  
  setValue(...defaultValue);
  
  // Mousemove handlers.
  const handlers = new Map([
    [controls.min, (dt, ov) => {
      const v = clamp(min, ov[1], ov[0] + dt * (max - min));
      setValue(v, ov[1]);
    }],
    [controls.max, (dt, ov) => {
      const v = clamp(ov[0], max, ov[1] + dt * (max - min));
      setValue(ov[0], v);
    }],
    [controls.range, (dt, ov) => {
      const d = ov[1] - ov[0];
      const v = clamp(min, max - d, ov[0] + dt * (max - min));
      setValue(v, v + d);
    }],
  ]);
  
  // Returns client offset object.
  const pointer = e => e.touches ? e.touches[0] : e;
  // Note: Chrome defaults "passive" for touch events to true.
  const on  = (e, fn) => e.split(' ').map(e => document.addEventListener(e, fn, {passive: false}));
  const off = (e, fn) => e.split(' ').map(e => document.removeEventListener(e, fn, {passive: false}));
  
  let initialX, initialV, target, dragging = false;
  function handleDrag(e) {
    // Gracefully handle exit and reentry of the viewport.
    if(!e.buttons && !e.touches) {
      handleDragStop();
      return;
    }
    dragging = true;
    const w = controls.zone.getBoundingClientRect().width;
    e.preventDefault();
    handlers.get(target)((pointer(e).clientX - initialX) / w, initialV);
  }
  
  
  function handleDragStop(e) {
    off('mousemove touchmove', handleDrag);
    off('mouseup touchend', handleDragStop);
    if(changed) dispatch('change');
  }
  
  invalidation.then(handleDragStop);
  
  dom.ontouchstart = dom.onmousedown = e => {
    dragging = false;
    changed = false;
    if(!handlers.has(e.target)) return;
    on('mousemove touchmove', handleDrag);
    on('mouseup touchend', handleDragStop);
    e.preventDefault();
    e.stopPropagation();
    
    target = e.target;
    initialX = pointer(e).clientX;
    initialV = value.slice();
  };
  
  controls.track.onclick = e => {
    if(dragging) return;
    changed = false;
    const r = controls.zone.getBoundingClientRect();
    const t = clamp(0, 1, (pointer(e).clientX - r.left) / r.width);
    const v = min + t * (max - min);
    const [vmin, vmax] = value, d = vmax - vmin;
    if(v < vmin) setValue(v, v + d);
    else if(v > vmax) setValue(v - d, v);
    if(changed) dispatch('change');
  };
  
  return dom;
}

cssLength = v => v == null ? null : typeof v === 'number' ? `${v}px` : `${v}`

html = htl.html

function randomScope(prefix = 'scope-') {
  return prefix + (performance.now() + Math.random()).toString(32).replace('.', '-');
}

theme_Flat = `
/* Options */
:scope {
  color: #3b99fc;
  width: 240px;
}

:scope {
  position: relative;
  display: inline-block;
  --thumb-size: 15px;
  --thumb-radius: calc(var(--thumb-size) / 2);
  padding: var(--thumb-radius) 0;
  margin: 2px;
  vertical-align: middle;
}
:scope .range-track {
  box-sizing: border-box;
  position: relative;
  height: 7px;
  background-color: hsl(0, 0%, 80%);
  overflow: visible;
  border-radius: 4px;
  padding: 0 var(--thumb-radius);
}
:scope .range-track-zone {
  box-sizing: border-box;
  position: relative;
}
:scope .range-select {
  box-sizing: border-box;
  position: relative;
  left: var(--range-min);
  width: calc(var(--range-max) - var(--range-min));
  cursor: ew-resize;
  background: currentColor;
  height: 7px;
  border: inherit;
}
/* Expands the hotspot area. */
:scope .range-select:before {
  content: "";
  position: absolute;
  width: 100%;
  height: var(--thumb-size);
  left: 0;
  top: calc(2px - var(--thumb-radius));
}
:scope .range-select:focus,
:scope .thumb:focus {
  outline: none;
}
:scope .thumb {
  box-sizing: border-box;
  position: absolute;
  width: var(--thumb-size);
  height: var(--thumb-size);

  background: #fcfcfc;
  top: -4px;
  border-radius: 100%;
  border: 1px solid hsl(0,0%,55%);
  cursor: default;
  margin: 0;
}
:scope .thumb:active {
  box-shadow: inset 0 var(--thumb-size) #0002;
}
:scope .thumb-min {
  left: calc(-1px - var(--thumb-radius));
}
:scope .thumb-max {
  right: calc(-1px - var(--thumb-radius));
}
`
```

``` js
sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms))
```

``` js
getRandomItem = (arr) => arr[Math.floor(Math.random() * arr.length)]
```

``` js
pageLim = 30
```

``` js
cleanCollection = {
  
  let page = 1;
  let releases = [];
  let totalPages = 1;

  // reload on username
  username
  
  if (!username.username) return []

  do {
    const response = await fetch(
      `https://api.discogs.com/users/${username.username}/collection/folders/0/releases?per_page=100&page=${page}&sort=added&sort_order=desc`,
      { 
        headers: { 
        "User-Agent": "DiscogsSuggestedPlay/0.1", 
        "Authorization": `Discogs token=${DISCOGS_API_TOKEN}` } 
      }
    )
    const data = await response.json()
    console.log(data?.message || `Parsing Collection Page: ${page}/${totalPages}`)
    if (data?.message) {
      throw new Error(`${data.message}`)
    }
    totalPages = data.pagination.pages
    releases = releases.concat(data.releases)
    page++
    if (page >= pageLim) {
      console.log('pageLim reached, stopping early')
      break
    }
    await sleep(1000)
  } while (page <= totalPages)
  
  return releases.map(d => {
    return {
      title: d.basic_information?.title,
      year: +d.basic_information?.year,
      formats: d.basic_information?.formats[0],
      labels: d.basic_information?.labels[0],
      artists: d.basic_information?.artists[0],
      genres: d.basic_information?.genres,
      styles: d.basic_information?.styles,
      img: d.basic_information?.cover_image
    }
  })
}
```

------------------------------------------------------------------------

Inspired by Real_gone_daddy45’s trove - hopefully this should solve any music indecision!

-CH

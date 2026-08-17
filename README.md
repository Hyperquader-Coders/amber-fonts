# amber-fonts

The typeface the **Amber Linux** suite draws with, packaged once.

There is no code here. This repository exists because [copal](../copal),
[kat800](../kat800) and [amberlin](../amberlin) each carried their own copy of
the same font, and two packages owning the same file cannot be installed
together.

## Why the suite ships a font at all

No Debian package carries the Nerd Fonts patch. Without this one, a fresh
install renders in whatever Pango picks instead of the face the applications
were designed for — a fallback that is invisible in the code and obvious on
screen.

It is also load-bearing for how the suite looks. An answer in Amberlin and the
same note on Copal's board are one object: they share a silhouette derived from
the note's Ambrosia id, and they have to share a letterform too, or the text
undoes what the shape achieves.

## Two families, not interchangeable

| Family | Icons | Used by |
|---|---|---|
| `SauceCodePro Nerd Font` | natural width | copal, amberlin — they draw notes, not a grid |
| `SauceCodePro Nerd Font Mono` | one character cell | kat800 — VTE *is* a character grid |

Both are monospaced for text; fontconfig reports `spacing=100` for either. The
difference is only the icons, and asking for the wrong family gets a silent
fallback rather than an error. Four styles each — Regular, Bold, Italic,
BoldItalic — so emphasis has somewhere to go.

Both install into `/usr/share/fonts/truetype/saucecodepro-nerd/` and coexist:
distinct families, distinct filenames, nothing overwrites anything.

## Build

```sh
make check    # every promised face is present and is really a font
make lint     # each face reports the family name consumers ask for
make deb      # binary .deb into dist/
make ci       # check + build + lint + deb
make deb-install
make deb-remove
make clean
```

`make lint` asks `fc-query` what family each file actually declares rather than
trusting its filename. A rename upstream would otherwise break Copal and
Amberlin silently, which is the exact failure this package exists to prevent.

## Packaging notes

Two things here were learned the expensive way in copal and are kept
deliberately:

- **Faces are installed one at a time**, never `cp -r packaging/fonts`. A
  recursive copy also carries `OFL.txt` into `/usr/share/fonts`, where a licence
  file is not a font, and gives every directory the builder's umask.
- **No `fc-cache`, and no maintainer scripts at all.** fontconfig ships a dpkg
  trigger on `/usr/share/fonts` that rebuilds the cache for every package that
  writes there. Calling it by hand is redundant and trips
  `maintainer-script-updates-fontconfig-cache-improperly`.

`Architecture: all` — a font is the same bytes on every machine.

## Licence

The fonts are **Source Code Pro** (Copyright 2010–2019 Adobe) patched by the
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) project, both under the
**SIL Open Font License 1.1** — see [`packaging/fonts/OFL.txt`](packaging/fonts/OFL.txt).

The packaging in this repository — the Makefile and the `packaging/` templates —
is **BSD-3-Clause**, so nothing here is more restrictive than the fonts it
wraps. It covers the packaging only; nothing narrows the OFL. See
[LICENSE](LICENSE).

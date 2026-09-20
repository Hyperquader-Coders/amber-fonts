# amber-fonts

Adobe's **Source** family — the typefaces the **Amber Linux** suite draws with,
packaged once. Three are Adobe's own releases; two are Adobe's code face with
the Nerd Fonts glyphs patched in.

There is no code here. This repository exists because [copal](https://github.com/Hyperquader-Coders/copal),
[kat800](https://github.com/Hyperquader-Coders/kat800) and [amberlin](https://github.com/Hyperquader-Coders/amberlin) each carried their own copy of
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

## Five families, not interchangeable

| Family | Spacing | Icons | Used by |
|---|---|---|---|
| `SauceCodePro Nerd Font` | monospaced | natural width | copal, amberlin — they draw notes, not a grid |
| `SauceCodePro Nerd Font Mono` | monospaced | one character cell | kat800 — VTE *is* a character grid |
| `Source Code Pro` | monospaced | none | code and monospaced text that draws no icons |
| `Source Sans 3` | proportional | none | proportional prose; the candidate for Amberlin's note bodies |
| `Source Serif 4` | proportional | none | proportional prose, where a serif reads better than a sans |

**The Nerd Font glyphs exist only in the two SauceCodePro families.** Source
Code Pro, Source Sans 3 and Source Serif 4 are Adobe's plain releases: asking
any of them for a powerline arrow or a folder icon gets the fallback box. Only a
terminal draws those glyphs, and only kat800 is a terminal.

**Source Code Pro and SauceCodePro are the same outlines**, the second being the
first with the icons patched in under a different name. The icons cost an order
of magnitude on disk — 210 kB a face against 2.4 MB — so `Source Code Pro` is
the family to ask for when the text is code and nothing else, and a SauceCodePro
family when something has to draw an icon at a text position.

The three code families are monospaced — fontconfig reports `spacing=100` for
each. Source Sans 3 and Source Serif 4 are proportional, which is why they are
here: a note body set in a monospaced face runs wide, and the measure that suits
a path suits a paragraph badly. Which face Amberlin sets note bodies in is an
open question, argued in `amberlin/docs/SPEC.md` § Open questions; settling it
means seeing the proportional face and the code face side by side in a real
note, which needs both installed.

Asking for the wrong family gets a silent fallback rather than an error. Four
styles each — Regular, Bold, Italic, BoldItalic — so emphasis has somewhere to
go. Upstream ships every weight from ExtraLight to Black, and Source Serif 4 a
set of optical sizes on top; the package carries the four styles and nothing
else, so what a caller may ask for is one sentence rather than a file list.

Each directory installs under `/usr/share/fonts/truetype/` —
`saucecodepro-nerd/` for both SauceCodePro families, `source-code-pro/`,
`source-sans-3/`, `source-serif-4/` — and they coexist: distinct families,
distinct filenames, nothing overwrites anything.

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
  recursive copy also carries each family's `OFL.txt` into `/usr/share/fonts`,
  where a licence file is not a font, and gives every directory the builder's
  umask.
- **No `fc-cache`, and no maintainer scripts at all.** fontconfig ships a dpkg
  trigger on `/usr/share/fonts` that rebuilds the cache for every package that
  writes there. Calling it by hand is redundant and trips
  `maintainer-script-updates-fontconfig-cache-improperly`.

`Architecture: all` — a font is the same bytes on every machine.

## Licence

The fonts are Adobe's, all under the **SIL Open Font License 1.1**. Each family
ships its own copy of that licence, because the copyright notice and the
Reserved Font Names are stated in the file and differ per family.

| Directory | Fonts | Licence copy |
|---|---|---|
| `saucecodepro-nerd/` | Source Code Pro (Copyright 2010–2020 Adobe) patched by [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) | [`packaging/fonts/OFL.txt`](packaging/fonts/OFL.txt) |
| `source-code-pro/` | [Source Code Pro](https://github.com/adobe-fonts/source-code-pro) (Copyright 2023 Adobe) | [`packaging/fonts/truetype/source-code-pro/OFL.txt`](packaging/fonts/truetype/source-code-pro/OFL.txt) |
| `source-sans-3/` | [Source Sans 3](https://github.com/adobe-fonts/source-sans) (Copyright 2010–2022 Adobe) | [`packaging/fonts/truetype/source-sans-3/OFL.txt`](packaging/fonts/truetype/source-sans-3/OFL.txt) |
| `source-serif-4/` | [Source Serif 4](https://github.com/adobe-fonts/source-serif) (Copyright 2014–2023 Adobe) | [`packaging/fonts/truetype/source-serif-4/OFL.txt`](packaging/fonts/truetype/source-serif-4/OFL.txt) |

`Source` is a Reserved Font Name. Clause 3 of the OFL forbids a modified version
from using it, which is why the patched faces are SauceCodePro rather than
Source Code Pro. The installed package puts all four copies in
`/usr/share/doc/amber-fonts/`.

Which upstream release each face comes from, and the sha256 of the archive it
was taken from, is recorded in
[`packaging/fonts/SOURCES`](packaging/fonts/SOURCES). No face here is rebuilt,
subsetted or renamed: each one is a byte-for-byte member of the archive named
there.

The packaging in this repository — the Makefile and the `packaging/` templates —
is **BSD-3-Clause**, so nothing here is more restrictive than the fonts it
wraps. It covers the packaging only; nothing narrows the OFL. See
[LICENSE](LICENSE).

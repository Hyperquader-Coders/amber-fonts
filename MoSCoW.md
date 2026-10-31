# MoSCoW: amber-fonts

Prioritisation by **Must / Should / Could / Won't have** (the lower-case Os just make it
pronounceable). This is the **scope** document, and it holds only what is **still open**: an
item leaves this file the moment it ships. Nothing here records work done: `git log` is for
that.

An empty band means that band is finished, not that it was never populated.

## Must have

## Should have

## Could have

- **The suite's own code font, built here.** amber-fonts builds the patched face itself instead of
  packaging Nerd Fonts' SauceCodePro: Source Code Pro with only the glyph sets the suite uses
  (Material Design first, the sets kat800's panels need), so the font is smaller and every icon
  is one the suite chose. It takes a name of its own ("Amber Mono" or similar): Source Code Pro's
  OFL-1.1 reserves the name "Source", and a modified font stays under OFL-1.1, so the font is not
  BSD-3; the build tooling and any glyphs the suite draws can be, and each icon set keeps its
  notice (Apache-2.0, CC-BY-4.0, MIT). amber-lib's `amber:icons` would then read its glyphs from
  this font. Needs planning: the glyph list, the patcher (Nerd Fonts' font-patcher, MIT, or our
  own fontTools step), the name, and kat800's, Copal's and Amberlin's switch to it.

## Won't have (this time)

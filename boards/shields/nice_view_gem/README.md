# nice_view_gem (vendored fork)

Forked from [M165437/nice-view-gem](https://github.com/M165437/nice-view-gem) at `v0.3.0`, vendored
directly into this repo instead of pulled in via `west.yml`.

Changes from upstream:

- Removed the WPM chart, layer/profile widgets, and crystal animation. Both halves are peripherals
  in this dongle-based setup, so none of that ever rendered here anyway — this just deletes the
  dead code.
- Replaced the crystal artwork with a static Umbrella Corporation logo.
- Added a caps-lock indicator, shown at the bottom of the display on both halves.
- Dropped the light/dark (`NICE_VIEW_WIDGET_INVERTED`) toggle in favor of a single hardcoded
  dark-background/light-text palette.

## Hardware

The nice!view is a low-power, high refresh rate display meant to replace I2C OLEDs traditionally used.

This shield requires that an `&nice_view_spi` labeled SPI bus is provided with _at least_ MOSI, SCK, and CS pins defined.

## Credits

The font, Pixel Operator, is the work of Jayvee Enaguas, shared under a
[Creative Commons Zero (CC0) 1.0](https://creativecommons.org/publicdomain/zero/1.0/) license.

#!/bin/bash
# This file feels sketchy as fuck.
git clone https://github.com/termbox/termbox2.git src/termbox2/lib/termbox2
cd src/termbox2/lib/termbox2
make libtermbox.so

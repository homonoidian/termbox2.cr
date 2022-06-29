#!/bin/bash
# This file feels sketchy as fuck.

curl -kL https://github.com/termbox/termbox2/archive/refs/heads/master.tar.gz | tar -xz
mv termbox2-master src/termbox2/lib/termbox2
cd src/termbox2/lib/termbox2
make libtermbox.a

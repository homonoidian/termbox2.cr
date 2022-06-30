# termbox2

A tiny bindings shard plus a bit more for [termbox2](https://github.com/termbox/termbox2).
Docs & comments & stuff stolen from there. The library is pretty cool except for a bunch
of key event (key name) clashes which are too weird to even discuss, and the termbox2 devs
aren't those to blame (it seems).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     termbox2:
       github: homonoidian/termbox2.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "termbox2"

include Termbox
include Termbox::Event

Termbox.enable
# Can be changed to other modes dynamically, colors will
# scale with some effort. See `examples/hello.cr`
Termbox.set_output_mode(OutputMode::Truecolor)
Termbox.clear(bg: Color[0x11, 0x11, 0x11], fg: Color[0xec, 0xec, 0xec])

bg_1 = Color[0x11, 0x11, 0x11]
bg_2 = Color[0xa3, 0xa7, 0x2a]
cbg = bg_1
frametimer = 0
h = 0

# This guy will automatically Termbox.disable.
#
# If you won't use it, you'd have to Termbox.disable yourself.
Termbox.each(nap: 33.milliseconds) do |event|
  # can be nil or mouse event or resize event or key event
  if event.is_a?(KeyEvent)
    if event.char == 'q'
      break
    else
    end
  end
  Termbox.clear
  Termbox.print(
    x: Termbox.width // 2 - 10 + (-10..10).sample,
    y: Termbox.height // 2 + (-1..1).sample,
    fg: Color[h: h / 360, s: 0.5, l: 0.5],
    bg: cbg,
    object: "Going nuclear would be fun AF!!!",
  )

  if h > 360
    h = 0
  else
    h += 1
  end

  cbg =
    if frametimer > 10
      frametimer = 0
      if rand < 0.5
        bg_2
      else
        bg_1
      end
    else
      frametimer += 1
      cbg
    end

  Termbox.present
end
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/homonoidian/termbox2.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alexey Yurchenko](https://github.com/homonoidian) - creator and maintainer

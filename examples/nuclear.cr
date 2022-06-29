require "../src/termbox2"

include Termbox
include Termbox::Event

Termbox.enable
# Can be changed to other modes, colors will scale with some effort.
Termbox.set_output_mode(OutputMode::Truecolor)
Termbox.clear(bg: Color[0x11, 0x11, 0x11], fg: Color[0xec, 0xec, 0xec])

bg_1 = Color[0x11, 0x11, 0x11]
bg_2 = Color[0xa3, 0xa7, 0x2a]
cbg = bg_1
frametimer = 0
h = 0

Termbox.each(nap: 33.milliseconds) do |event|
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

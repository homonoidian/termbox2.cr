require "../src/termbox2"

include Termbox
include Termbox::Event

def erase(fg, bg)
  # Yup.
  Termbox.clear(fg, bg)
  Termbox.clear
end

h = 0
x = 0
y = 0
dx = 1
dy = 1

Termbox.enable
# Termbox.set_output_mode(OutputMode::Normal)
# Termbox.set_output_mode(OutputMode::M256)
Termbox.set_output_mode(OutputMode::Truecolor)

Termbox.each(33.milliseconds) do |event|
  break if event.is_a?(KeyEvent) && event.char == 'q'

  erase(Color::Default, bg = Color[h: h / 360, s: 0.5, l: 0.5])

  x += dx
  y += dy

  if x < 0 || x > Termbox.width - 3
    dx = -dx
    x = x < 0 ? 0 : Termbox.width - 3
  end

  if y < 0 || y > Termbox.height - 1
    dy = -dy
    y = y < 0 ? 0 : Termbox.height - 3
  end

  Termbox.print(x.to_i, y.to_i, Color::Default | Color::Also::Italic, Color::Default, h)
  Termbox.present
  h = h > 360 ? 0 : h + 1
end

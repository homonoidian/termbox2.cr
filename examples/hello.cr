require "../src/termbox2"

include Termbox

FG = Color[0xcc, 0xcc, 0xcc]
BG = Color[0x1f, 0x1f, 0x1f]

class State
  property str = ""
  property cur = 0
  property evt : Event::BaseEvent? = nil
  property attr = Color::Also::Italic
  property hi = true
  property pixels = [] of {Int32, Int32}
end

def center(dw = 0, dh = 0)
  if Termbox.width < 80
    x = dw
  else
    x = Termbox.width // 2 - dw/2
  end

  if Termbox.height < 40
    y = Termbox.height - dh
  else
    y = Termbox.height // 2 - dh
  end

  {x, y}
end

def typein(s, char)
  s.str = s.str.insert(s.cur, char)
  s.cur += 1
end

def render(s)
  lines = [
    {"Output mode #{Termbox.get_output_mode} #{s.evt}", FG, BG},
    {"Hit Ctrl-q to quit", FG, BG},
    {"Scroll thru attrs via mouse, current: #{s.attr}", FG, BG},
    {"Left mouse button to hi/unhi below", FG, BG},
    {"Right mouse button to draw", FG, BG},
    if s.hi
      {" #{s.str} ", BG | s.attr, FG}
    else
      {"#{s.str} ", FG | s.attr, BG}
    end,
  ]

  lines.each_with_index do |(line, fg, bg), index|
    Termbox.print(*center(line.size, lines.size - index), fg, bg, line)
  end

  s.pixels.each do |(x, y)|
    Termbox.print(x, y, FG | Color::Also::Reverse, BG, " ")
  end
end

Termbox.enable
Termbox.set_input_mode(InputMode::Escape | InputMode::Mouse)
Termbox.set_output_mode(OutputMode::Truecolor)
Termbox.clear(FG, BG)

s = State.new
Termbox.clear
render(s)
Termbox.present

Termbox.each do |event|
  case event
  when KeyEvent
    break if event.key.try &.ctrl_q?
    if event.key.try &.tab?
      mode =
        case Termbox.get_output_mode
        when .normal?    then OutputMode::M256
        when .m256?      then OutputMode::Truecolor
        when .truecolor? then OutputMode::Normal
        else
          raise "impossible"
        end
      Termbox.set_output_mode(mode)
      Termbox.clear(FG, BG) # idk why this is needed maybe redraws everything???
    elsif ch = event.char
      typein(s, ch)
    end
  when MouseEvent
    if event.button.left?
      s.hi = !s.hi
    elsif event.button.right?
      s.pixels << {event.x, event.y}
    elsif event.button.wheel_up?
      inc = -1
    elsif event.button.wheel_down?
      inc = +1
    end
    inc ||= 0
    attrord = s.attr.ord
    if 0 <= attrord + inc < Color::Also.count
      s.attr = Color::Also[attrord + inc]
    else
      s.attr = Color::Also[inc < 0 ? Color::Also.count : 0]
    end
  end

  s.evt = event if event

  Termbox.clear
  render(s)
  Termbox.present
end

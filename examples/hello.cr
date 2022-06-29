require "../src/termbox2"

include Termbox

FG = Color[0xcc, 0xcc, 0xcc]
BG = Color[0x1f, 0x1f, 0x1f]

class State
  property str = ""
  property cur = 0
  property evt : Event::BaseEvent? = nil
end

def center(dw = 0, dh = 0)
  if dw >= Termbox.width
    if dh >= Termbox.height
      {0, 0}
    else
      {0, Termbox.height // 2 - dh}
    end
  else
    {Termbox.width // 2 - dw/2, Termbox.height // 2 - dh}
  end
end

def typein(s, char)
  s.str = s.str.insert(s.cur, char)
  s.cur += 1
end

def render(s)
  caption = "Output mode #{Termbox.get_output_mode} #{s.evt}"

  Termbox.print(*center(caption.size, 2), FG, BG, caption)
  Termbox.print(*center(s.str.size, 1), BG, FG, s.str)
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
      case Termbox.get_output_mode
      when .normal?
        Termbox.set_output_mode(OutputMode::M256)
        Termbox.clear(FG, BG) # idk why this is needed maybe redraws everything???
      when .m256?
        Termbox.set_output_mode(OutputMode::Truecolor)
        Termbox.clear(FG, BG)
      when .truecolor?
        Termbox.set_output_mode(OutputMode::Normal)
        Termbox.clear(FG, BG)
      end
    elsif ch = event.char
      typein(s, ch)
    end
  when MouseEvent
  end

  s.evt = event if event

  Termbox.clear
  render(s)
  Termbox.present
end

require "../src/termbox2"

include Termbox
include Termbox::Event

record Word, word : String, index : Int32, start : Int32 do
  def range
    start...start + word.size
  end
end

class Line
  private property text : String

  def initialize(@text = "")
  end

  getter words : Array(Word) do
    # This doesn't really work but gets the job done (i.e.,
    # it considers whitspaces as words too, this is not
    # conventional.)
    start = 0
    splitted = text.split(/(\s+)/, remove_empty: true)
    splitted << " "
    splitted.map_with_index do |word, index|
      Word.new(word, index, start.tap { start += word.size })
    end
  end

  def text=(@text)
    @words = nil
  end

  def add(pos, str)
    self.text = text.insert(pos, str)
  end

  def del(pos)
    self.text = text.delete_at(pos) unless text.empty?
  end

  def size
    text.size
  end

  def blit(x, y)
    Termbox.print(x, y, text)
  end
end

class LineEditor
  property line : Line
  getter curs : Int32

  def initialize(@line)
    @curs = line.size
  end

  def curs=(pos)
    @curs = pos.clamp(0..line.size)
  end

  def add(input)
    line.add(curs, input)
    move(input.size)
  end

  def del(delta = 0)
    line.del(self.curs += delta)
  end

  def word?
    line.words.find &.range.includes?(curs)
  end

  def ws?
    word?.try &.range.begin
  end

  def we?
    word?.try &.range.end
  end

  def pws?
    word?.try do |word|
      line.words.each_cons_pair do |l, r|
        return l.range.begin if r.index == word.index
      end
    end
  end

  def nwe?
    word?.try { |word| line.words[word.index + 1]?.try(&.range.end) }
  end

  def move(delta)
    self.curs += delta
  end

  def blit(x, y)
    line.blit(x, y)
    Termbox.change(x + curs, y, Color::Also::Reverse)
  end
end

editors = Array(LineEditor).new(3) do |index|
  LineEditor.new(Line.new("Hit Ctrl-Q to quit ##{index}"))
end

Termbox.enable
Termbox.each(33.milliseconds) do |event|
  if event.is_a?(KeyEvent)
    case event.key
    when nil
      char = event.char.not_nil!
      if char.printable?
        editors.each &.add(char.to_s)
      end
    when .ctrl_q? then break
    when .arrow_left?
      if event.mod.try &.ctrl?
        editors.each do |editor|
          ws = editor.ws?
          if editor.curs == ws
            # Already at the start of the current word. Jump
            # to previous word start.
            editor.curs = editor.pws? || ws.not_nil!
          elsif ws
            # Jump to current word start.
            editor.curs = ws
          end
        end
      else
        editors.each &.move(-1)
      end
    when .arrow_right?
      if event.mod.try &.ctrl?
        editors.each do |editor|
          we = editor.we?
          if editor.curs == we
            # Already at the end of current word, jump to the
            # next word end.
            editor.curs = editor.nwe? || we.not_nil!
          elsif we
            editor.curs = we
          end
        end
      else
        editors.each &.move(+1)
      end
    when .home?, .arrow_up?
      editors.each(&.curs = 0)
    when .end?, .arrow_down?
      editors.each { |editor| editor.curs = editor.line.size }
    when .backspace?, .backspace2?
      editors.each(&.del(-1))
    when .delete?
      editors.each(&.del(0))
    end
  end

  Termbox.clear

  editors.each_with_index do |editor, index|
    editor.blit(1, index + 1)
  end

  Termbox.present
end

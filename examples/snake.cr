require "../src/termbox2"

struct SVec2
  getter x : Int32
  getter y : Int32

  def initialize(@x = 0, @y = 0)
  end

  def &+(other)
    SVec2.new((x + other.x) % Termbox.width, (y + other.y) % Termbox.height)
  end

  def put(string)
    Termbox.print(x, y, Termbox::Color::Default, Termbox::Color::Default, string)
  end

  def opp?(other)
    x * other.x < 0 || y * other.y < 0
  end

  def self.sample(minx = 0, maxx = Termbox.width, miny = 0, maxy = Termbox.height)
    SVec2.new((minx...maxx).sample, (miny...maxy).sample)
  end

  def_equals x, y
end

module Entity
  abstract def pos : SVec2
  abstract def to(entity)

  def at?(other)
    pos == other.pos
  end

  def step
  end

  def blit
    pos.put(char)
  end
end

class Snake
  include Entity

  private getter body = [SVec2.new]
  private getter dir = SVec2.new(+1, 0)

  private def dir=(vec)
    @dir = vec unless vec.opp?(dir)
  end

  def pos : SVec2
    body.first
  end

  def apply(event : Termbox::Event::KeyEvent)
    case event.key
    when nil
    when .arrow_up?    then self.dir = SVec2.new(0, -1)
    when .arrow_down?  then self.dir = SVec2.new(0, +1)
    when .arrow_left?  then self.dir = SVec2.new(-1, 0)
    when .arrow_right? then self.dir = SVec2.new(+1, 0)
    end
  end

  def dead?
    body.size > 1 && body.skip(1).any?(pos)
  end

  def to(entity)
    body[0] = entity.pos
  end

  def grow
    body << body.last
  end

  def step
    head = pos &+ dir
    body.map! do |prev|
      head, _ = prev, head
    end
  end

  def blit
    pos.put("O"); body.each.skip(1).each &.put("o")
  end
end

class Apple
  include Entity

  property pos : SVec2

  def initialize(@pos)
  end

  def to(entity)
    self.pos = entity.pos
  end

  def char
    "@"
  end
end

class Portal
  include Entity

  property pos : SVec2
  property dst : Portal?

  def initialize(@pos, @dst = nil)
  end

  def tp(other)
    dst.try { |it| other.to(it) }
  end

  def to(other)
    self.pos = other
  end

  def char
    "."
  end
end

Termbox.enable

apple = Apple.new(SVec2.sample)
snake = Snake.new
pin = Portal.new(SVec2.sample)
pout = Portal.new(SVec2.sample, pin)
pin.dst = pout
pout.dst = pin


Termbox.each(33.milliseconds) do |event|
  key = event.as?(Termbox::Event::KeyEvent)
  
  break if snake.dead? || (key && key.char == 'q')
 
  if snake.at?(apple)
    apple = Apple.new(SVec2.sample)
    snake.grow
  elsif portal = {pin, pout}.find &.at?(snake)
    portal.tp(snake)
  end
  
  # ! Snake must grow before step, o/w it will die.
  snake.apply(key) if key
  snake.step
  
  
  Termbox.clear
  snake.blit
  apple.blit
  pin.blit
  pout.blit
  Termbox.present
end

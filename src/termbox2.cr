require "./termbox2/lib/lib"
require "./termbox2/color"

# A thin wrapper around Termbox 2.
module Termbox
  extend self
  include Event

  alias Attribute = IColor | Color::Also

  # Returns whether Termbox is currently enabled.
  class_getter? enabled = false

  # Raised when Termbox fails to do something.
  class TermboxError < Exception
    getter err : Int32

    def initialize(@err)
      @message = String.new(LibTermbox.strerror(err))
    end
  end

  # :nodoc:
  #
  # Raises if a negative value is returned by *call*. This
  # is considered an error in Termbox.
  macro try!(call)
    if (%code = {{call}}).negative?
      raise TermboxError.new(%code)
    end
  end

  # Returns the width of the terminal window (in columns).
  def width : Int32
    LibTermbox.width.to_i
  end

  # Returns the width of the terminal window (in rows).
  def height : Int32
    LibTermbox.height.to_i
  end

  # Moves the cursor to the specified position (in rows, cols).
  # Upper-left corner is at (0, 0). The cursor is shown if it
  # was hidden.
  def set_cursor(x, y)
    try! LibTermbox.set_cursor(x, y)
  end

  # Hides the cursor.
  def hide_cursor
    try! LibTermbox.hide_cursor
  end

  # Synchronizes the internal back buffer with the terminal
  # by writing to tty.
  def present
    try! LibTermbox.present
  end

  # Clears the internal back buffer using `NormalColor::Default`
  # or the color/attributes set by `clear(fg, bg)`.
  def clear
    try! LibTermbox.clear
  end

  # Sets clear background and foreground attributes.
  def clear(fg : Attribute, bg : Attribute)
    mode = get_output_mode
    try! LibTermbox.set_clear_attrs(fg.for(mode), bg.for(mode))
  end

  # Changes the attributes of the cell at *x*, *y*. *fill*
  # specifies the character that is used when the referred
  # cell has no content, otherwise, existing cel lcontent
  # is used.
  def change(x, y, fg : Attribute = Color::Default, bg : Attribute = Color::Default, fill = ' ')
    mode = get_output_mode
    backup = fill.ord.to_u32
    LibTermbox.change(x, y, pointerof(backup), fg.for(mode), bg.for(mode))
  end

  # Prints the string representation of *object* at the given
  # position, with the given foreground and background attributes.
  def print(x, y, fg : Attribute, bg : Attribute, object)
    text = object.to_s
    size = text.bytesize.to_u64
    mode = get_output_mode
    try! LibTermbox.print(x, y, fg.for(mode), bg.for(mode), pointerof(size), text.to_unsafe)
  end

  # Prints the string representation of *object* at the given
  # position with default attributes (see `Color::Default`).
  def print(x, y, object)
    print(x, y, Color::Default, Color::Default, object)
  end

  # Waits for an event up to *timeout* and returns a `BaseEvent`,
  # or nil if no event is available within the timeout.
  def peek?(timeout : Time::Span) : BaseEvent?
    peek?(timeout.milliseconds)
  end

  # Waits for an event up to *timeout* milliseconds and
  # returns a `BaseEvent`, or nil if no event is available
  # within the timeout.
  def peek?(timeout = -1) : BaseEvent?
    case err = LibTermbox.peek(out event, timeout.to_i)
    when .zero?
      BaseEvent.from(event)
    when LibTermbox::ERR_NO_EVENT
    when LibTermbox::ERR_POLL
      # On a resize event, the underlying select(2) call may be
      # interrupted, yielding a return code of TB_ERR_POLL. In
      # this case, you may check errno via tb_last_errno(). If
      # it's EINTR, you can safely ignore that and peek again.
      peek?(timeout) if LibTermbox.last_errno == Errno::EINTR
    else
      raise TermboxError.new(err)
    end
  end

  # Sets the input mode (see `InputMode`). The default mode
  # is `InputMode::Escape`.
  def set_input_mode(mode : InputMode) : InputMode
    result = LibTermbox.set_input_mode(mode)
    mode.current? ? InputMode.new(result) : mode
  end

  # Same as `set_input_mode(InputMode::Current)`.
  def get_input_mode
    set_input_mode(InputMode::Current)
  end

  # Sets the termbox output mode (see `OutputMode`).
  #
  # Note that not all terminals support all output modes,
  # especially beyond `OutputMode::Normal`. There is also no
  # very reliable way to determine color support dynamically.
  # If portability is desired, users are recommended to use
  # `OutputMode::Normal` or make output mode end-user configurable.
  def set_output_mode(mode : OutputMode) : OutputMode
    result = LibTermbox.set_output_mode(mode)
    mode.current? ? OutputMode.new(result) : mode
  end

  # Same as `set_output_mode(InputMode::Current)`.
  def get_output_mode
    set_output_mode(OutputMode::Current)
  end

  # Initializes Termbox. Must be called before any other function.
  # If Termbox is already on, does nothing.
  def enable
    unless enabled?
      try! LibTermbox.init
      @@enabled = true
    end
  end

  # Finalizes Termbox. Must be called after successful initialization.
  # Does nothing if Termbox is off already.
  def disable
    if enabled?
      @@enabled = false
      try! LibTermbox.shutdown
    end
  end

  # Initializes Termbox for the duration of the block. If *nap*
  # is given and is not nil, does not wait for events but naps
  # for that span between the non-blocking polls. Else, waits
  # for events. Yields event to the block (can be nil).
  def each(nap = nil)
    enable
    at_exit { disable }
    loop do
      # -1 is for blocking peek I suppose, but who knows?
      yield peek?(nap || -1)
      sleep nap if nap
    rescue error
      disable
      raise error
    end
  end
end

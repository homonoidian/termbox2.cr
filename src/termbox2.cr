require "./termbox2/lib/lib"
require "./termbox2/color"

# A thin wrapper around Termbox 2.
module Termbox
  extend self
  include Event

  # Returns whether Termbox is currently enabled.
  class_getter? enabled = false

  # Raised when Termbox fails to do something.
  class TermboxError < Exception
    getter err : Int32

    def initialize(@err)
      @message = String.new(LibTermbox.strerror(err))
    end
  end

  # Raises if a negative value is returned by *call*. This is
  # considered an error in termbox.
  macro try!(call)
    if (%code = {{call}}).negative?
      raise TermboxError.new(%code)
    end
  end

  # Returns the width of the terminal window (in columns).
  def width
    LibTermbox.width.to_i
  end

  # Returns the width of the terminal window (in rows).
  def height
    LibTermbox.height.to_i
  end

  # Moves the cursor to the specified position (in rows,
  # columns). Upper-left corner is at (0, 0). Shows it if
  # it was hidden.
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

  # Clears the internal back buffer using `Color::Default`
  # or the color/attributes set by `clear(fg, bg)`.
  def clear
    try! LibTermbox.clear
  end

  # Sets clear background and foreground color/attributes.
  def clear(fg : Color, bg : Color)
    mode = get_output_mode

    try! LibTermbox.set_clear_attrs(fg.for(mode), bg.for(mode))
  end

  # Prints the string representation of *object* at the
  # specified position, with the specified attributes.
  def print(x, y, fg : Color, bg : Color, object)
    string = object.to_s
    width = string.bytesize.to_u64
    mode = get_output_mode
    try! LibTermbox.print(x, y, fg.for(mode), bg.for(mode), pointerof(width), string.to_unsafe)
  end

  # Waits for an event up to *timeout* and returns an `Event`,
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
      raise "termbox error: #{err}"
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

require "../mode"
require "../event"
require "../input"

@[Link(ldflags: "#{__DIR__}/termbox2/libtermbox.so")]
lib LibTermbox
  alias Int = LibC::Int
  alias SizeT = LibC::SizeT

  ERR_NO_EVENT =  -6
  ERR_POLL     = -14

  enum EventType : UInt8
    Key    = 1
    Resize
    Mouse
  end

  struct Event
    type : EventType
    mod : LibC::UInt8T
    key : LibC::UInt16T
    ch : LibC::UInt32T
    w : LibC::Int
    h : LibC::Int
    x : LibC::Int
    y : LibC::Int
  end

  fun init = tb_init : Int
  fun init_file = tb_init_file(path : UInt8*) : Int
  fun init_fd = tb_init_fd(ttyfd : Int) : Int
  fun init_rwfd = tb_init_rwfd(rfd : Int, wfd : Int) : Int
  fun shutdown = tb_shutdown : Int
  fun width = tb_width : Int
  fun height = tb_height : Int
  fun clear = tb_clear : Int
  fun set_clear_attrs = tb_set_clear_attrs(fg : UInt32, bg : UInt32) : Int
  fun present = tb_present : Int
  fun set_cursor = tb_set_cursor(cx : Int, cy : Int) : Int
  fun hide_cursor = tb_hide_cursor : Int
  fun set_input_mode = tb_set_input_mode(mode : Termbox::InputMode) : Int
  fun set_output_mode = tb_set_output_mode(mode : Termbox::OutputMode) : Int
  fun print = tb_print_ex(x : Int, y : Int, fg : UInt32, bg : UInt32, out_w : SizeT*, str : UInt8*) : Int
  fun peek = tb_peek_event(event : Event*, timeout_ms : Int) : Int
  fun last_errno = tb_last_errno : Int
  fun strerror = tb_strerror(err : Int) : UInt8*
end
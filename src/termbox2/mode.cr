module Termbox
  # Input modes (bitwise).
  enum InputMode : LibC::Int
    # Makes `Termbox.get_input_mode` return the current input mode.
    Current = 0

    # When escape (`\x1b`) is in the buffer and there's no
    # match for an escape sequence, a key event for `Key::Esc`
    # is returned.
    Escape = 1

    # When escape (`\x1b`) is in the buffer and there's no match
    # for an escape sequence, the next keyboard event is returned
    # with a `KeyMod::Alt` modifier.
    Alt = 2

    # Can be applied via bitwise OR operation to either of the
    # modes to receive `EventType::Mouse` events.
    #
    # If none of the main two modes were set, but the mouse
    # mode was, `Escape` mode is used.
    Mouse = 4
  end

  # Output modes.
  enum OutputMode : LibC::Int
    # Makes `Termbox.get_output_mode` return the current output mode.
    Current

    # This mode provides 8 different `NormalColor`s: black,
    # red, green, yellow, blue, magenta, cyan, white. Colors
    # may be bitwise OR'd with attributes: bold, italic, underline,
    # reverse, blink (note that bold, underline, italic, blink
    # only apply to foreground).
    Normal

    # This mode provides 256 distinct colors.
    #   * 0x00 - 0x07: the 8 colors as in `Normal`
    #   * 0x08 - 0x0f: bright versions of the above
    #   * 0x10 - 0xe7: 216 different colors
    #   * 0xe8 - 0xff: 24 different shades of grey
    M256

    # This mode supports the 3rd range of `M256` only, but
    # you don't need to provide an offset.
    M216

    # This mode supports the 4th range of `M256` only, but
    # you don't need to provide an offset.
    Grayscale

    # This mode provides 24-bit color on supported terminals.
    # The format is 0xRRGGBB. Colors may be bitwise OR'd with
    # `TrueColor` attributes.
    Truecolor
  end
end

require "./input"

module Termbox::Event
  abstract struct BaseEvent
    # Creates a `BaseEvent` subclass from a Termbox event struct.
    def self.from(event : LibTermbox::Event)
      case event.type
      in .key?
        KeyEvent.from(event)
      in .resize?
        ResizeEvent.from(event)
      in .mouse?
        MouseEvent.from(event)
      end
    end
  end

  # Emitted by those key press events that are not representable
  # by a printable(-ish) Char and a modifier.
  struct KeyEvent < BaseEvent
    # Returns the key that was pressed. Either this or `char`
    # is available for key events.
    getter key : Key?

    # Returns the char that was pressed. Either this or `key`
    # is available for key events.
    getter char : Char?

    # Returns the key modifier.
    getter mod : KeyModifier

    def initialize(@key, @char, @mod)
    end

    # Creates a `KeyEvent` from a Termbox event struct.
    def self.from(event)
      KeyEvent.new(
        key: event.key.zero? ? nil : Key.new(event.key),
        char: event.ch.zero? ? nil : event.ch.chr,
        mod: KeyModifier.new(event.mod),
      )
    end
  end

  # Emitted when the terminal window is resized.
  struct ResizeEvent < BaseEvent
    # Returns the new terminal width.
    getter w : Int32
    # Returns the new terminal height.
    getter h : Int32

    def initialize(@w, @h)
    end

    # Creates a `ResizeEvent` from a Termbox event struct.
    def self.from(event)
      ResizeEvent.new(event.w, event.h)
    end
  end

  # Emitted by mouse events when mouse is enabled (see
  # `InputMode::Mouse` for more).
  struct MouseEvent < BaseEvent
    # Returns the mouse X position of this event, in columns.
    getter x : Int32
    # Returns the mouse Y position of this event, in rows.
    getter y : Int32
    # Returns the mouse button of this event.
    getter button : MouseButton

    def initialize(@button, @x, @y)
    end

    # Creates a `MouseEvent` from a Termbox event struct.
    def self.from(event)
      button =
        case Key.new(event.key)
        when .mouse_left?       then MouseButton::Left
        when .mouse_right?      then MouseButton::Right
        when .mouse_middle?     then MouseButton::Middle
        when .mouse_release?    then MouseButton::Release
        when .mouse_wheel_up?   then MouseButton::WheelUp
        when .mouse_wheel_down? then MouseButton::WheelDown
        else
          raise "invalid mouse button in mouse event"
        end

      MouseEvent.new(button, event.x, event.y)
    end
  end
end

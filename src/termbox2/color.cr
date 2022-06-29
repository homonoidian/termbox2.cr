module Termbox
  # Colors (numeric) and attributes (bitwise).
  enum NormalColor : LibC::UInt16T
    Default   = 0x0000
    Black     = 0x0001
    Red       = 0x0002
    Green     = 0x0003
    Yellow    = 0x0004
    Blue      = 0x0005
    Magenta   = 0x0006
    Cyan      = 0x0007
    White     = 0x0008
    Bold      = 0x0100
    Underline = 0x0200
    Reverse   = 0x0400
    Italic    = 0x0800
    Blink     = 0x1000
  end

  # True color attributes (bitwise).
  enum TrueColor : LibC::UInt64T
    Default
    Bold      = 0x01000000
    Underline = 0x02000000
    Reverse   = 0x04000000
    Italic    = 0x08000000
    Blink     = 0x10000000
  end

  abstract struct IColor
    # Returns this color's attribute.
    def also
      Color::Also::Default
    end

    # Returns this color's value for the given output *mode*.
    def for(mode : OutputMode) : UInt32
      case mode
      when .normal?    then normal
      when .m256?      then m256
      when .truecolor? then truecolor
      else
        raise "not implemented yet"
      end.to_u32 | also.for(mode)
    end

    # Mixes *also*, an output-mode-independent attribute,
    # into this color.
    abstract def |(also also_ : Color::Also)
  end

  # Default color for the current color mode.
  record DefaultColor < IColor, also = Color::Also::Default do
    # Even though both are basically zero, I think the difference
    # is in number size: NormalColor is uint16_t and true color
    # is uint64_t.

    getter normal = NormalColor::Default
    getter m256 = NormalColor::Default
    getter truecolor = TrueColor::Default

    def |(also also_ : Color::Also)
      DefaultColor.new(also_)
    end
  end

  # Translates any RGB color between terminal ouput modes
  # (see `OutputMode`).
  record Color < IColor, r : Int32, g : Int32, b : Int32, also = Also::Default do
    # :nodoc:
    #
    # RGBs of Mode::M8 colors.
    M8_COLORS = {
      {0, 0, 0},
      {128, 0, 0},
      {0, 128, 0},
      {128, 128, 0},
      {0, 0, 128},
      {128, 0, 128},
      {0, 128, 128},
      {192, 192, 192},
      {128, 128, 128},
    }

    # :nodoc:
    #
    # RGBs of Mode::M256 colors.
    M256_COLORS = {
      {0, 0, 0},
      {128, 0, 0},
      {0, 128, 0},
      {128, 128, 0},
      {0, 0, 128},
      {128, 0, 128},
      {0, 128, 128},
      {192, 192, 192},
      {128, 128, 128},
      {255, 0, 0},
      {0, 255, 0},
      {255, 255, 0},
      {0, 0, 255},
      {255, 0, 255},
      {0, 255, 255},
      {255, 255, 255},
      {0, 0, 0},
      {0, 0, 95},
      {0, 0, 135},
      {0, 0, 175},
      {0, 0, 215},
      {0, 0, 255},
      {0, 95, 0},
      {0, 95, 95},
      {0, 95, 135},
      {0, 95, 175},
      {0, 95, 215},
      {0, 95, 255},
      {0, 135, 0},
      {0, 135, 95},
      {0, 135, 135},
      {0, 135, 175},
      {0, 135, 215},
      {0, 135, 255},
      {0, 175, 0},
      {0, 175, 95},
      {0, 175, 135},
      {0, 175, 175},
      {0, 175, 215},
      {0, 175, 255},
      {0, 215, 0},
      {0, 215, 95},
      {0, 215, 135},
      {0, 215, 175},
      {0, 215, 215},
      {0, 215, 255},
      {0, 255, 0},
      {0, 255, 95},
      {0, 255, 135},
      {0, 255, 175},
      {0, 255, 215},
      {0, 255, 255},
      {95, 0, 0},
      {95, 0, 95},
      {95, 0, 135},
      {95, 0, 175},
      {95, 0, 215},
      {95, 0, 255},
      {95, 95, 0},
      {95, 95, 95},
      {95, 95, 135},
      {95, 95, 175},
      {95, 95, 215},
      {95, 95, 255},
      {95, 135, 0},
      {95, 135, 95},
      {95, 135, 135},
      {95, 135, 175},
      {95, 135, 215},
      {95, 135, 255},
      {95, 175, 0},
      {95, 175, 95},
      {95, 175, 135},
      {95, 175, 175},
      {95, 175, 215},
      {95, 175, 255},
      {95, 215, 0},
      {95, 215, 95},
      {95, 215, 135},
      {95, 215, 175},
      {95, 215, 215},
      {95, 215, 255},
      {95, 255, 0},
      {95, 255, 95},
      {95, 255, 135},
      {95, 255, 175},
      {95, 255, 215},
      {95, 255, 255},
      {135, 0, 0},
      {135, 0, 95},
      {135, 0, 135},
      {135, 0, 175},
      {135, 0, 215},
      {135, 0, 255},
      {135, 95, 0},
      {135, 95, 95},
      {135, 95, 135},
      {135, 95, 175},
      {135, 95, 215},
      {135, 95, 255},
      {135, 135, 0},
      {135, 135, 95},
      {135, 135, 135},
      {135, 135, 175},
      {135, 135, 215},
      {135, 135, 255},
      {135, 175, 0},
      {135, 175, 95},
      {135, 175, 135},
      {135, 175, 175},
      {135, 175, 215},
      {135, 175, 255},
      {135, 215, 0},
      {135, 215, 95},
      {135, 215, 135},
      {135, 215, 175},
      {135, 215, 215},
      {135, 215, 255},
      {135, 255, 0},
      {135, 255, 95},
      {135, 255, 135},
      {135, 255, 175},
      {135, 255, 215},
      {135, 255, 255},
      {175, 0, 0},
      {175, 0, 95},
      {175, 0, 135},
      {175, 0, 175},
      {175, 0, 215},
      {175, 0, 255},
      {175, 95, 0},
      {175, 95, 95},
      {175, 95, 135},
      {175, 95, 175},
      {175, 95, 215},
      {175, 95, 255},
      {175, 135, 0},
      {175, 135, 95},
      {175, 135, 135},
      {175, 135, 175},
      {175, 135, 215},
      {175, 135, 255},
      {175, 175, 0},
      {175, 175, 95},
      {175, 175, 135},
      {175, 175, 175},
      {175, 175, 215},
      {175, 175, 255},
      {175, 215, 0},
      {175, 215, 95},
      {175, 215, 135},
      {175, 215, 175},
      {175, 215, 215},
      {175, 215, 255},
      {175, 255, 0},
      {175, 255, 95},
      {175, 255, 135},
      {175, 255, 175},
      {175, 255, 215},
      {175, 255, 255},
      {215, 0, 0},
      {215, 0, 95},
      {215, 0, 135},
      {215, 0, 175},
      {215, 0, 215},
      {215, 0, 255},
      {215, 95, 0},
      {215, 95, 95},
      {215, 95, 135},
      {215, 95, 175},
      {215, 95, 215},
      {215, 95, 255},
      {215, 135, 0},
      {215, 135, 95},
      {215, 135, 135},
      {215, 135, 175},
      {215, 135, 215},
      {215, 135, 255},
      {215, 175, 0},
      {215, 175, 95},
      {215, 175, 135},
      {215, 175, 175},
      {215, 175, 215},
      {215, 175, 255},
      {215, 215, 0},
      {215, 215, 95},
      {215, 215, 135},
      {215, 215, 175},
      {215, 215, 215},
      {215, 215, 255},
      {215, 255, 0},
      {215, 255, 95},
      {215, 255, 135},
      {215, 255, 175},
      {215, 255, 215},
      {215, 255, 255},
      {255, 0, 0},
      {255, 0, 95},
      {255, 0, 135},
      {255, 0, 175},
      {255, 0, 215},
      {255, 0, 255},
      {255, 95, 0},
      {255, 95, 95},
      {255, 95, 135},
      {255, 95, 175},
      {255, 95, 215},
      {255, 95, 255},
      {255, 135, 0},
      {255, 135, 95},
      {255, 135, 135},
      {255, 135, 175},
      {255, 135, 215},
      {255, 135, 255},
      {255, 175, 0},
      {255, 175, 95},
      {255, 175, 135},
      {255, 175, 175},
      {255, 175, 215},
      {255, 175, 255},
      {255, 215, 0},
      {255, 215, 95},
      {255, 215, 135},
      {255, 215, 175},
      {255, 215, 215},
      {255, 215, 255},
      {255, 255, 0},
      {255, 255, 95},
      {255, 255, 135},
      {255, 255, 175},
      {255, 255, 215},
      {255, 255, 255},
      {8, 8, 8},
      {18, 18, 18},
      {28, 28, 28},
      {38, 38, 38},
      {48, 48, 48},
      {58, 58, 58},
      {68, 68, 68},
      {78, 78, 78},
      {88, 88, 88},
      {98, 98, 98},
      {108, 108, 108},
      {118, 118, 118},
      {128, 128, 128},
      {138, 138, 138},
      {148, 148, 148},
      {158, 158, 158},
      {168, 168, 168},
      {178, 178, 178},
      {188, 188, 188},
      {198, 198, 198},
      {208, 208, 208},
      {218, 218, 218},
      {228, 228, 228},
      {238, 238, 238},
    }

    Black   = Color.new(*M8_COLORS[0])
    Maroon  = Color.new(*M8_COLORS[1])
    Green   = Color.new(*M8_COLORS[2])
    Olive   = Color.new(*M8_COLORS[3])
    Navy    = Color.new(*M8_COLORS[4])
    Purple  = Color.new(*M8_COLORS[5])
    Teal    = Color.new(*M8_COLORS[6])
    Silver  = Color.new(*M8_COLORS[7])
    White   = Color.new(255, 255, 255)
    Default = DefaultColor.new

    # An output-mode-independent attribute. Exists to delay
    # selection between `NormalColor` and `TrueColor`.
    enum Also
      Default
      Bold
      Underline
      Reverse
      Italic
      Blink

      # Returns the concrete attribute for *mode*.
      def for(mode : OutputMode)
        name = Also.names[to_i]

        case mode
        when .normal?, .m256?
          NormalColor.parse(name).to_u32
        when .truecolor?
          TrueColor.parse(name).to_u64
        else
          raise "not implemented yet"
        end
      end
    end

    private def dist(other)
      cr, cg, cb = other
      dr = r - cr
      dg = g - cg
      db = b - cb
      dr ** 2 + dg ** 2 + db ** 2
    end

    # Returns normal color (0-8) closest to this RGB color.
    def normal
      idx = 0
      dist = dist(M8_COLORS[0])
      M8_COLORS.each_with_index(offset: 1) do |ccolor, index|
        cdist = dist(ccolor)
        if cdist < dist
          dist = cdist
          idx = index
        end
      end
      idx
    end

    # Returns M256 color (0-255) closest to this RGB color.
    def m256
      idx = 0
      dist = dist(M256_COLORS[0])
      M256_COLORS.each_with_index(offset: 1) do |ccolor, index|
        cdist = dist(ccolor)
        if cdist < dist
          dist = cdist
          idx = index
        end
      end
      idx
    end

    # Returns true color for this RGB color.
    def truecolor
      (r << 16) + (g << 8) + b
    end

    # Mixes *also*, an output-mode-independent attribute,
    # into this color.
    def |(also also_ : Color::Also)
      Color.new(r, g, b, also_)
    end

    # Shorthand for `new`.
    def self.[](r, g, b)
      Color.new(r, g, b)
    end

    # STOLEN PROPERTY BELOW
    #
    # https://github.com/watzon/cor

    private module HueToRgb
      # Helper for making rgb.
      def self.hue_to_rgb(m1, m2, h)
        h += 1 if h < 0
        h -= 1 if h > 1
        return m1 + (m2 - m1) * h * 6 if h * 6 < 1
        return m2 if h * 2 < 1
        return m1 + (m2 - m1) * (2.0/3 - h) * 6 if h * 3 < 2
        return m1
      end
    end

    # Shorthand for `new` but converts the given HSL to RGB first.
    def self.[](*, h, s, l)
      m2 = l <= 0.5 ? l * (s + 1) : (l + s - l * s)
      m1 = l * 2 - m2

      rgb = [
        HueToRgb.hue_to_rgb(m1, m2, h + 1.0 / 3),
        HueToRgb.hue_to_rgb(m1, m2, h),
        HueToRgb.hue_to_rgb(m1, m2, h - 1.0 / 3),
      ].map { |c| (c * 0xff).round }

      new(rgb[0].to_i, rgb[1].to_i, rgb[2].to_i)
    end
  end
end

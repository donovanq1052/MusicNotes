require 'rubygems'
require 'gosu'
require './notation_software'

#Draw a circle - pinched from 6.3C in ed lessons
class Circle
  attr_reader :columns, :rows

  def initialize(radius)
    @columns = @rows = radius * 2

    clear, solid = 0x00.chr, 0xff.chr

    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius ** 2 - y ** 2).round
      right_half = "#{solid * x}#{clear * (radius - x)}"
      right_half.reverse + right_half
    end.join
    alpha_channel = lower_half.reverse + lower_half
    # Expand alpha bytes into RGBA color values.
    @blob = alpha_channel.gsub(/./) { |alpha| solid * 3 + alpha }
  end

  def to_blob
    @blob
  end
end

class NoteToDraw
  attr_accessor :x_pos, :y_pos, :sharp, :flat, :note
  
  def initialize(x_pos, y_pos, sharp, flat, note)
    @x_pos = x_pos
    @y_pos = y_pos
    @sharp = sharp
    @flat = flat
    @note = note
  end
end

def draw_quarter_note(x_pos, y_pos, sharp, flat, note)
  note = NoteToDraw.new(x_pos, y_pos, sharp, flat, note)
  circle = Gosu::Image.new(Circle.new(50))
  circle.draw(x_pos, y_pos, ZOrder::NOTE, 1.0, 1.0, Gosu::Color::BLACK)
end
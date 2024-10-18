require 'rubygems'
require 'gosu'

# a record Note that stores the values of a single note
class Note
  attr_accessor :x_pos, :y_pos, :sharp, :flat, :note_type, :note, :sound, :is_rest
  
  def initialize(x_pos, y_pos, sharp, flat, note_type, note, is_rest)
    @x_pos = x_pos
    @y_pos = y_pos
    @sharp = sharp
    @flat = flat
    @note_type = note_type
    @note = note
    @is_rest = is_rest
    if !@is_rest
      @sound = Gosu::Sample.new("pianonotes/#{note}.mp3")
    else
      @sound = nil
    end
  end
end
require 'rubygems'
require 'gosu'

UI_COLOUR = Gosu::Color.new(0xFF1EB1FA)
BLACK = Gosu::Color::BLACK
WHITE = Gosu::Color::WHITE
SECONDS = 60.0
NOTES_UI_START = 400

module ZOrder
  BACKGROUND, UI, SHEET, NOTE = *0..3
end

module NoteType
  QUARTER, EIGTH, SIXTEENTH = *1..3
end

$note_type_selected = NoteType::QUARTER
$sharp_selected = false
$flat_selected = false
$rest_selected = false
$repeat = false
$sheet_music_paused = false
$notes = []
$sharp = Gosu::Image.new("images/sharpsymbol.png")
$flat = Gosu::Image.new("images/flatsymbol.png")
$quarterrest = Gosu::Image.new("images/quarterrest.png")
$eighthrest = Gosu::Image.new("images/eighthrest.png")
$sixteenthrest = Gosu::Image.new("images/sixteenthrest.png")
$repeatsymbol = Gosu::Image.new("images/repeat.png")
$bpm = 90
$last_note_type = NoteType::QUARTER
$pointer_position = 0


######################### THIS SHOULD BE IN MUSIC_NOTES.RB BUT IT WON'T WORK TO USE IT FROM THERE ##############
#THIS IS TO FIX LATER - TALK TO DR MITCHELL OR SOMETHING

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

#Create a class Note that has its location and note values
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

# draws a vertical line up
def draw_up_line(x_pos, y_pos)
  Gosu.draw_line((x_pos + 18), (y_pos + 10), BLACK, (x_pos + 18), (y_pos - 40), BLACK, ZOrder::NOTE)
  Gosu.draw_line((x_pos + 19), (y_pos + 10), BLACK, (x_pos + 19), (y_pos - 40), BLACK, ZOrder::NOTE)
  Gosu.draw_line((x_pos + 20), (y_pos + 10), BLACK, (x_pos + 20), (y_pos - 40), BLACK, ZOrder::NOTE)
end

# draws a vertical line down
def draw_down_line(x_pos, y_pos)
  Gosu.draw_line((x_pos + 18), (y_pos + 10), BLACK, (x_pos + 18), (y_pos + 50), BLACK, ZOrder::NOTE)
  Gosu.draw_line((x_pos + 19), (y_pos + 10), BLACK, (x_pos + 19), (y_pos + 50), BLACK, ZOrder::NOTE)
  Gosu.draw_line((x_pos + 20), (y_pos + 10), BLACK, (x_pos + 20), (y_pos + 50), BLACK, ZOrder::NOTE)
end

# draws a horizontal line
def draw_side_line(x_pos, y_pos)
    Gosu.draw_line((x_pos + 18), y_pos, BLACK, (x_pos + 36), y_pos, BLACK, ZOrder::NOTE)
    Gosu.draw_line((x_pos + 18), (y_pos + 1), BLACK, (x_pos + 36), (y_pos + 1), BLACK, ZOrder::NOTE)
end

# draws a line for a note below or above the stave
def draw_sheet_line(x_pos, y_pos)
  Gosu.draw_line(x_pos - 10, y_pos + 10, BLACK, x_pos + 30, y_pos + 10, BLACK, ZOrder::NOTE)
end

# Takes a Note to draw and draws it at it's position
def draw_note(note)
  circle = Gosu::Image.new(Circle.new(10))
  if !note.is_rest
    circle.draw(note.x_pos, note.y_pos, ZOrder::NOTE, 1.0, 1.0, BLACK)
  end
  case note.note_type
  when NoteType::QUARTER
    if note.is_rest
      $quarterrest.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    elsif note.y_pos <= 416
      draw_up_line(note.x_pos, note.y_pos)
    elsif note.y_pos > 416
      draw_down_line(note.x_pos - 18, note.y_pos)
    end
  when NoteType::EIGTH
    if note.is_rest
      $eighthrest.draw(note.x_pos, 370, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    elsif note.y_pos <= 416
      draw_up_line(note.x_pos, note.y_pos)
      draw_side_line(note.x_pos, note.y_pos - 40)
    elsif note.y_pos > 416
      draw_down_line(note.x_pos - 18, note.y_pos)
      draw_side_line(note.x_pos - 34, note.y_pos + 50)
    end
  when NoteType::SIXTEENTH
    if note.is_rest
      $sixteenthrest.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    elsif note.y_pos <= 416
      draw_up_line(note.x_pos, note.y_pos)
      draw_side_line(note.x_pos, (note.y_pos - 40))
      draw_side_line(note.x_pos, (note.y_pos - 30))
    elsif note.y_pos > 416
      draw_down_line(note.x_pos - 18, note.y_pos)
      draw_side_line(note.x_pos - 34, note.y_pos + 50)
      draw_side_line(note.x_pos - 34, note.y_pos + 40)
    end
  end
  # draws lines below the stave based on the note position if the note is not a rest
  if !note.is_rest
    case note.y_pos
    when 191
      draw_sheet_line(note.x_pos, note.y_pos)
      draw_sheet_line(note.x_pos, note.y_pos + 50)
    when 216
      draw_sheet_line(note.x_pos, note.y_pos + 25)
    when 241
      draw_sheet_line(note.x_pos, note.y_pos)
    when 541
      draw_sheet_line(note.x_pos, note.y_pos)
    when 566
      draw_sheet_line(note.x_pos, note.y_pos - 25)
    when 591
      draw_sheet_line(note.x_pos, note.y_pos)
      draw_sheet_line(note.x_pos, note.y_pos - 50)
    when 616
      draw_sheet_line(note.x_pos, note.y_pos - 25)
      draw_sheet_line(note.x_pos, note.y_pos - 75)
    when 641
      draw_sheet_line(note.x_pos, note.y_pos)
      draw_sheet_line(note.x_pos, note.y_pos - 50)
      draw_sheet_line(note.x_pos, note.y_pos - 100)
    when 666
      draw_sheet_line(note.x_pos, note.y_pos - 25)
      draw_sheet_line(note.x_pos, note.y_pos - 75)
      draw_sheet_line(note.x_pos, note.y_pos - 125)
    when 691
      draw_sheet_line(note.x_pos, note.y_pos)
      draw_sheet_line(note.x_pos, note.y_pos - 50)
      draw_sheet_line(note.x_pos, note.y_pos - 100)
      draw_sheet_line(note.x_pos, note.y_pos - 150)
    end
    # adds a sharp or a flat if selected if the note is not a rest
    if note.sharp
      $sharp.draw(note.x_pos - 20, note.y_pos, ZOrder::NOTE, scale_x = 0.015, scale_y = 0.015)
    end
    if note.flat
      $flat.draw(note.x_pos - 20, note.y_pos - 10, ZOrder::NOTE, scale_x = 0.008, scale_y = 0.008)
    end
  end
end

######################### END OF MUSIC_NOTES.RB CODE ######################

# draw a box around the currently selected ui item(s)
def draw_box(top_x)
  Gosu.draw_line(top_x, 45, BLACK, top_x + 50, 45, BLACK, ZOrder::UI)
  Gosu.draw_line(top_x + 50, 45, BLACK, top_x + 50, 125, BLACK, ZOrder::UI)
  Gosu.draw_line(top_x + 50, 125, BLACK, top_x, 125, BLACK, ZOrder::UI)
  Gosu.draw_line(top_x, 125, BLACK, top_x, 45, BLACK, ZOrder::UI)
end

# draw a pointer that shows the note the sheet music is currently playing
def draw_pointer()
  if $sheet_music_playing
    Gosu.draw_line($pointer_position + 10, 170, BLACK, $pointer_position + 10, 700, BLACK, ZOrder::NOTE)
  end
end

##### MOUSE LEFT SELECTOR FUNCTIONS AREA #####

def main_selector(mouse_x, mouse_y)
  if mouse_y < 125
    if mouse_y > 35
      top_ui_actions(mouse_x)
    end
  elsif mouse_y >= 187.5
    create_note(mouse_x, mouse_y)
  end
end

def top_ui_actions(mouse_x)
  case mouse_x
  when 25..100
    play_sheet_music()
  when 150..225
    stop_sheet_music()
  when 260..340
    pause_sheet_music()
  when 390..420
    select_note(NoteType::QUARTER)
    $rest_selected = false
  when 490..520
    select_note(NoteType::EIGTH)
    $rest_selected = false
  when 590..620
    select_note(NoteType::SIXTEENTH)
    $rest_selected = false
  when 690..750
    if !$sharp_selected
      $sharp_selected = true
    elsif $sharp_selected
      $sharp_selected = false
    end
    $flat_selected = false
  when 790..830
    if !$flat_selected
      $flat_selected = true
    elsif $flat_selected
      $flat_selected = false
    end
    $sharp_selected = false
  when 890..940
    select_note(NoteType::QUARTER)
    $rest_selected = true
  when 990..1040
    select_note(NoteType::EIGTH)
    $rest_selected = true
  when 1090..1140
    select_note(NoteType::SIXTEENTH)
    $rest_selected = true
  when 1200..1300
    repeat_sheet_music()
  end

end

# control the bpm of the piece with the scroll wheel, between 10 and 300
def bpm_scroll(direction)
  if mouse_x >= 1440 and mouse_x <= 1550
    if mouse_y >= 65 and mouse_y <= 105
      if direction == true
        if $bpm < 300
          $bpm += 1
        end
      elsif direction == false
        if $bpm > 10
          $bpm -= 1
        end
      end
    end
  end
end

def play_sheet_music
  if $notes.length > 0
    $sheet_music_playing = true
    $pointer_position = 200
    a_note_found = false
    Thread.new do      
      while $pointer_position <= 1600 and $sheet_music_playing
        for notes in $notes
          if notes.x_pos == $pointer_position
            a_note_found = true
            if !notes.is_rest
              notes.sound.play
            end
            $last_note_type = notes.note_type
          end
        end
        time_to_wait = (SECONDS / $bpm) / $last_note_type
        if a_note_found
          sleep time_to_wait
          while $sheet_music_paused
            sleep 0.3
          end
        end
        $pointer_position += 80
        a_note_found = false
      end
      if $repeat and $sheet_music_playing and !$sheet_music_paused
        $pointer_position = 200
        play_sheet_music()
      end
    end
  end
end

def stop_sheet_music
  $sheet_music_playing = false
end

def pause_sheet_music
  if $sheet_music_playing
    if $sheet_music_paused
      $sheet_music_paused = false
    elsif !$sheet_music_paused
      $sheet_music_paused = true
    end
  end
end

def repeat_sheet_music
  if !$repeat
   $repeat = true
  elsif $repeat
    $repeat = false
  end
end

def select_note(note_number)
  $note_type_selected = note_number
end

def create_note(mouse_x, mouse_y)
  note_x = return_note_x(mouse_x)
  note_value_index = return_note_y(mouse_y)
  if mouse_x > 180
    if $sharp_selected
      note_value_index[1] -= 1
    elsif $flat_selected
      note_value_index[1] += 1
    end
    note = Note.new(note_x, note_value_index[0], $sharp_selected, $flat_selected, $note_type_selected, assign_note_sound(note_value_index[1]), $rest_selected)
    if !note.is_rest
      note.sound.play
    end
    for notes in $notes
      if notes.x_pos == note.x_pos
        notes.note_type = note.note_type
      end
      if notes.x_pos == note.x_pos and notes.y_pos == note.y_pos
        $notes.delete(notes)
      end
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        $notes.delete(notes)
      end
    end
    # For some reason this does not remove every single note when the for loop is called once or even twice, so it's done here twice and this works. I have no idea why this happens.
    for notes in $notes
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        $notes.delete(notes)
      end
    end
    for notes in $notes
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        $notes.delete(notes)
      end
    end
    for notes in $notes
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        $notes.delete(notes)
      end
    end
    $notes << note
  end
end

def remove_note(mouse_x, mouse_y)
  x_pos = return_note_x(mouse_x)
  y_pos = return_note_y(mouse_y)
  for note in $notes
    if x_pos == note.x_pos and y_pos[0] == note.y_pos
      $notes.delete(note)
    end
  end
end

# takes mouse_x coordinate and returns the x value for a Note
def return_note_x(mouse_x)
  index = 200
  note_value_found = false
  while note_value_found != true and index < 1600
   if mouse_x > index - 40 and mouse_x <= index + 40
      note_value_found = true    
   else
      index += 80
   end
  end
  return index
end

# takes mouse_y coordinate and returns the y value for a Note as well as the note associated with it
def return_note_y(mouse_y)
  index = 200
  value = 1
  note_value_found = false
  while note_value_found != true and index < 700
    if mouse_y > index - 12.5 and mouse_y <= index + 12.5
      note_value_found = true
    #Fb and Cb are not real notes, so this adds 1 less value when jumping whole notes if the next note would be an E or a B
    elsif index == 200 or index == 300 or index == 375 or index == 475 or index == 550 or index == 650
      index += 25
      value += 1
    else
      index += 25
      value += 2
    end
  end
  return [index - 9, value]
end

# takes note value and assigns it a string for the sample to be read using
def assign_note_sound(note_value)
  note_array = ["Db5", "C5", "B4", "Bb4", "A4", "Ab4", "G4", "Gb4", "F4", "E4", "Eb4", "D4", "Db4", "C4", "B3", "Bb3", "A3", "Ab3", "G3", "Gb3", "F3", "E3", "Eb3", "D3", "Db3", "C3", "B2", "Bb2", "A2", "Ab2", "G2", "Gb2", "F2", "E2", "Eb2", "D2", "Db2"]
  return note_array[note_value]
end

class MusicNotesMain < Gosu::Window

	def initialize
      #window size
	  	super 1600, 800, false, 5
	  	self.caption = "MusicNotes"
	end

  #draw the white background
  def draw_background
    Gosu.draw_quad(0, 0, WHITE, 1600, 0, WHITE, 0, 800, WHITE, 1600, 800, WHITE, ZOrder::BACKGROUND, mode =:default)
  end

  #draw the ui components
  def draw_ui
    #top and bottom panels
    Gosu.draw_quad(0, 0, UI_COLOUR, 1600, 0, UI_COLOUR, 0, 150, UI_COLOUR, 1600, 150, UI_COLOUR, ZOrder::UI)
    Gosu.draw_quad(0, 750, UI_COLOUR, 1600, 750, UI_COLOUR, 0, 800, UI_COLOUR, 1600, 800, UI_COLOUR, ZOrder::UI)
    # play, stop, repeat and pause buttons
    Gosu.draw_triangle(100, 80, BLACK, 25, 125, BLACK, 25, 40, BLACK, ZOrder::UI)
    Gosu.draw_quad(150, 50, BLACK, 225, 50, BLACK, 225, 125, BLACK, 150, 125, BLACK, ZOrder::UI)
    Gosu.draw_quad(275, 50, BLACK, 300, 50, BLACK, 300, 125, BLACK, 275, 125, BLACK, ZOrder::UI)
    Gosu.draw_quad(315, 50, BLACK, 340, 50, BLACK, 340, 125, BLACK, 315, 125, BLACK, ZOrder::UI)
    $repeatsymbol.draw(NOTES_UI_START + 800, 70, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    # note selection options
    ui_quarter = Note.new(NOTES_UI_START, 100, false, false, NoteType::QUARTER, "C5", false)
    ui_eigth = Note.new(NOTES_UI_START + 100, 100, false, false, NoteType::EIGTH, "C5", false)
    ui_sixteenth = Note.new(NOTES_UI_START + 200, 100, false, false, NoteType::SIXTEENTH, "C5", false)
    draw_note(ui_quarter)
    draw_note(ui_eigth)
    draw_note(ui_sixteenth)
    $sharp.draw(NOTES_UI_START + 300, 70, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    $flat.draw(NOTES_UI_START + 400, 60, ZOrder::UI, scale_x = 0.015, scale_y = 0.015)
    $quarterrest.draw(NOTES_UI_START + 500, 56, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    $eighthrest.draw(NOTES_UI_START + 600, 30, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    $sixteenthrest.draw(NOTES_UI_START + 700, 50, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    #bpm, and bottom of screen fonts
    Gosu.draw_quad(1440, 65, WHITE, 1550, 65, WHITE, 1550, 105, WHITE, 1440, 105, WHITE, ZOrder::UI)
    font = Gosu::Font.new(30)
    font.draw_text("BPM:", NOTES_UI_START + 950, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    font.draw_text($bpm, NOTES_UI_START + 1050, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    font.draw_text("MusicNotes: A simple music notation software.", 50, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    font.draw_text("Made by Donovan Quilty", 1200, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    font.draw_text("Loop", 1220, 40, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
  end

  #draw the blank sheet music
  def draw_sheet
    Gosu.draw_line(0, 300, BLACK, 1600, 300, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 350, BLACK, 1600, 350, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 400, BLACK, 1600, 400, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 450, BLACK, 1600, 450, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 500, BLACK, 1600, 500, BLACK, ZOrder::SHEET)
    #trebleclef
    trebleclef = Gosu::Image.new("images/trebleclef.png")
    trebleclef.draw(10, 250, ZOrder::SHEET, scale_x = 0.2, scale_y = 0.2)
    #start of sheet music
    Gosu.draw_quad(170, 300, BLACK, 175, 300, BLACK, 170, 500, BLACK, 175, 500, BLACK, ZOrder::SHEET)
  end

  #draw a border around the note currently selected in the UI
  def draw_selected
    case $note_type_selected
    when NoteType::QUARTER
      if $rest_selected
        draw_box(NOTES_UI_START + 492)
      else
        draw_box(NOTES_UI_START - 8)
      end
    when NoteType::EIGTH
      if $rest_selected
        draw_box(NOTES_UI_START + 592)
      else
        draw_box(NOTES_UI_START + 92)
      end
    when NoteType::SIXTEENTH
      if $rest_selected
        draw_box(NOTES_UI_START + 692)
      else
        draw_box(NOTES_UI_START + 192)
      end
    end
    if $repeat
      Gosu.draw_line(1200, 125, BLACK, 1300, 125, BLACK, ZOrder::UI)
    end
    if $sheet_music_paused
      Gosu.draw_line(270, 130, BLACK, 345, 130, BLACK, ZOrder::UI)
      Gosu.draw_line(270, 131, BLACK, 345, 131, BLACK, ZOrder::UI)
    end
  end

  
  def draw_sharp_or_flat_selection
    if $sharp_selected
      draw_box(NOTES_UI_START + 296)
    elsif $flat_selected
      draw_box(NOTES_UI_START + 392)
    end
  end

  def update
        
  end



  def draw
    draw_background()
    draw_ui()
    draw_sheet()
    for note in $notes
      draw_note(note)
    end
    draw_selected()
    draw_sharp_or_flat_selection()
    draw_pointer()
  end

  def needs_cursor?; true; end

  def button_down(id)
    case id
    when Gosu::MsLeft
      main_selector(mouse_x, mouse_y)
    when Gosu::MsWheelUp
      bpm_scroll(true)
    when Gosu::MsWheelDown
      bpm_scroll(false)
    when Gosu::MsRight
      remove_note(mouse_x, mouse_y)
    end
  end

end

#loop through update and draw
MusicNotesMain.new.show
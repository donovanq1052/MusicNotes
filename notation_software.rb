require 'rubygems'
require 'gosu'

module ZOrder
  BACKGROUND, UI, SHEET, NOTE = *0..3
end

module NoteType
  QUARTER, EIGTH, SIXTEENTH = *1..3
end

UI_COLOUR = Gosu::Color.new(0xFF1EB1FA)
BLACK = Gosu::Color::BLACK
WHITE = Gosu::Color::WHITE
SECONDS = 60.0
NOTES_UI_START = 400
SHARP = Gosu::Image.new("images/sharpsymbol.png")
FLAT = Gosu::Image.new("images/flatsymbol.png")
QUARTER_REST = Gosu::Image.new("images/quarterrest.png")
EIGTH_REST = Gosu::Image.new("images/eighthrest.png")
SIXTEENTH_REST = Gosu::Image.new("images/sixteenthrest.png")
REPEAT_SYMBOL = Gosu::Image.new("images/repeat.png")
BUTTONS = {
"Note Type Selected" => NoteType::QUARTER,
"Sharp Selected" => false, "Flat Selected" => false,
"Rest Selected" => false, "Repeat" => false,
"Sheet Music Paused" => false, "BPM" => 90,
"Pointer Position" => 0, "Sheet Music Playing" => false
}
NOTES = []

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

# initialize one circle to be used in draw_note
CIRCLE = Gosu::Image.new(Circle.new(10))

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
  if !note.is_rest
    CIRCLE.draw(note.x_pos, note.y_pos, ZOrder::NOTE, 1.0, 1.0, BLACK)
  end
  case note.note_type
  when NoteType::QUARTER
    if note.is_rest
      QUARTER_REST.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    elsif note.y_pos <= 416
      draw_up_line(note.x_pos, note.y_pos)
    elsif note.y_pos > 416
      draw_down_line(note.x_pos - 18, note.y_pos)
    end
  when NoteType::EIGTH
    if note.is_rest
      EIGTH_REST.draw(note.x_pos, 370, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    elsif note.y_pos <= 416
      draw_up_line(note.x_pos, note.y_pos)
      draw_side_line(note.x_pos, note.y_pos - 40)
    elsif note.y_pos > 416
      draw_down_line(note.x_pos - 18, note.y_pos)
      draw_side_line(note.x_pos - 34, note.y_pos + 50)
    end
  when NoteType::SIXTEENTH
    if note.is_rest
      SIXTEENTH_REST.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
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
      SHARP.draw(note.x_pos - 20, note.y_pos, ZOrder::NOTE, scale_x = 0.015, scale_y = 0.015)
    end
    if note.flat
      FLAT.draw(note.x_pos - 20, note.y_pos - 10, ZOrder::NOTE, scale_x = 0.008, scale_y = 0.008)
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
  if BUTTONS["Sheet Music Playing"]
    Gosu.draw_line(BUTTONS["Pointer Position"] + 10, 170, BLACK, BUTTONS["Pointer Position"] + 10, 700, BLACK, ZOrder::NOTE)
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
    BUTTONS["Rest Selected"] = false
  when 490..520
    select_note(NoteType::EIGTH)
    BUTTONS["Rest Selected"] = false
  when 590..620
    select_note(NoteType::SIXTEENTH)
    BUTTONS["Rest Selected"] = false
  when 690..750
    if !BUTTONS["Sharp Selected"]
      BUTTONS["Sharp Selected"] = true
    elsif BUTTONS["Sharp Selected"]
      BUTTONS["Sharp Selected"] = false
    end
    BUTTONS["Flat Selected"] = false
  when 790..830
    if !BUTTONS["Flat Selected"]
      BUTTONS["Flat Selected"] = true
    elsif BUTTONS["Flat Selected"]
      BUTTONS["Flat Selected"] = false
    end
    BUTTONS["Sharp Selected"] = false
  when 890..940
    select_note(NoteType::QUARTER)
    BUTTONS["Rest Selected"] = true
  when 990..1040
    select_note(NoteType::EIGTH)
    BUTTONS["Rest Selected"] = true
  when 1090..1140
    select_note(NoteType::SIXTEENTH)
    BUTTONS["Rest Selected"] = true
  when 1200..1300
    repeat_sheet_music()
  end

end

# control the bpm of the piece with the scroll wheel, between 10 and 300
def bpm_scroll(direction)
  if mouse_x >= 1440 and mouse_x <= 1550
    if mouse_y >= 65 and mouse_y <= 105
      if direction == true
        if BUTTONS["BPM"] < 300
          BUTTONS["BPM"] += 1
        end
      elsif direction == false
        if BUTTONS["BPM"] > 10
          BUTTONS["BPM"] -= 1
        end
      end
    end
  end
end

def play_sheet_music
  if NOTES.length > 0
    BUTTONS["Sheet Music Playing"] = true
    BUTTONS["Pointer Position"] = 200
    last_note_type = NoteType::QUARTER
    a_note_found = false
    Thread.new do      
      while BUTTONS["Pointer Position"] <= 1600 and BUTTONS["Sheet Music Playing"]
        for notes in NOTES
          if notes.x_pos == BUTTONS["Pointer Position"]
            a_note_found = true
            if !notes.is_rest
              notes.sound.play
            end
            last_note_type = notes.note_type
          end
        end
        time_to_wait = (SECONDS / BUTTONS["BPM"]) / last_note_type
        if a_note_found
          sleep time_to_wait
          while BUTTONS["Sheet Music Paused"]
            sleep 0.3
          end
        end
        BUTTONS["Pointer Position"] += 80
        a_note_found = false
      end
      if BUTTONS["Repeat"] and BUTTONS["Sheet Music Playing"] and !BUTTONS["Sheet Music Paused"]
        BUTTONS["Pointer Position"] = 200
        play_sheet_music()
      end
    end
  end
end

def stop_sheet_music
  BUTTONS["Sheet Music Playing"] = false
end

def pause_sheet_music
  if BUTTONS["Sheet Music Playing"]
    if BUTTONS["Sheet Music Paused"]
      BUTTONS["Sheet Music Paused"] = false
    elsif !BUTTONS["Sheet Music Paused"]
      BUTTONS["Sheet Music Paused"] = true
    end
  end
end

def repeat_sheet_music
  if !BUTTONS["Repeat"]
    BUTTONS["Repeat"] = true
  elsif BUTTONS["Repeat"]
    BUTTONS["Repeat"] = false
  end
end

def select_note(note_number)
  BUTTONS["Note Type Selected"] = note_number
end

def create_note(mouse_x, mouse_y)
  note_x = return_note_x(mouse_x)
  note_value_index = return_note_y(mouse_y)
  if mouse_x > 180
    if BUTTONS["Sharp Selected"]
      note_value_index[1] -= 1
    elsif BUTTONS["Flat Selected"]
      note_value_index[1] += 1
    end
    note = Note.new(note_x, note_value_index[0], BUTTONS["Sharp Selected"], BUTTONS["Flat Selected"], BUTTONS["Note Type Selected"], assign_note_sound(note_value_index[1]), BUTTONS["Rest Selected"])
    if !note.is_rest
      note.sound.play
    end
    for notes in NOTES
      if notes.x_pos == note.x_pos
        notes.note_type = note.note_type
      end
      if notes.x_pos == note.x_pos and notes.y_pos == note.y_pos
        NOTES.delete(notes)
      end
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        NOTES.delete(notes)
      end
    end
    # For some reason this does not remove every single note when the for loop is called once or even twice, so it's done here twice and this works. I have no idea why this happens.
    for notes in NOTES
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        NOTES.delete(notes)
      end
    end
    for notes in NOTES
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        NOTES.delete(notes)
      end
    end
    for notes in NOTES
      if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
        NOTES.delete(notes)
      end
    end
    NOTES << note
  end
end

def remove_note(mouse_x, mouse_y)
  x_pos = return_note_x(mouse_x)
  y_pos = return_note_y(mouse_y)
  for note in NOTES
    if x_pos == note.x_pos and y_pos[0] == note.y_pos
      NOTES.delete(note)
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
	  	super 1600, 800
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
    REPEAT_SYMBOL.draw(NOTES_UI_START + 800, 70, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    # note selection options
    ui_quarter = Note.new(NOTES_UI_START, 100, false, false, NoteType::QUARTER, "C5", false)
    ui_eigth = Note.new(NOTES_UI_START + 100, 100, false, false, NoteType::EIGTH, "C5", false)
    ui_sixteenth = Note.new(NOTES_UI_START + 200, 100, false, false, NoteType::SIXTEENTH, "C5", false)
    draw_note(ui_quarter)
    draw_note(ui_eigth)
    draw_note(ui_sixteenth)
    SHARP.draw(NOTES_UI_START + 300, 70, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    FLAT.draw(NOTES_UI_START + 400, 60, ZOrder::UI, scale_x = 0.015, scale_y = 0.015)
    QUARTER_REST.draw(NOTES_UI_START + 500, 56, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    EIGTH_REST.draw(NOTES_UI_START + 600, 30, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    SIXTEENTH_REST.draw(NOTES_UI_START + 700, 50, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    #bpm, and bottom of screen fonts
    Gosu.draw_quad(1440, 65, WHITE, 1550, 65, WHITE, 1550, 105, WHITE, 1440, 105, WHITE, ZOrder::UI)
    font = Gosu::Font.new(30)
    font.draw_text("BPM:", NOTES_UI_START + 950, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    font.draw_text(BUTTONS["BPM"], NOTES_UI_START + 1050, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
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
    case BUTTONS["Note Type Selected"]
    when NoteType::QUARTER
      if BUTTONS["Rest Selected"]
        draw_box(NOTES_UI_START + 492)
      else
        draw_box(NOTES_UI_START - 8)
      end
    when NoteType::EIGTH
      if BUTTONS["Rest Selected"]
        draw_box(NOTES_UI_START + 592)
      else
        draw_box(NOTES_UI_START + 92)
      end
    when NoteType::SIXTEENTH
      if BUTTONS["Rest Selected"]
        draw_box(NOTES_UI_START + 692)
      else
        draw_box(NOTES_UI_START + 192)
      end
    end
    if BUTTONS["Repeat"]
      Gosu.draw_line(1200, 125, BLACK, 1300, 125, BLACK, ZOrder::UI)
    end
    if BUTTONS["Sheet Music Paused"]
      Gosu.draw_line(270, 130, BLACK, 345, 130, BLACK, ZOrder::UI)
      Gosu.draw_line(270, 131, BLACK, 345, 131, BLACK, ZOrder::UI)
    end
  end

  
  def draw_sharp_or_flat_selection
    if BUTTONS["Sharp Selected"]
      draw_box(NOTES_UI_START + 296)
    elsif BUTTONS["Flat Selected"]
      draw_box(NOTES_UI_START + 392)
    end
  end

  def update
        
  end



  def draw
    draw_background()
    draw_ui()
    draw_sheet()
    for note in NOTES
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
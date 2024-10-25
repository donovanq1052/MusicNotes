require 'rubygems'
require 'gosu'
require './circle'

# a record Note that stores the values of a single note
class Note
  attr_accessor :x_pos, :y_pos, :sharp, :flat, :note_type, :note, :sound, :is_rest
end

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
TREBLECLEF = Gosu::Image.new("images/trebleclef.png")
FONT = Gosu::Font.new(30)
CIRCLE = Gosu::Image.new(Circle.new(10))
NOTE_ARRAY = ["Db5", "C5", "B4", "Bb4", "A4", "Ab4", "G4", "Gb4", "F4", "E4", "Eb4", "D4", "Db4", "C4", "B3", "Bb3", "A3", "Ab3", "G3", "Gb3", "F3", "E3", "Eb3", "D3", "Db3", "C3", "B2", "Bb2", "A2", "Ab2", "G2", "Gb2", "F2", "E2", "Eb2", "D2", "Db2"]
BUTTONS = {
"Note Type Selected" => NoteType::QUARTER,
"Sharp Selected" => false, "Flat Selected" => false,
"Rest Selected" => false, "Repeat" => false,
"Sheet Music Paused" => false, "BPM" => 90,
"Pointer Position" => 0, "Sheet Music Playing" => false,
"Saved" => "Save"
}
NOTES = []
###### create notes to be drawn in the UI menu \/ #########
UI_QUARTER = Note.new()
UI_EIGTH = Note.new()
UI_SIXTEENTH = Note.new()

def setup_ui_notes(note, offset, note_type)
  note.x_pos = NOTES_UI_START + offset
  note.y_pos = 100
  note.note_type = note_type
end

setup_ui_notes(UI_QUARTER, 0, NoteType::QUARTER)
setup_ui_notes(UI_EIGTH, 100, NoteType::EIGTH)
setup_ui_notes(UI_SIXTEENTH, 200, NoteType::SIXTEENTH)
######## create notes to be drawn in the UI menu /\ #######

########## DRAWING A NOTE ##########

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

# takes a note, and boolean previous_note_found from draw_connecting_note_line
# draws different parts of the note (line going up, lines going sideways)
# based on type of note and notes in front of or behind it
def draw_parts_of_note(note, previous_note_found)
  if note.y_pos <= 416
    draw_up_line(note.x_pos, note.y_pos)
    case note.note_type
    when NoteType::EIGTH
      if !previous_note_found
        draw_side_line(note.x_pos, note.y_pos - 40)
      end
    when NoteType::SIXTEENTH
      if !previous_note_found
        draw_side_line(note.x_pos, note.y_pos - 40)
        draw_side_line(note.x_pos, note.y_pos - 30)
      end
    end
  elsif note.y_pos > 416
    draw_down_line(note.x_pos - 18, note.y_pos)
    note_in_front = false
    for note_ahead in NOTES
      if note.x_pos + 80 == note_ahead.x_pos and note.note_type == note_ahead.note_type and note.y_pos == note_ahead.y_pos and !note_ahead.is_rest
        note_in_front = true
      end
    end
    if !note_in_front and !previous_note_found
      case note.note_type
      when NoteType::EIGTH
        draw_side_line(note.x_pos - 34, note.y_pos + 50)
      when NoteType::SIXTEENTH
        draw_side_line(note.x_pos - 34, note.y_pos + 50)
        draw_side_line(note.x_pos - 34, note.y_pos + 40)
      end
    end
  end 
end

# draws a number of connecting lines depending on the note type
# if there's a note of the same type on the same y position in front of the note being drawn
# also calls to draw the connecting parts of the note
def draw_connecting_note_line(note)
  previous_note_found = false
  for previous_note in NOTES
    if note.x_pos - 80 == previous_note.x_pos and note.note_type == previous_note.note_type and note.y_pos == previous_note.y_pos and !previous_note.is_rest
      previous_note_found = true
      if note.y_pos <= 416
        Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 39, BLACK, note.x_pos + 20, note.y_pos - 39, BLACK, ZOrder::NOTE)
        Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 40, BLACK, note.x_pos + 20, note.y_pos - 40, BLACK, ZOrder::NOTE)
        if note.note_type != NoteType::QUARTER
          Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 29, BLACK, note.x_pos + 20, note.y_pos - 29, BLACK, ZOrder::NOTE)
          Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 30, BLACK, note.x_pos + 20, note.y_pos - 30, BLACK, ZOrder::NOTE)
        end
        if note.note_type == NoteType::SIXTEENTH
          Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 19, BLACK, note.x_pos + 20, note.y_pos - 19, BLACK, ZOrder::NOTE)
          Gosu.draw_line(previous_note.x_pos + 18, previous_note.y_pos - 20, BLACK, note.x_pos + 20, note.y_pos - 20, BLACK, ZOrder::NOTE)
        end
      elsif note.y_pos > 416
        Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 48, BLACK, note.x_pos, note.y_pos + 48, BLACK, ZOrder::NOTE)
        Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 49, BLACK, note.x_pos, note.y_pos + 49, BLACK, ZOrder::NOTE)
        if note.note_type != NoteType::QUARTER
          Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 38, BLACK, note.x_pos, note.y_pos + 38, BLACK, ZOrder::NOTE)
          Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 39, BLACK, note.x_pos, note.y_pos + 39, BLACK, ZOrder::NOTE)
        end
        if note.note_type == NoteType::SIXTEENTH
          Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 28, BLACK, note.x_pos, note.y_pos + 28, BLACK, ZOrder::NOTE)
          Gosu.draw_line(previous_note.x_pos, previous_note.y_pos + 29, BLACK, note.x_pos, note.y_pos + 29, BLACK, ZOrder::NOTE)
        end
      end
    end
  end
  draw_parts_of_note(note, previous_note_found)
end

# Takes a Note to draw and draws it at it's position
def draw_note(note)
  if !note.is_rest
    CIRCLE.draw(note.x_pos, note.y_pos, ZOrder::NOTE, 1.0, 1.0, BLACK)
    draw_connecting_note_line(note)
    # draws lines above or below the stave depending on the note position
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
  else
    # if it's a rest we just draw an image of the rest
    case note.note_type
    when NoteType::QUARTER
      QUARTER_REST.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    when NoteType::EIGTH
      EIGTH_REST.draw(note.x_pos, 370, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    when NoteType::SIXTEENTH
      SIXTEENTH_REST.draw(note.x_pos, 400, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    end
  end
end
######## DRAWING A NOTE #########

####### DRAWING UI COMPONENTS #########

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

######## DRAWING UI COMPONENTS ###########

##### BUTTON PRESS FUNCTIONS AREA #####

# calls a function with mouse_x based on the position of mouse_y
def main_selector(mouse_x, mouse_y)
  if mouse_y < 125
    if mouse_y > 35
      top_ui_actions(mouse_x)
    end
  elsif mouse_y >= 187.5 and mouse_y < 730
    create_note(mouse_x, mouse_y)
  elsif mouse_y >= 755
    bottom_ui_actions(mouse_x)
  end
end

# either toggles a boolean in BUTTONS or calls a function based on where mouse_x currently is
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

# plays all notes on the screen in order
def play_sheet_music
  if !BUTTONS["Sheet Music Playing"]
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
              if notes.note_type == NoteType::SIXTEENTH
                last_note_type += 1
              end
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
end

# stops the sheet music from being played
def stop_sheet_music
  BUTTONS["Sheet Music Playing"] = false
end

# toggles whether the sheet music should be paused
def pause_sheet_music
  if BUTTONS["Sheet Music Playing"]
    if BUTTONS["Sheet Music Paused"]
      BUTTONS["Sheet Music Paused"] = false
    elsif !BUTTONS["Sheet Music Paused"]
      BUTTONS["Sheet Music Paused"] = true
    end
  end
end

# toggles whether the sheet music should be repeated
def repeat_sheet_music
  if !BUTTONS["Repeat"]
    BUTTONS["Repeat"] = true
  elsif BUTTONS["Repeat"]
    BUTTONS["Repeat"] = false
  end
end

# indicates the current note type selected
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
    note = Note.new()
    note.x_pos = note_x
    note.y_pos = note_value_index[0]
    note.sharp = BUTTONS["Sharp Selected"]
    note.flat = BUTTONS["Flat Selected"]
    note.note_type = BUTTONS["Note Type Selected"]
    note.note = NOTE_ARRAY[note_value_index[1]]
    note.is_rest = BUTTONS["Rest Selected"]
    if !note.is_rest
      note.sound = Gosu::Sample.new("pianonotes/#{note.note}.mp3")
      note.sound.play
    else
      note.sound = nil
    end
    for notes in NOTES
      if notes.x_pos == note.x_pos
        notes.note_type = note.note_type
      end
      if notes.x_pos == note.x_pos and notes.y_pos == note.y_pos
        NOTES.delete(notes)
      end
    end
    # For some reason this does not remove every single note when the for loop is called once or even twice, so i've put it in a while loop to run 10 times. I don't know why this happens but it works
    index = 10
    while index > 0
      for notes in NOTES
        if notes.x_pos == note.x_pos and (notes.is_rest or note.is_rest)
          NOTES.delete(notes)
        end
      end
      index -= 1
    end
    NOTES << note
  end
end

# removes a note from the stave
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

# should we save or load the sheet music? or clear the screen?
def bottom_ui_actions(x_pos)
  case x_pos
  when 700..775
    save_sheet_music()
  when 900..975
    load_sheet_music()
  when 1100..1175
    clear_sheet_music()
  end
end

# saves the information of each note into a txt file
def save_sheet_music()
  save_file = File.new("savefile.txt", "w")
  save_file.puts(NOTES.length)
  for note in NOTES
    save_file.puts(note.x_pos)
    save_file.puts(note.y_pos)
    save_file.puts(note.sharp)
    save_file.puts(note.flat)
    save_file.puts(note.note_type)
    save_file.puts(note.is_rest)
  end
  Thread.new do
    BUTTONS["Saved"] = "Music Saved!"
    sleep(2)
    BUTTONS["Saved"] = "Save"
  end
end

# loads the notes in the savefile onto the screen
def load_sheet_music()
  load_file = File.new("savefile.txt", "r")
  index = load_file.gets.to_i()
  counter = 0
  for note in NOTES
    NOTES.delete(note)
  end
  while counter < index
    x_pos = load_file.gets.to_i()
    y_pos = load_file.gets.to_i()
    sharp = convert_string_to_boolean(load_file.gets.chomp())
    flat = convert_string_to_boolean(load_file.gets.chomp())
    note_type = load_file.gets.to_i()
    note_value_index = return_note_y(y_pos)
    note = NOTE_ARRAY[note_value_index[1]]
    is_rest = convert_string_to_boolean(load_file.gets.chomp())
    new_note = Note.new(x_pos, note_value_index[0], sharp, flat, note_type, note, is_rest)
    NOTES << new_note
    counter += 1
  end
end

#evaluates whether a given string == "true", returns true if it is, or false if it isn't. Used to load sheet music
def convert_string_to_boolean(string)
  string == "true"
end

def clear_sheet_music()
  # for some reason again doing this once does not delete every note in NOTES
  # so I have wrapped it in a while loop
  while NOTES.length > 0
    for note in NOTES
     NOTES.delete(note)
    end
  end
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
    draw_note(UI_QUARTER)
    draw_note(UI_EIGTH)
    draw_note(UI_SIXTEENTH)
    SHARP.draw(NOTES_UI_START + 300, 70, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    FLAT.draw(NOTES_UI_START + 400, 60, ZOrder::UI, scale_x = 0.015, scale_y = 0.015)
    QUARTER_REST.draw(NOTES_UI_START + 500, 56, ZOrder::UI, scale_x = 0.1, scale_y = 0.1)
    EIGTH_REST.draw(NOTES_UI_START + 600, 30, ZOrder::UI, scale_x = 0.03, scale_y = 0.03)
    SIXTEENTH_REST.draw(NOTES_UI_START + 700, 50, ZOrder::UI, scale_x = 0.04, scale_y = 0.04)
    #bpm, and bottom of screen fonts
    Gosu.draw_quad(1440, 65, WHITE, 1550, 65, WHITE, 1550, 105, WHITE, 1440, 105, WHITE, ZOrder::UI)
    FONT.draw_text("BPM:", NOTES_UI_START + 950, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text(BUTTONS["BPM"], NOTES_UI_START + 1050, 70, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text("MusicNotes: A simple music notation software.", 10, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text("Made by Donovan Quilty", 1300, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text("Loop", 1220, 40, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text(BUTTONS["Saved"], 700, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text("Load", 900, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
    FONT.draw_text("Clear", 1100, 760, ZOrder::UI, scale_x = 1, scale_y = 1, BLACK)
  end

  #draw the blank sheet music
  def draw_sheet
    Gosu.draw_line(0, 300, BLACK, 1600, 300, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 350, BLACK, 1600, 350, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 400, BLACK, 1600, 400, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 450, BLACK, 1600, 450, BLACK, ZOrder::SHEET)
    Gosu.draw_line(0, 500, BLACK, 1600, 500, BLACK, ZOrder::SHEET)
    TREBLECLEF.draw(10, 250, ZOrder::SHEET, scale_x = 0.2, scale_y = 0.2)
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

  # draw a box around the sharp or flat UI symbols based on what is selected
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
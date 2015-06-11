class Loader
  attr_reader("game")
  attr_reader("modifier")

  def initialize(game, modifier)
    @game = game
    @modifer = modifier
  end

  def choose_and_load_file
    case game
      when "hex"
        self.load("/Users/dylanpratt/Documents/stuff/game_notes/hex_notes.rtf")
      when "magic"
        if modifier == "khans"
          self.load("/Users/dylanpratt/Documents/stuff/game_notes/khans.rtf")
        else
          self.load("/Users/dylanpratt/Documents/stuff/game_notes/magic_notes.rtf")
        end
      when "hearthstone"
        self.load("/Users/dylanpratt/Documents/stuff/game_notes/hearthstone_notes.rtf")
      else
        puts "Couldn't load file, unknown game type #{game}"
    end
  end
end
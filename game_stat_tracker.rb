# Public methods
def exists(object)
  object !=nil
end

# Public classes
class Deck
  attr_reader("record")
  attr_reader("archetype")
  attr_reader("color_combo")

  def initialize(data)
    # Given variables
    @colors = data[:colors]
    @type = data[:type]
    @record = data[:record]
    @description = data[:description]

    # Calculated variables
    # Create the archetype string, which needs to be standardized
    @archetype = ""
    @colors.each {|color| @archetype += color  }
    @archetype += " #{@type}"

    # Create the color_combo string ignoring lower case splashes
    @color_combo = ""
    @colors.each {|color| @color_combo += color if exists(/[[:upper:]]/.match(color))  }
  end

  def has_color?(given_color)
    @colors.any? {|color| color == given_color}
  end

  def is_type?(given_type)
    @type == given_type
  end

  def is_archetype?(given_type)
    @archetype == given_type
  end

  def is_color_combo?(given_combo)
    @color_combo == given_combo
  end

end

class Tracker
  attr_reader("game")

  def initialize(game)
    puts "Creating a tracker for #{game} \n\n"
    @game = game
    @decks = []
    @game_colors =
      case game
        when 'hex'
          ["R", "W", "B", "D", "S"]
        when 'magic'
          ["B", "U", "W", "G", "R"]
        else
          []
      end
    @game_deck_types =
      case game
        when 'hex'
          ["control", "aggro", "midrange", "bunnies", "dwarves"]
        when 'magic'
          ["control", "aggro", "midrange"]
        else
          []
      end
  end

  # TODO: for now just do stuff here, but later make these into functions, when I know how they should be divided better
  def load(file)
    # Fetch raw text from sample_hex_data
    text = File.read(file)

    # Make an array out of it
    lines = []
    text.each_line do |line|
      lines << line.chop
      end

    # TODO: support other types of files - check the kind of file and only do this if its rtf
    # Just get the lines after the rtf formatting
    first_line = nil
    meta_data_index = nil
    lines.each_with_index { |line, i|
      if match = line.match(/.*\\f0\\fs24\s\\cf0(.*)/)
        first_line = match[1]
        meta_data_index = i
        break
      end
    }

    # Cut off the metadata from the start
    if exists(meta_data_index)
      lines = lines[meta_data_index+1..-1]
    end

    # Add the first line that may have been shared with metadata
    if exists(first_line)
      lines.unshift(first_line)
    end

    # Just get the draft record lines
    start_index = nil
    end_index = nil
    lines.each_with_index { |line, i|
      if match = line.match(/draft\srecord/)
        start_index = i
      elsif line.match(/(\\'97){3,}/)
        end_index = i
        break
      end
    }
    if exists(start_index) and exists(end_index)
      lines = lines[start_index+1..end_index-1]
    end

    puts 'draft record:', lines

    lines.each { |line|
      # Strip the description
      if match = line.match(/(.*)\s-\s(.*)/)
        stripped_line = match[1]
        description = match[2]
      else
        stripped_line = line
        description = ''
      end
      # TODO: check if the letter is lowercase, and if so call it a splash (currently only looks for capital letters, so lowercase mean nothing. Possibly a good thing? (mono with a splash is basically mono, sorta. Maybe should have a "Rx" category...dunno))
      if match = stripped_line.match(/\s*(\w*)\s(\w*)\s.*(\d).*(\d)\s*(\S*)/)
        color_string = match[1]
        colors = color_string.scan(/\w/)
        colors.sort!
        rough_type = match[2]
        # Combine slang terms
        if rough_type.match(/mid/)
          type = "midrange"
        else
          type = rough_type
        end
        # TODO: check for '2' in the match and make byes 2 if its there
        has_bye = match[5].match(/bye/) != nil
        byes = has_bye ? 1 : 0
        record = {wins: match[3].to_i, losses: match[4].to_i, byes: byes}

        data = {
         colors: colors,
         type: type,
         record: record,
         description: description
        }
        @decks << Deck.new(data)
      end
    }

    generate_categories

  end

  def generate_categories
    @archetypes = @decks.map { |deck| deck.archetype }
    @archetypes.uniq!
    @color_combos = @decks.map { |deck| deck.color_combo }
    @color_combos.uniq!
  end

  def get_prop_name(value)
    case @game
      when 'hex'
        case value
          when 'R'
            "Ruby"
          when 'S'
            "Sapphire"
          when 'D'
            "Diamond"
          when 'B'
            "Blood"
          when 'W'
            "Wild"
          else
            # Just print the value given
            value
        end
      when 'magic'
        case color
          when 'R'
            "Red"
          when 'U'
            "Blue"
          when 'B'
            "Black"
          when 'W'
            "White"
          when 'G'
            "Green"
          else
            log "Error! Unknown color given", color
        end
      else
        log "Error! Unknown game given", @game
    end
  end

  def get_total(record_type, decks)
    total = 0
    decks.each { |deck|
      if record_type == 'all'
        total += deck.record[:wins]
        total += deck.record[:losses]
      else
        total += deck.record[record_type.to_sym]
      end
    }
    total
  end

  def get_percentage(num, den)
    ((num.to_f/den)*100).round
  end

  def get_win_rate(decks)
    get_percentage(get_total("wins", decks), get_total("all", decks))
  end

  def get_decks_of_prop(func, value)
    @decks.select {|deck| func.call(deck, value) }
  end

  def generate_data(filter_func, value)
    decks = get_decks_of_prop(filter_func, value)
    data = {
      win_rate: get_win_rate(decks),
      name: get_prop_name(value),
      frequency: decks.length
    }
    data
  end

  def sort_by_win_rate(given_data)
    # given_data.sort! {|data| data[:win_rate]}
    given_data.sort! do |a, b|
      a_wins = a[:win_rate]
      b_wins = b[:win_rate]
      if a_wins > b_wins
        1
      elsif a_wins < b_wins
        -1
      else
        0
      end
    end
    given_data.reverse!
    given_data
  end

  def print_data(possible_values, filter_func)
    deck_data = possible_values.map { |value| generate_data(filter_func, value) }
    deck_data = sort_by_win_rate(deck_data)
    total_matches = 0
    deck_data.each do |data|
      freq = data[:frequency]
      total_matches += freq
      frequency_percentage = get_percentage(freq, get_total_drafts_played)
      puts "#{data[:name]}: #{data[:win_rate]}%, #{freq.round}/#{get_total_drafts_played} drafts (#{frequency_percentage}%)"
    end
    # Return total matches, to be verified if necessary
    total_matches
  end

  def print_data_and_check_count(possible_values, filter_func)
    total_matches = print_data(possible_values, filter_func)
    # Make sure the total decks calculated is the number of drafts. Otherwise, we missed something
    draft_count = @decks.length
    puts "Error! There are #{draft_count} drafts recorded, but one of the analyzers came up with #{total_matches}" unless total_matches == draft_count
  end

  def calc_packs(record, include_byes)
    wins = record[:wins]
    # If we're to include byes, add them as wins
    wins += record[:byes] if include_byes
    if @game == 'hex'
      case wins
        when 0
          return 0
        when 1
          return 2
        when 2
          return 3
        when 3
          return 5
        else
          puts 'Error! Wins isnt 0, 1, 2 or 3', wins
      end
    end
  end

  def get_total_drafts_played
    @decks.length
  end

  def get_packs_won(type, include_byes)
    packs = 0
    if type == 'all'
      @decks.each { |deck|
        packs += calc_packs(deck.record, include_byes)
      }
      (packs.to_f/get_total_drafts_played).round(2)
    else
      puts 'Error! get_packs_earned type is unrecognized', type
    end
  end

  def print_overall_data
    win_rate = get_win_rate(@decks)
    puts "overall win rate: #{win_rate} \n"
    puts "#{get_total_drafts_played} drafts, avg #{get_packs_won('all', false)}/#{get_packs_won('all', true)} packs earned/won \n\n"
  end

  def print
    puts "#{@game} stats: "
    print_overall_data

    puts "Colors: Win Rate, Frequency"
    print_data(@game_colors, Proc.new {|deck, color| deck.has_color?(color) })

    puts "\nTypes: Win Rate, Frequency"
    print_data_and_check_count(@game_deck_types, Proc.new {|deck, type| deck.is_type?(type) })

    puts "\nColor Combos: Win Rate, Frequency"
    print_data_and_check_count(@color_combos, Proc.new {|deck, colors| deck.is_color_combo?(colors) })

    puts "\nArchetypes: Win Rate, Frequency"
    print_data_and_check_count(@archetypes, Proc.new {|deck, type| deck.is_archetype?(type) })

  end


end


puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new("hex")
tracker.load("/Users/dylanpratt/Documents/stuff/game_notes/hex_notes.rtf")

puts ''

tracker.print()


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

class Hero
  attr_reader("name")
  attr_reader("record")
  attr_reader("average_wins")
  attr_reader("frequency")
  attr_reader("twelves")

  def initialize(data)
    # Given variables
    @name = data[:name]
    @record = data[:record]
    @average_wins = calc_average_wins
    @twelves = calc_twelves
    @frequency = @record.length
  end

  def calc_average_wins
     @record.inject(:+).to_f / @record.length
  end

  def calc_twelves
    @record.count(12)
  end
end

class Tracker
  attr_reader("game")
  attr_reader("modifier")

  def initialize(game, modifier)
    puts "Creating a tracker for #{game} \n\n"
    @game = game
    @modifier = modifier
    if is_ccg?
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
            if modifier == 'm15'
              ["control", "aggro", "midrange", "convoke", "auras", "graveyard"]
            elsif modifier == 'khans'
              []
            else
              ["control", "aggro", "midrange"]
            end
          when 'magic-m15'
          else
            []
        end
    elsif game == "hearthstone"
      @heroes = []
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

    original_lines = lines

    # Just get the draft record lines for ccgs
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
    start_index = 0 if game == "hearthstone"
    if exists(start_index) and exists(end_index)
      lines = lines[start_index+1..end_index-1]
    end

    puts 'raw data:', lines
    if is_ccg?
      process_ccg_lines(lines)
      generate_categories
    else
      process_hearthstone_lines(lines)
    end

    # Follow command
    # Cut out the lines from the file and save them in a new file
    # if command == "purge"
    #   original_lines.slice!(start_index+1, end_index-start_index-1)
    #   do_purge(lines, original_lines)
    # end

  end

  def do_purge(lines, original_lines)
    file_name = case game
      when "hex"
        "/Users/dylanpratt/Documents/stuff/game_notes/new_hex_notes"
      when "magic"
        "/Users/dylanpratt/Documents/stuff/game_notes/new_magic_notes"
      when "hearthstone"
        "/Users/dylanpratt/Documents/stuff/game_notes/new_hearthstone_notes"
      else
        nil
    end
    File.open(file_name, "w+") do |file|
      file.write original_lines
    end
  end

  def process_hearthstone_lines(lines)
    lines.each { |line|
      if match = line.match(/(.*)\s*-\s*(.*)/)
        name = match[1]
        record = match[2]
        record = record.scan(/\d{1,2}/)
        record = record.map do |r|
          r.to_i
        end

        data = {
          name: name.strip,
          record: record
        }
        @heroes << Hero.new(data)
      end
    }
  end

  def process_ccg_lines(lines)
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
      reg_exp = support_provided_types? ? /\s*(\w*)\s(\w*)\s.*(\d).*(\d)\s*(\S*)/ : /\s*(\w*)\s.*(\d).*(\d)\s*(\S*)/
      if match = stripped_line.match(reg_exp)
        # Colors
        color_string = match[1]
        colors = color_string.scan(/\w/)
        colors.sort!

        # Types
        if support_provided_types?
          rough_type = match[2]
          # Combine slang terms
          if rough_type.match(/mid/)
            type = "midrange"
          else
            type = rough_type
          end
        else
          type = compute_type_from_colors(colors)
        end

        # Record
        if support_provided_types?
          wins = match[3].to_i
          losses = match[4].to_i
          has_bye = match[5].match(/bye/) != nil if support_byes?
        else
          wins = match[2].to_i
          losses = match[3].to_i
          has_bye = match[4].match(/bye/) != nil if support_byes?
        end
        byes = has_bye ? 1 : 0
        record = {wins: wins, losses: losses.to_i, byes: byes}

        data = {
         colors: colors,
         type: type,
         record: record,
         description: description
        }
        @decks << Deck.new(data)
      end
    }
  end

  def compute_type_from_colors(colors)
    if modifier == 'khans'
      'temp'
    else
      'unknown'
    end
  end

  def generate_categories
    @archetypes = @decks.map { |deck| deck.archetype }
    @archetypes.uniq!
    @color_combos = @decks.map { |deck| deck.color_combo }
    @color_combos.uniq!
  end

  def is_ccg?
    ["hex", "magic"].include? game
  end

  def support_provided_types?
    if modifier == 'khans'
      false
    else
      true
    end
  end

  def support_byes?
    game == 'hex' ? true : false
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
        case value
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
            value
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
    return 0 if num == 0 && den == 0
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
      frequency: decks.length,
      average_packs_won: get_packs_won(decks)
    }
    data
  end

  def sort_by_symbol(given_data, symbol)
    given_data.sort! do |a, b|
      a_wins = a[symbol]
      b_wins = b[symbol]
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

  def sort_hearthstone_data(given_data)
    given_data.sort! do |a, b|
      a_wins = a.average_wins
      b_wins = b.average_wins
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

  def print_data(section_name, possible_values, filter_func)
    puts "\n#{section_name}: Win %, Packs Won, Frequency"
    deck_data = possible_values.map { |value| generate_data(filter_func, value) }
    deck_data = sort_by_symbol(deck_data, :win_rate)
    total_matches = 0
    deck_data.each do |data|
      freq = data[:frequency]
      total_matches += freq
      frequency_percentage = get_percentage(freq, get_total_drafts_played)
      puts "#{data[:name]}: #{data[:win_rate]}%, #{data[:average_packs_won]}, #{freq.round}/#{get_total_drafts_played} drafts (#{frequency_percentage}%)"
    end
    # Return total matches, to be verified if necessary
    total_matches
  end

  def print_data_and_check_count(section_name, possible_values, filter_func)
    total_matches = print_data(section_name, possible_values, filter_func)
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
    if @game == 'magic'
      losses = record[:losses]
      case wins
        when 0
          return 0
        when 1
          return 0
        when 2
          return losses==1 ? 4 : 6
        when 3
          return 8
        else
          puts 'Error! Wins isnt 0, 1, 2 or 3', wins
      end
    end
  end

  def get_total_drafts_played
    @decks.length
  end

  def get_packs_won(decks, include_byes = false)
    packs = 0
    decks.each { |deck|
      packs += calc_packs(deck.record, include_byes)
    }
    (packs.to_f/(decks.length)).round(2)
  end

  def total_arenas
    total = 0
    @heroes.each do |hero|
      total += hero.frequency
    end
    total
  end

  def hearthstone_total_average
    total_average = 0
    @heroes.each do |hero|
      total_average += hero.average_wins
    end
    (total_average / @heroes.length).round(2)
  end

  def print_overall_data
    if is_ccg?
      win_rate = get_win_rate(@decks)
      puts "overall win rate: #{win_rate}%"
    end
    case game
      when 'hex'
        puts "#{get_total_drafts_played} drafts, avg #{get_packs_won(@decks, false)}/#{get_packs_won(@decks, true)} packs earned/won"
      when 'magic'
        puts "#{get_total_drafts_played} drafts, avg #{get_packs_won(@decks, false)} packs won"
      when 'hearthstone'
        puts "#{total_arenas} arenas played, avg of #{hearthstone_total_average} games won \n\n"
    end
  end

  def print_ccg_data
    print_data('Colors', @game_colors, Proc.new {|deck, color| deck.has_color?(color) })
    print_data_and_check_count('Types', @game_deck_types, Proc.new {|deck, type| deck.is_type?(type) })
    print_data_and_check_count('Color Combos', @color_combos, Proc.new {|deck, colors| deck.is_color_combo?(colors) })
  end

  def print_archetypes
    print_data_and_check_count('Archetypes', @archetypes, Proc.new {|deck, type| deck.is_archetype?(type) })
  end

  def print_hearthstone_data
    puts "Hero, Avg Wins, Frequency"
    heroes = sort_hearthstone_data(@heroes)
    heroes.each do |hero|
      freq = hero.frequency
      frequency_percentage = get_percentage(freq, total_arenas)
      puts "#{hero.name}: #{hero.average_wins.round(2)}, #{freq.round}/#{total_arenas} arenas (#{frequency_percentage}%), #{hero.twelves} twelves"
    end
  end

  def print_results
    puts "#{@game} stats: "
    print_overall_data
    if is_ccg?
      print_ccg_data
    else
      print_hearthstone_data
    end
  end

  def choose_and_load_file
    case game
      when "hex"
        self.load("/Users/dylanpratt/Documents/stuff/game_notes/hex_notes.rtf")
      when "magic"
        self.load("/Users/dylanpratt/Documents/stuff/game_notes/magic_notes.rtf")
      when "hearthstone"
        self.load("/Users/dylanpratt/Documents/stuff/game_notes/hearthstone_notes.rtf")
      else
        puts "Couldn't load file, unknown game type #{game}"
    end
  end

end

# Get the game type from arguments given (use hex as default)
game = ARGV[0] || "magic"
modifier = ARGV[1]

puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new(game, modifier)
tracker.choose_and_load_file

puts ''

tracker.print_results()


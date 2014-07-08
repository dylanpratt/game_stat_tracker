# Public methods
def exists(object)
  object !=nil
end

# Public classes
class Deck
  attr_reader("colors")
  attr_reader("type")
  attr_reader("record")

  def initialize(colors, type, record)
    @colors = colors
    @type = type
    @record = record
  end
end

class Tracker
  attr_reader("game")

  def initialize(game)
    puts "Creating a tracker for #{game} \n\n"
    @game = game
    @decks = []
    @gameColors =
      case game
        when 'hex'
          ["R", "W", "B", "D", "S"]
        when 'magic'
          ["B", "U", "W", "G", "R"]
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
    firstLine = nil
    metaDataIndex = nil
    lines.each_with_index { |line, i|
      if match = line.match(/.*\\f0\\fs24\s\\cf0(.*)/)
        firstLine = match[1]
        metaDataIndex = i
        break
      end
    }

    # Cut off the metadata from the start
    if exists(metaDataIndex)
      lines = lines[metaDataIndex+1..-1]
    end

    # Add the first line that may have been shared with metadata
    if exists(firstLine)
      lines.unshift(firstLine)
    end

    puts 'data:', lines

    lines.each { |line|
      # TODO: check if the letter is lowercase, and if so call it a splash
      if match = line.match(/\s*(\w*)\s(\w*)\s.*(\d).*(\d)\s*(\S*)/)
        colorString = match[1]
        colors = colorString.scan(/\w/)
        roughType = match[2]
        # Combine slang terms
        if roughType.match(/mid/)
          type = "midrange"
        else
          type = roughType
        end
        # TODO: check for '2' in the match and make byes 2 if its there
        hasBye = match[5].match(/bye/) != nil
        byes = hasBye ? 1 : 0
        record = {wins: match[3].to_i, losses: match[4].to_i, byes: byes}
        @decks << Deck.new(colors, type, record)
      end
    }
    # puts '@decks', @decks.inspect
    # puts '@decks.length', @decks.length
  end

  def getDecksOfColor(givenColor)
    @decks.select {|deck| deck.colors.any? {|color| color == givenColor} }
  end

  def getTotal(recordType, color)
    total = 0
    decks = color=='all' ? @decks : getDecksOfColor(color)
    decks.each { |deck|
      if recordType == 'all'
        total += deck.record[:wins]
        total += deck.record[:losses]
      else
        total += deck.record[recordType.to_sym]
      end
    }
    total
  end

  def getPercentage(num, den)
    ((num.to_f/den)*100).round
  end

  def winRate(color)
    percentage = getPercentage(getTotal("wins", color), getTotal("all", color))
    "#{percentage}%"
  end

  def getColorName(color)
    case @game
      when 'hex'
        case color
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
            log "Error! Unknown color given", color
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

  def calcColorData(color)
    data = {
      winRate: winRate(color),
      name: getColorName(color),
      frequency: getTotal('all', color)
    }
    data
  end

  def printColorsData
    puts "Colors: Win Rate"
    colorsData = @gameColors.map { |color|
      calcColorData(color)
    }
    # TODO: turn me into a generic function, since everything will be sorted by win rate
    colorsData.sort_by! {|data|
      data[:winRate]
    }
    colorsData.reverse!
    colorsData.each {|data|
      totalDrafts = getTotal('all', 'all')
      frequencyPercentage = getPercentage(data[:frequency], totalDrafts)
      puts "#{data[:name]}: #{data[:winRate]}, #{data[:frequency].round}/#{totalDrafts.round} drafts (#{frequencyPercentage}%)"
    }
  end

  def calcPacks(record, includeByes)
    wins = record[:wins]
    # If we're to include byes, add them as wins
    wins -= record[:byes] if (includeByes.nil? || includeByes == false)
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

  def getTotalDraftsPlayed
    @decks.length
  end

  def getPacksWon(type, includeByes)
    packs = 0
    if type == 'all'
      @decks.each { |deck|
        packs += calcPacks(deck.record, includeByes)
      }
      packs.to_f/getTotalDraftsPlayed
    else
      puts 'Error! getPacksEarned type is unrecognized', type
    end
  end

  def print
    puts "#{@game} stats: "
    winRate = winRate('all')
    puts "overall win rate: #{winRate} \n"
    puts "#{getTotalDraftsPlayed} drafts, avg #{getPacksWon('all', false)}/#{getPacksWon('all', true)} packs earned/won \n"
    printColorsData()
  end


end


puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new("hex")
tracker.load("./sample_hex_data.rtf")

puts ''

tracker.print()


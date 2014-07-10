# Public methods
def exists(object)
  object !=nil
end

# Public classes
class Deck
  attr_reader("record")
  attr_reader("archetype")

  def initialize(data)
    @colors = data[:colors]
    @type = data[:type]
    @record = data[:record]
    @description = data[:description]
    @archetype = data[:archetype]
  end

  def has_color?(givenColor)
    @colors.any? {|color| color == givenColor}
  end

  def is_type?(givenType)
    @type == givenType
  end

  def is_archetype?(givenType)
    @archetype == givenType
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
    @gameDeckTypes =
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

    # Just get the draft record lines
    startIndex = nil
    endIndex = nil
    lines.each_with_index { |line, i|
      if match = line.match(/draft\srecord/)
        startIndex = i
      elsif line.match(/(\\'97){3,}/)
        endIndex = i
        break
      end
    }
    if exists(startIndex) and exists(endIndex)
      lines = lines[startIndex+1..endIndex-1]
    end

    puts 'draft record:', lines

    lines.each { |line|
      # Strip the description
      if match = line.match(/(.*)\s-\s(.*)/)
        strippedLine = match[1]
        description = match[2]
      else
        strippedLine = line
        description = ''
      end
      # TODO: check if the letter is lowercase, and if so call it a splash (currently only looks for capital letters, so lowercase mean nothing. Possibly a good thing? (mono with a splash is basically mono, sorta. Maybe should have a "Rx" category...dunno))
      if match = strippedLine.match(/\s*(\w*)\s(\w*)\s.*(\d).*(\d)\s*(\S*)/)
        colorString = match[1]
        colors = colorString.scan(/\w/)
        colors.sort!
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

        # Create the archetype string, which needs to be standardized
        archetype = ""
        colors.each {|color| archetype += color  }
        archetype += " #{type}"

        data = {
         colors: colors,
         type: type,
         archetype: archetype,
         record: record,
         description: description
        }
        @decks << Deck.new(data)
      end
    }

    generateGameArcheTypes

  end

  def generateGameArcheTypes
    types = @decks.map { |deck| deck.archetype }
    types.uniq!
    @gameArcheTypes = types
  end

  def getPropName(value)
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

  def getTotal(recordType, decks)
    total = 0
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

  def getWinRate(decks)
    percentage = getPercentage(getTotal("wins", decks), getTotal("all", decks))
    "#{percentage}%"
  end

  def getDecksOfProp(func, value)
    @decks.select {|deck| func.call(deck, value) }
  end

  def generateData(filterFunc, value)
    decks = getDecksOfProp(filterFunc, value)
    data = {
      winRate: getWinRate(decks),
      name: getPropName(value),
      frequency: decks.length
    }
    data
  end

  def sortByWinRate(givenData)
    givenData.sort_by! { |data| data[:winRate] }
    givenData.reverse!
    givenData
  end

  def printData(possibleValues, filterFunc)
    deckData = possibleValues.map { |value| generateData(filterFunc, value) }
    deckData = sortByWinRate(deckData)
    totalMatches = 0
    deckData.each do |data|
      freq = data[:frequency]
      totalMatches += freq
      frequencyPercentage = getPercentage(freq, getTotalDraftsPlayed)
      puts "#{data[:name]}: #{data[:winRate]}, #{freq.round}/#{getTotalDraftsPlayed} drafts (#{frequencyPercentage}%)"
    end
    # Return total matches, to be verified if necessary
    totalMatches
  end

  def printDataAndCheckCount(possibleValues, filterFunc)
    totalMatches = printData(possibleValues, filterFunc)
    # Make sure the total decks calculated is the number of drafts. Otherwise, we missed something
    draftCount = @decks.length
    puts "Error! There are #{draftCount} drafts recorded, but one of the analyzers came up with #{totalMatches}" unless totalMatches == draftCount
  end

  def calcPacks(record, includeByes)
    wins = record[:wins]
    # If we're to include byes, add them as wins
    wins += record[:byes] if includeByes
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
      (packs.to_f/getTotalDraftsPlayed).round(2)
    else
      puts 'Error! getPacksEarned type is unrecognized', type
    end
  end

  def printOverallData
    winRate = getWinRate(@decks)
    puts "overall win rate: #{winRate} \n"
    puts "#{getTotalDraftsPlayed} drafts, avg #{getPacksWon('all', false)}/#{getPacksWon('all', true)} packs earned/won \n\n"
  end

  def print
    puts "#{@game} stats: "
    printOverallData

    puts "Colors: Win Rate, Frequency"
    printData(@gameColors, Proc.new {|deck, color| deck.has_color?(color) })

    puts "\nTypes: Win Rate, Frequency"
    printDataAndCheckCount(@gameDeckTypes, Proc.new {|deck, type| deck.is_type?(type) })

    puts "\nArchetypes: Win Rate, Frequency"
    printDataAndCheckCount(@gameArcheTypes, Proc.new {|deck, type| deck.is_archetype?(type) })

  end


end


puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new("hex")
tracker.load("/Users/dylanpratt/Documents/stuff/game_notes/hex_notes.rtf")

puts ''

tracker.print()


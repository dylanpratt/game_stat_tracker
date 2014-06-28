# Public methods
def exists(object)
  object !=nil
end

# Public classes
class Deck
  def initialize(colors, type, record)
    @colors = colors
    @type = type
    @record = record
  end
end

class Tracker
  def initialize(game)
    puts "Creating a tracker for #{game} \n\n"
    @game = game
    @decks = []
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

    puts 'lines', lines

    lines.each { |line|
      # TODO: check if the letter is lowercase, and if so call it a splash
      if match = line.match(/(\w*)\s(\w*)\s.*(\d).*(\d)\s*(\S*)/)
        colorString = match[1]
        colors = colorString.scan(/\w/)
        type = match[2]
        # TODO: check for '2' in the match and makes byes 2 if its there
        hasBye = match[5].match(/bye/) != nil
        byes = hasBye ? 1 : 0
        record = {wins: match[3], losses: match[4], byes: byes}
        @decks << Deck.new(colors, type, record)
      end
    }
    puts '@decks', @decks.inspect
    puts '@decks.length', @decks.length
  end


end


puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new("hex")
tracker.load("./sample_hex_data.rtf")



# Public methods
def exists(object)
  object !=nil
end

class Tracker

  def initialize(game)
    puts "Creating a tracker for #{game}"
    @game = game
  end

end

puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new("hex")

# TODO: for now just do stuff here, but later make these into functions, when I know how they should be divided better

# Fetch raw text from sample_hex_data
text = File.read("./sample_hex_data.rtf")

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

if exists(metaDataIndex)
  lines = lines[metaDataIndex+1..-1]
end

puts lines

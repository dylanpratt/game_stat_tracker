class Deck
  attr_reader("record")
  attr_reader("archetype")
  attr_reader("color_combo")

  def initialize(data)
    # Given variables
    @colors = data[:colors]
    @types = data[:types]
    @record = data[:record]
    @description = data[:description]
    @rating = data[:rating]

    # Calculated variables
    # Create the archetype string, which needs to be standardized
    @archetype = ""
    @colors.each {|color| @archetype += color  }
    @archetype += " #{@types}"

    # Create the color_combo string ignoring lower case splashes
    @color_combo = ""
    @colors.each {|color| @color_combo += color if exists(/[[:upper:]]/.match(color))  }
  end

  def has_color?(given_color)
    @colors.any? {|color| color == given_color}
  end

  def has_type?(given_type)
    @types.any? {|type| type == given_type}
  end

  def is_archetype?(given_type)
    @archetype == given_type
  end

  def is_color_combo?(given_combo)
    @color_combo == given_combo
  end
end
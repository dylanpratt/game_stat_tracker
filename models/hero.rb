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
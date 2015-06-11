# Public variables

# Public methods
def exists(object)
  object !=nil
end

# Public classes
require './tracker/main.rb'

# Get the game type from arguments given (use magic as default)
game = ARGV[0] || "magic"
modifier = ARGV[1]

puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new(game, modifier)
tracker.choose_and_load_file

puts ''

tracker.print_results()


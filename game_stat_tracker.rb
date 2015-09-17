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

# Find out if we're on a mac. 
is_mac = (/darwin/ =~ RUBY_PLATFORM) != nil

puts "Welcome to the wonderful world of game stat tracking! \n\n"

tracker = Tracker.new(game, modifier)

if is_mac
	puts "I see you're on a mac, well met!"
	tracker.choose_and_load_file_from_mac
# For now, assume we're on windows if not on a mac
else
	puts "Not on a mac?! Phbbbbbt"
	tracker.choose_and_load_file_from_windows
end


puts ''

tracker.print_results()


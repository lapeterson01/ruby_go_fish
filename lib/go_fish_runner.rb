require_relative 'game'

game = Game.new
game.start
puts game.play_round until game.winner
puts "Winner: #{game.winner.name}"

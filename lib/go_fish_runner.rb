require_relative 'game'

game = Game.new(2)
game.start
puts game.turn == game.players['Player 1'] ? game.play_round('Player 2', game.turn.hand.keys[0]) : game.play_round('Player 1', game.turn.hand.keys[0]) until game.winner
puts "Winner: #{game.winner.name}"

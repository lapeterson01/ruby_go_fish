# runs the game from the server
class GameRunner
  attr_reader :game, :connections

  def initialize(game, connections)
    @game = game
    @connections = connections
  end

  def start
    @game.start
    @connections.each { |client| client.provide_input('Game Started!') }
  end
end

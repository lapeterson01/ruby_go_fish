require 'socket'
require 'pry'
require_relative 'game'
require_relative 'socket_client'
require_relative 'socket_game_runner'

# creates server for sockets
class SocketServer
  attr_reader :pending_clients, :games

  def initialize
    @games = {}
    @pending_clients = []
  end

  def port_number
    3336
  end

  def start
    @server = TCPServer.new(port_number)
  end

  def accept_new_client
    client = @server.accept_nonblock
    sleep(0.1) until client
    @pending_clients.push(SocketClient.new(client))
    client.puts 'You are connected!'
    handle_accept_clients_messages(client)
  rescue StandardError
    # no client to accept
  end

  def create_game_if_possible
    @games.each { |game| game.push(@pending_clients) unless game.started }
    return unless @pending_clients.length > 1

    game = Game.new
    @pending_clients.length.times { |player_number| add_players(game, player_number) }
    @games[game] = @pending_clients.shift(@pending_clients.length)
    game
  end

  def run_game(game)
    game_runner = GameRunner.new(game, @games[game])
    game_runner.start
    Thread.start do
      game_runner.play_round until game.winner
      game_runner.winner
    end
  end

  def stop
    @server.close if @server
  end

  private

  def handle_accept_clients_messages(client)
    return client.puts('Waiting for more players') if @pending_clients.length < 2

    @pending_clients.each { |each_client| each_client.provide_input "#{@pending_clients.length} players have joined" }
  end

  def add_players(game, player_number)
    player = Player.new("Player #{player_number + 1}")
    game.add_player(player)
  end
end

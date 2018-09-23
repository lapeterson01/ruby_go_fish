require 'pry'
require_relative 'socket_server'

server = SocketServer.new
server.start
loop do
  begin
    server.accept_new_client
    game = server.create_game_if_possible
    server.run_game(game) if game
  rescue StandardError
    server.stop
  end
end

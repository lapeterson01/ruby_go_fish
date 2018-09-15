require 'rspec'
require_relative '../lib/socket_server'
require_relative 'socket_server_spec'

describe GameRunner do
  def setup_clients(server, clients)
    @client1, @client2 = MockSocketClient.new(server.port_number), MockSocketClient.new(server.port_number)
    2.times { server.accept_new_client }
    clients << @client1 << @client2
  end

  def count_hand(player)
    count = 0
    player.hand.each_value { |set| count += set.length }
    count
  end

  let(:server) { SocketServer.new }
  let(:clients) { [] }

  before do
    server.start
    setup_clients(server, clients)
    clients.each { |client| client.provide_input('start') }
    @game = server.create_game_if_possible
    @game_runner = server.run_game(@game)
    @player1, @player2 = @game.players['Player 1'], @game.players['Player 2']
  end

  after do
    server.stop
    clients.each(&:close)
  end

  describe '#initialize' do
    it 'begins with game and client connections' do
      expect(@game_runner.game).to eq @game
      expect(@game_runner.connections.length).to eq 2
    end
  end

  describe '#start' do
    it 'starts the game' do
      @game_runner.start
      expect(@client1.capture_output && @client2.capture_output).to match(/Game Started!/)
      expect(@game.deck.cards.length).to eq 38
      expect(count_hand(@player1) && count_hand(@player2)).to eq 7
    end
  end
end
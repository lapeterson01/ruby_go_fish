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

  describe '#play_round' do
    it 'takes input from clients in order to play a round' do
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('A', 'Clubs')
      @player1.retrieve_card(card1)
      @player2.retrieve_card(card2)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You took A of Clubs from Player 2/)
      expect(@client2.capture_output).to match(/Player 1 took A of Clubs from you/)
    end

    it 'returns the appropriate message to each player if the player drew from the deck' do
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('Q', 'Hearts')
      @player1.retrieve_card(card1)
      @player2.retrieve_card(card2)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You asked for A and drew/)
      expect(@client2.capture_output).to match(/Player 1 asked for A and drew/)
    end

    it 'returns an message when player asks for card not in their hand and lets them go again' do
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('A', 'Clubs')
      @player1.retrieve_card(card1)
      @player2.retrieve_card(card2)
      @client1.provide_input('Player 2 for K')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You can only ask for a rank that is in your hand/)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You took A of Clubs from Player 2/)
    end
  end

  describe '#winner' do
    it 'returns the winner of the round' do
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('A', 'Clubs')
      card3, card4 = PlayingCard.new('A', 'Diamonds'), PlayingCard.new('A', 'Hearts')
      @player1.retrieve_card(card1) && @player1.retrieve_card(card2)
      @player2.retrieve_card(card3) && @player2.retrieve_card(card4)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      @game_runner.winner
      expect(@client1.capture_output).to match(/You won!/)
      expect(@client2.capture_output).to match(/You lost... Winner: Player 1/)
    end
  end
end

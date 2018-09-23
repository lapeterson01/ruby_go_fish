require 'rspec'
require_relative '../lib/socket_server'
require_relative '../lib/socket_game_runner'
require_relative 'socket_server_spec'

describe GameRunner do
  def setup_clients(server, clients)
    @client1, @client2, @client3 = MockSocketClient.new(server.port_number), MockSocketClient.new(server.port_number), MockSocketClient.new(server.port_number)
    3.times { server.accept_new_client }
    clients << @client1 << @client2 << @client3
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
    @game = server.create_game_if_possible
    @game_runner = GameRunner.new(@game, server.games[@game])
    @player1, @player2, @player3 = @game.players['Player 1'], @game.players['Player 2'], @game.players['Player 3']
  end

  after do
    server.stop
    clients.each(&:close)
  end

  describe '#initialize' do
    it 'begins with game and client connections' do
      expect(@game_runner.game).to eq @game
      expect(@game_runner.connections.length).to eq 3
      expect(@client1.capture_output && @client2.capture_output && @client3.capture_output).to match(/You have joined a game.. Type 'start' to begin or wait for more players to join/)
    end
  end

  describe '#start' do
    it 'starts the game' do
      clients.each { |client| client.provide_input 'start' }
      @game_runner.start
      expect(@client1.capture_output && @client2.capture_output && @client3.capture_output).to match(/Game Started!/)
      expect(@game.deck.cards.length).to eq 31
      expect(count_hand(@player1) && count_hand(@player2)).to eq 7
    end
  end

  describe '#play_round' do
    let(:card1) { PlayingCard.new('A', 'Spades') }
    let(:card2) { PlayingCard.new('A', 'Clubs') }

    before do
      @player1.retrieve_card(card1)
    end

    it 'takes input from clients in order to play a round' do
      @player2.retrieve_card(card2)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You took A of Clubs from Player 2/)
      expect(@client2.capture_output).to match(/Player 1 took A of Clubs from you/)
      expect(@client3.capture_output).to match(/Player 1 took A of Clubs from Player 2/)
    end

    it 'returns the appropriate message to each player if the player drew from the deck' do
      card2 = PlayingCard.new('Q', 'Hearts')
      @player2.retrieve_card(card2)
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      expect(@client1.capture_output).to match(/You asked for A and drew/)
      expect(@client2.capture_output).to match(/Player 1 asked for A and drew/)
    end

    it 'returns a message when player asks for card not in their hand and lets them go again' do
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
    let(:card1) { PlayingCard.new('A', 'Spades') }
    let(:card2) { PlayingCard.new('A', 'Clubs') }
    let(:card3) { PlayingCard.new('A', 'Diamonds') }
    let(:card4) { PlayingCard.new('A', 'Hearts') }
    let(:extra_card) { PlayingCard.new('2', 'Clubs') }

    before do
      @player1.retrieve_card(card1) && @player1.retrieve_card(card2)
      @player2.retrieve_card(card3) && @player2.retrieve_card(card4)
      @player3.retrieve_card(extra_card)
    end

    it 'returns the winner of the round' do
      expect(@game_runner.winner).to eq nil
      @client1.provide_input('Player 2 for A')
      @game_runner.play_round
      @game_runner.winner
      expect(@client1.capture_output).to match(/You won! Winner: Player 1/)
      expect(@client2.capture_output).to match(/You lost... Winner: Player 1/)
    end

    describe 'multiple winners' do
      def setup_multiple_winners
        inputs_and_outputs = { 'Player 2 for A' => /You took A of Diamonds, A of Hearts from Player 2/, 'Player 3 for K' => /You asked for K and drew/, 'Player 1 for K' => /Player 2 took K of Spades, K of Clubs from you/ }

        inputs_and_outputs.each_pair do |input, output|
          input.include?('Player 1') ? @client2.provide_input(input) : @client1.provide_input(input)
          @game_runner.play_round
          expect(@client1.capture_output).to match(output)
        end
      end

      let(:card5) { PlayingCard.new('K', 'Spades') }
      let(:card6) { PlayingCard.new('K', 'Clubs') }
      let(:card7) { PlayingCard.new('K', 'Diamonds') }
      let(:card8) { PlayingCard.new('K', 'Hearts') }

      before do
        @player1.retrieve_card(card5) && @player1.retrieve_card(card6)
        @player2.retrieve_card(card7) && @player2.retrieve_card(card8)
      end

      it 'handles multiple winners' do
        setup_multiple_winners
        @game_runner.winner
        expect(@client1.capture_output && @client2.capture_output).to match(/You won! Winners: Player 1, Player 2/)
        expect(@client3.capture_output).to match(/You lost... Winners: Player 1, Player 2/)
      end
    end
  end
end

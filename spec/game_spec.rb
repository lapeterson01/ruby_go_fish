require 'rspec'
require_relative '../lib/game'

describe Game do
  def round_result_expectations(round_result, card_from, cards, rank_asked_for, turn)
    expect(round_result['card_from']).to eq card_from
    expect(round_result['cards']).to eq cards
    expect(round_result['rank_asked_for']).to eq rank_asked_for
    expect(round_result['turn']).to eq turn
  end

  let(:game) { Game.new }
  let(:player1) { Player.new('Player 1') }
  let(:player2) { Player.new('Player 2') }
  let(:card1) { PlayingCard.new('A', 'Spades') }
  let(:card2) { PlayingCard.new('A', 'Clubs') }

  before do
    game.add_player(player1)
    game.add_player(player2)
  end

  describe '#initialize' do
    it 'begins with deck of 52 standard playing cards' do
      expect(game.deck).to be_instance_of CardDeck
    end

    it 'begins with 2 or more players' do
      expect(player1).to be_instance_of Player
    end
  end

  describe '#start' do
    it 'shuffles and deals deck to players' do
      game.start
      expect(game.deck.cards.length).to eq 38
      expect(player1.count_hand).to eq 7
      expect(player2.count_hand).to eq 7
    end
  end

  describe '#play_round' do
    it 'removes specified card from specified player (if they have the card) and adds it to the player whose turn it is' do
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      round_result_expectations(game.play_round('Player 2', 'A'), player2.name, [card2], 'A', player1.name)
      expect(player1.count_hand).to eq 2
      expect(player2.count_hand).to eq 0
    end

    it 'if specified player does not have card, it takes next card from deck and adds to player hand' do
      card2 = PlayingCard.new('Q', 'Hearts')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round('Player 2', 'A')
      expect(player1.count_hand).to eq 2
      expect(player2.count_hand).to eq 1
    end

    it 'allows the player to get another turn if player gets the card they asked for' do
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      round_result_expectations(game.play_round('Player 2', 'A'), player2.name, [card2], 'A', player1.name)
      expect(game.turn).to eq player1
    end

    describe 'changing turns' do
      let(:game) { Game.new(CardDeck.new([PlayingCard.new('2', 'Clubs'), PlayingCard.new('K', 'Diamonds')])) }
      let(:player1) { Player.new('Player 1') }
      let(:player2) { Player.new('Player 2') }
      let(:card2) { PlayingCard.new('Q', 'Hearts') }

      before do
        game.add_player(player1)
        game.add_player(player2)
        player1.retrieve_card(card1) && player2.retrieve_card(card2)
        game.play_round('Player 2', 'A')
      end

      it 'changes turns to the next player if first player does not get the card they asked for' do
        expect(game.turn).to eq player2
        game.play_round('Player 1', 'Q')
        expect(game.turn).to eq player1
      end
    end

    it 'keeps track of player books and sets the book aside when player gets one' do
      card3, card4 = PlayingCard.new('A', 'Diamonds'), PlayingCard.new('A', 'Hearts')
      player1.retrieve_card(card1) && player1.retrieve_card(card2) && player1.retrieve_card(card3)
      player2.retrieve_card(card4)
      round_result_expectations(game.play_round('Player 2', 'A'), player2.name, [card4], 'A', player1.name)
      expect(player1.books).to eq 1
      expect(player1.count_hand).to eq 0
    end

    it 'does not allow a player to ask for a card that is not in their hand' do
      expect(game.play_round('Player 2', '2')).to eq 'You can only ask for a rank that is in your hand'
    end
  end

  describe '#winner' do
    let(:game) { Game.new(CardDeck.new([PlayingCard.new('2', 'Clubs'), PlayingCard.new('A', 'Hearts')])) }
    let(:player1) { Player.new('Player 1') }
    let(:player2) { Player.new('Player 2') }
    let(:card3) { PlayingCard.new('A', 'Diamonds') }

    before do
      game.add_player(player1)
      game.add_player(player2)
    end

    it 'assigns a winner when the pool is out of cards' do
      card4 = PlayingCard.new('5', 'Diamonds')
      player1.retrieve_card(card4)
      player2.retrieve_card(card1) && player2.retrieve_card(card2) && player2.retrieve_card(card3)
      game.play_round('Player 2', '5')
      expect(game.winner).to eq nil
      game.play_round('Player 1', 'A')
      expect(game.winner).to eq player2
    end

    it 'assigns a winner when a player is out of cards' do
      card4 = PlayingCard.new('A', 'Hearts')
      player1.retrieve_card(card1) && player1.retrieve_card(card2) && player1.retrieve_card(card3)
      player2.retrieve_card(card4)
      game.play_round('Player 2', 'A')
      expect(game.winner).to eq player1
    end
  end
end

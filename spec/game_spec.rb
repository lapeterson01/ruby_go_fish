require 'rspec'
require_relative '../lib/game'

describe Game do
  def count_hand(player)
    count = 0
    player.hand.each_value { |set| count += set.length }
    count
  end

  let(:game) { Game.new(2) }
  let(:player1) { game.players['player1'] }
  let(:player2) { game.players['player2'] }
  let(:card1) { PlayingCard.new('A', 'Spades') }
  let(:card2) { PlayingCard.new('A', 'Clubs') }

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
      expect(count_hand(player1)).to eq 7
      expect(count_hand(player2)).to eq 7
    end
  end

  describe '#play_round' do
    it 'removes specified card from specified player (if they have the card) and adds it to the player whose turn it is' do
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(count_hand(player1)).to eq 2
      expect(count_hand(player2)).to eq 0
    end

    it 'if specified player does not have card, it takes next card from deck and adds to player hand' do
      card2 = PlayingCard.new('Q', 'Hearts')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(count_hand(player1)).to eq 2
      expect(count_hand(player2)).to eq 1
    end

    it 'allows the player to get another turn if player gets the card they asked for' do
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(game.turn).to eq player1
    end

    it 'changes turns to the next player if first player does not get the card they asked for' do
      game = Game.new(2, CardDeck.new([PlayingCard.new('2', 'Clubs')]))
      player1, player2 = game.players['player1'], game.players['player2']
      card2 = PlayingCard.new('Q', 'Hearts')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(game.turn).to eq player2
    end

    it 'keeps track of player books and sets the book aside when player gets one' do
      card3, card4 = PlayingCard.new('A', 'Diamonds'), PlayingCard.new('A', 'Hearts')
      player1.retrieve_card(card1) && player1.retrieve_card(card2) && player1.retrieve_card(card3)
      player2.retrieve_card(card4)
      game.play_round(player2, 'A')
      expect(player1.books).to eq 1
      expect(count_hand(player1)).to eq 0
    end
  end
end

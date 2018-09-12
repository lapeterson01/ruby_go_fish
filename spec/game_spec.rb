require 'rspec'
require_relative '../lib/game'

describe Game do
  describe '#initialize' do
    it 'begins with deck of 52 standard playing cards' do
      game = Game.new
      expect(game.deck).to be_instance_of CardDeck
    end

    it 'begins with 2 or more players' do
      game = Game.new
      expect(game.player1).to be_instance_of Player
    end
  end

  describe '#start' do
    it 'shuffles and deals deck to players' do
      game = Game.new
      game.start
      expect(game.deck.cards.length).to eq 38
      count1, count2 = 0, 0
      game.player1.hand.each_value { |set| count1 += set.length }
      game.player2.hand.each_value { |set| count2 += set.length }
      expect(count1).to eq 7
      expect(count2).to eq 7
    end
  end

  describe '#play_round' do
    it 'removes specified card from specified player (if they have the card) and adds it to the player whose turn it is' do
      game = Game.new
      player1 = game.player1
      player2 = game.player2
      card1 = PlayingCard.new('A', 'Spades')
      card2 = PlayingCard.new('A', 'Clubs')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      count1 = 0
      game.player1.hand.each_value { |set| count1 += set.length }
      expect(count1).to eq 2
      expect(player2.hand.length).to eq 0
    end

    it 'if specified player does not have card, it takes next card from deck and adds to player hand' do
      game = Game.new
      player1 = game.player1
      player2 = game.player2
      card1 = PlayingCard.new('A', 'Spades')
      card2 = PlayingCard.new('Q', 'Hearts')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      count1, count2 = 0, 0
      game.player1.hand.each_value { |set| count1 += set.length }
      game.player2.hand.each_value { |set| count2 += set.length }
      expect(count1).to eq 2
      expect(count2).to eq 1
    end

    it 'allows the player to get another turn if player gets the card they asked for' do
      game = Game.new
      player1 = game.player1
      player2 = game.player2
      card1 = PlayingCard.new('A', 'Spades')
      card2 = PlayingCard.new('A', 'Clubs')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(game.turn).to eq player1
    end

    it 'changes turns to the next player if first player does not get the card they asked for' do
      game = Game.new(CardDeck.new([PlayingCard.new('2', 'Clubs')]))
      player1 = game.player1
      player2 = game.player2
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('Q', 'Hearts')
      player1.retrieve_card(card1)
      player2.retrieve_card(card2)
      game.play_round(player2, 'A')
      expect(game.turn).to eq player2
    end

    it 'keeps track of player books and sets the book aside when player gets one' do
      game = Game.new
      player1, player2 = game.player1, game.player2
      card1, card2 = PlayingCard.new('A', 'Spades'), PlayingCard.new('A', 'Clubs')
      card3, card4 = PlayingCard.new('A', 'Diamonds'), PlayingCard.new('A', 'Hearts')
      player1.retrieve_card(card1)
      player1.retrieve_card(card2)
      player1.retrieve_card(card3)
      player2.retrieve_card(card4)
      game.play_round(player2, 'A')
      expect(player1.books).to eq 1
      count1 = 0
      player1.hand.each_value { |set| count1 += set.length }
      expect(count1).to eq 0
    end
  end
end

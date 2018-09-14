require 'rspec'
require_relative '../lib/player'

describe Player do
  describe '#initialize' do
    it 'begins with an empty hand' do
      player1 = Player.new('Player 1')
      expect(player1.hand.length).to eq 0
    end
  end

  describe '#retrieve_card' do
    it 'takes in a card and adds it to player hand' do
      player = Player.new('Player')
      card = PlayingCard.new('A', 'Spades')
      player.retrieve_card(card)
      count = 0
      player.hand.each_value { |set| count += set.length }
      expect(count).to eq 1
    end
  end

  describe '#give_up_cards' do
    it 'removes a specified card from player hand and returns it' do
      player = Player.new('Player')
      card1 = PlayingCard.new('A', 'Spades')
      card2 = PlayingCard.new('Q', 'Hearts')
      player.retrieve_card(card1)
      player.retrieve_card(card2)
      player.give_up_cards(card1.rank)
      count = 0
      player.hand.each_value { |set| count += set.length }
      expect(count).to eq 1
    end
  end
end

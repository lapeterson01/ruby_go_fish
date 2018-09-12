require 'rspec'
require_relative '../lib/playing_card'

describe PlayingCard do
  describe '#initialize' do
    it 'creates a standard playing card with rank and suit' do
      card = PlayingCard.new('A', 'Spades')
      expect(card.rank).to eq 'A'
      expect(card.suit).to eq 'Spades'
    end
  end

  describe 'equality' do
    it 'allows two instances of PlayingCard to be equal if ranks and suits are equal' do
      card1 = PlayingCard.new('A', 'Spades')
      card2 = PlayingCard.new('A', 'Spades')
      expect(card1).to eq card2
      card3 = PlayingCard.new('Q', 'Hearts')
      expect(card1).to_not eq card3
    end
  end
end

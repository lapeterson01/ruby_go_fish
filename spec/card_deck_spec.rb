require 'rspec'
require_relative '../lib/card_deck'

describe CardDeck do
  describe '#initialize' do
    it 'creates a deck of 52 standard playing cards' do
      deck = CardDeck.new
      expect(deck.cards.length).to eq 52
    end
  end

  describe '#shuffle!' do
    it 'shuffles the deck of cards' do
      deck1 = CardDeck.new
      deck2 = CardDeck.new
      expect(deck1).to eq deck2
      deck1.shuffle!
      expect(deck1).to_not eq deck2
    end
  end

  describe '#deal' do
    it 'returns the top card from the deck' do
      deck = CardDeck.new
      card = deck.deal
      expect(card).to be_instance_of PlayingCard
      expect(deck.cards.length).to eq 51
    end
  end

  describe 'equality' do
    it 'allows two instances of CardDeck to be equal if the cards are equal' do
      deck1 = CardDeck.new
      deck2 = CardDeck.new
      expect(deck1).to eq deck2
    end
  end

  describe '#out_of_cards?' do
    it 'returns true if the deck is out of cards and false if it is not' do
      deck1 = CardDeck.new
      expect(deck1.out_of_cards?).to eq false
      deck2 = CardDeck.new([])
      expect(deck2.out_of_cards?).to eq true
    end
  end
end

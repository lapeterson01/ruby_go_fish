require 'pry'

# creates a deck of 52 standard playing cards
class CardDeck
  attr_reader :cards

  RANKS = %w[A K Q J 10 9 8 7 6 5 4 3 2].freeze
  SUITS = %w[Spades Clubs Diamonds Hearts].freeze

  def initialize(cards = RANKS.map { |rank| SUITS.map { |suit| PlayingCard.new(rank, suit) } }.flatten)
    @cards = cards
  end

  def shuffle!
    @cards.shuffle!
  end

  def deal
    @cards.shift
  end

  def ==(other)
    equal = true
    other.cards.each do |card2|
      equal = false if @cards[other.cards.index(card2)] != card2
    end
    equal
  end
end

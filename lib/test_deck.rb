require_relative 'playing_card'

class TestDeck
  attr_reader :cards

  RANKS = %w[A K Q J].freeze
  SUITS = %w[Spades Clubs Diamonds Hearts].freeze

  def initialize(cards = SUITS.map { |suit| RANKS.map { |rank| PlayingCard.new(rank, suit) } }.flatten)
    @cards = cards
  end

  def shuffle!
    # do nothing
  end

  def deal
    cards.shift
  end

  def out_of_cards?
    cards.empty?
  end

  def ==(other)
    equal = true
    other.cards.each do |card2|
      equal = false if cards[other.cards.index(card2)] != card2
    end
    equal
  end
end
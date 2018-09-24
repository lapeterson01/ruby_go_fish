require_relative 'playing_card'
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
    cards.shuffle!
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

def play
  output = ''
  output = @socket.gets until output.include? 'start'
  @socket.puts 'start'
  next_request = ''
  until output.include? 'Winner'
    if output.include? 'hand'
      RANKS.each do |rank|
        if output.include? rank
          next_request = rank
          break
        end
      end
      @socket.gets
    elsif output.include? 'Type'
      @socket.puts "Player 2 for #{next_request}"
    else
      @socket.gets
    end
  end
  @socket.gets
end
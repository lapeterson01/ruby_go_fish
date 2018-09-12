# creates standard playing card with rank and suit
class PlayingCard
  attr_reader :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def ==(other)
    @rank == other.rank && @suit == other.suit
  end
end

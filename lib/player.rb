# creates Go Fish player
class Player
  attr_reader :hand
  attr_accessor :books

  def initialize
    @hand = {}
    @books = 0
  end

  def retrieve_card(card)
    @hand[card.rank] = [] unless @hand[card.rank]
    @hand[card.rank].push(card)
  end

  def give_up_cards(rank)
    @hand.delete(rank)
  end
end

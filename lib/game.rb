require_relative 'card_deck'

# creates and runs a game of go fish
class Game
  attr_reader :deck, :players, :turn

  def initialize(number_of_players, deck = CardDeck.new)
    @deck = deck
    @players = {}
    number_of_players.times { |player_number| @players["player#{player_number + 1}"] = Player.new }
    @turn = @players['player1']
  end

  def start
    @deck.shuffle!
    @players.each_value { |player| @players.length < 4 ? deal_cards(7, player) : deal_cards(5, player) }
  end

  def play_round(player, rank)
    get_catch = false
    if player.hand[rank]
      cards = player.give_up_cards(rank)
      cards.each { |card| @turn.retrieve_card(card) }
      get_catch = true
    else
      card = deck.deal
      @turn.retrieve_card(card)
      get_catch = true if card.rank == rank
    end
    @turn.hand.each_key do |set|
      if @turn.hand[set].length == 4
        @turn.books += 1
        @turn.give_up_cards(set)
      end
    end
    unless get_catch
      @turn = @turn == @players['player1'] ? @players['player2'] : @players['player1']
    end
  end

  private

  def deal_cards(int, player)
    int.times do
      card = @deck.deal
      player.retrieve_card(card)
    end
  end
end

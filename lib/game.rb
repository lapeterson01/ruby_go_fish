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

  def play_round(player_name, rank)
    return 'You can only ask for a rank that is in your hand' unless @turn.hand[rank]

    player = @players[player_name]
    get_catch = player.hand[rank] ? handle_player_asked_has_card(player, rank) : handle_go_fish(rank)
    @turn.hand.each_key { |set| handle_player_got_book(set) }
    next_player_turn unless get_catch
  end

  private

  def deal_cards(int, player)
    int.times do
      card = @deck.deal
      player.retrieve_card(card)
    end
  end

  def handle_player_asked_has_card(player, rank)
    cards = player.give_up_cards(rank)
    cards.each { |card| @turn.retrieve_card(card) }
    _get_catch = true
  end

  def handle_go_fish(rank)
    card = deck.deal
    @turn.retrieve_card(card)
    _get_catch = card.rank == rank
  end

  def handle_player_got_book(set)
    return unless @turn.hand[set].length == 4

    @turn.books += 1
    @turn.give_up_cards(set)
  end

  def next_player_turn
    player_names = @players.keys
    @turn = if @players.key(@turn) == player_names.last
              @players[player_names[0]]
            else
              @players[player_names[player_names.index(@players.key(@turn)) + 1]]
            end
  end
end

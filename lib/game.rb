require_relative 'card_deck'
require_relative 'player'
require 'pry'

# creates and runs a game of go fish
class Game
  attr_reader :deck, :players, :turn, :books_display_name, :books_display_number, :hash_to_return, :winning_books, :started
  attr_accessor :round_result

  def initialize(deck = CardDeck.new)
    @deck = deck
    @players = {}
    @started = false
  end

  def add_player(player)
    return if @players.length == 4

    @players[player.name] = player
    @turn = player if @players.length == 1
  end

  def other_players(player)
    other_players_list = []
    @players.each_value { |other_player| other_players_list.push(other_player) if player != other_player }
    other_players_list
  end

  def start
    deck.shuffle!
    players.each_value { |player| @players.length < 4 ? deal_cards(7, player) : deal_cards(5, player) }
    @started = true
  end

  def play_round(player_name, rank)
    return 'You can only ask for a rank that is in your hand' unless @turn.hand[rank]

    return 'You cannot ask yourself for a card' if player_name == @turn.name

    player = players[player_name]
    get_catch = player.hand[rank] ? handle_asked_player_has_card(player, rank) : handle_go_fish(rank)
    handle_player_got_book
    next_player_turn unless get_catch
    @round_result = hash_to_return
  end

  def winner
    @winning_books = 0
    players.each_value { |player| calculate_winner(player) } if deck.out_of_cards? || players_out_of_cards
    @winner
  end

  private

  def deal_cards(int, player)
    int.times do
      card = deck.deal
      player.retrieve_card(card)
    end
  end

  def handle_asked_player_has_card(player, rank)
    cards = player.give_up_cards(rank)
    cards.each { |card| @turn.retrieve_card(card) }
    create_display(player, cards, rank)
    _get_catch = true
  end

  def handle_go_fish(rank)
    card = deck.deal
    turn.retrieve_card(card)
    @hash_to_return = {
      'turn' => @turn.name,
      'rank_asked_for' => rank,
      'card_from' => 'pool',
      'cards' => [card]
    }
    _get_catch = card.rank == rank
  end

  def handle_player_got_book
    @books_display_name, @books_display_number = turn.name, 0
    turn.hand.each_key do |set|
      next unless turn.hand[set].length == 4

      turn.books += 1
      turn.give_up_cards(set)
      @books_display_number += 1
    end
  end

  def next_player_turn
    player_names = players.keys
    @turn = if players.key(turn) == player_names.last
              players[player_names[0]]
            else
              @players[player_names[player_names.index(@players.key(turn)) + 1]]
            end
  end

  def players_out_of_cards
    any_empty_hands = false
    players.each_value do |player|
      any_empty_hands = true if player.out_of_cards?
    end
    any_empty_hands
  end

  def calculate_winner(player)
    if player.books > winning_books
      @winner, @winning_books = player, player.books
    elsif player.books == winning_books && player.books > 0
      @winner.class == Array ? @winner.push(player) : @winner = [@winner, player]
    end
  end

  def create_display(player, cards, rank)
    @hash_to_return = {
      'turn' => turn.name,
      'rank_asked_for' => rank,
      'card_from' => player.name,
      'cards' => []
    }
    cards.each { |card| @hash_to_return['cards'].push(card) }
    hash_to_return
  end

  def book_or_books
    books_display_number == 1 ? 'book' : 'books'
  end
end

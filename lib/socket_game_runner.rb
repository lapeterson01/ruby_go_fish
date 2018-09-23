# runs the game from the server
class GameRunner
  attr_reader :game, :connections

  def initialize(game, connections)
    @game = game
    @connections = {}
    connections.each_with_index { |connection, index| @connections[@game.players["Player #{index + 1}"]] = connection }
    @turn = @game.turn
    @connections.each_value do |connection|
      connection.provide_input("You have joined a game.. Type 'start' to begin or wait for more players to join")
    end
  end

  def start
    check_player_ready_status until @connections.values.all?(&:ready)
    @game.start
    @connections.each_value { |client| client.provide_input('Game Started!') }
  end

  def play_round
    handle_round_initial_input

    handle_player_and_card_selection
    @player_choice = @output[0]
    card_choice = @output[1]
    @round_result = @game.play_round(@player_choice, card_choice)
    @connections.each_pair { |player, connection| handle_round_final_input(player, connection) }
    @turn = @game.turn
  end

  def winner
    @connections.each_pair do |player, connection|
      return @game.winner unless @game.winner

      @game.winner.class == Array ? handle_multiple_winners(player, connection) : handle_single_winner(player, connection)
    end
  end

  private

  def check_player_ready_status
    @connections.each_value do |connection|
      output = connection.capture_output
      connection.ready = true if output.include? 'start'
    end
  end

  def handle_round_initial_input
    @connections.each_pair do |player, connection|
      player_hand = player.hand.values.map { |cards| cards.map { |card| "#{card.rank} of #{card.suit}" } }.flatten
      connection.provide_input("Your hand: #{player_hand.join(', ')}")
    end
    @connections[@turn].provide_input("Type the name of the card you would like to ask for and the name of the player you would like to ask like this: 'Player 2 for A'")
    @connections.each_pair { |player, connection| connection.provide_input("Waiting for #{@turn.name} to ask for card...") if @turn != player }
  end

  def handle_player_and_card_selection
    @connections[@turn].ready = false
    until @connections[@turn].ready
      @output = @connections[@turn].capture_output.chomp.split(' for ')
      @connections[@turn].ready = true unless @output.empty?
    end
  end

  def handle_take_card_from_player(player, connection)
    if player == @turn
      connection.provide_input(@round_result.gsub(@turn.name, 'You'))
    elsif player.name == @player_choice
      connection.provide_input(@round_result.sub(player.name, 'you'))
    else
      connection.provide_input(@round_result)
    end
  end

  def handle_draw_card_from_pool(player, connection)
    return connection.provide_input(@round_result.sub(@turn.name, 'You')) if player == @turn

    connection.provide_input(@round_result)
  end

  def handle_round_final_input(player, connection)
    if @round_result.include? 'took'
      handle_take_card_from_player(player, connection)
    elsif @round_result.include? 'drew'
      handle_draw_card_from_pool(player, connection)
    elsif player == @turn
      connection.provide_input(@round_result)
    end
  end

  def handle_multiple_winners(player, connection)
    winner_names = []
    @game.winner.each { |winner| winner_names.push(winner.name) }
    if @game.winner.include?(player)
      connection.provide_input("You won! Winners: #{winner_names.join(', ')}")
    else
      connection.provide_input("You lost... Winners: #{winner_names.join(', ')}")
    end
  end

  def handle_single_winner(player, connection)
    if @game.winner == player
      connection.provide_input("You won! Winner: #{@game.winner.name}")
    else
      connection.provide_input("You lost... Winner: #{@game.winner.name}")
    end
  end
end

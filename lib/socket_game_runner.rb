# runs the game from the server
class GameRunner
  attr_reader :game, :connections

  def initialize(game, connections)
    @game = game
    count = 1
    @connections = {}
    connections.each do |connection|
      @connections[@game.players["Player #{count}"]] = connection
      count += 1
    end
  end

  def start
    @game.start
    @connections.each_value { |client| client.provide_input('Game Started!') }
  end

  def play_round
    handle_initial_round_input

    handle_player_and_card_selection
    @player_choice = @output[0]
    card_choice = @output[1]
    @round_result = @game.play_round(@player_choice, card_choice)

    @connections.each_pair { |player, connection| handle_final_round_input(player, connection) }
  end

  def winner
    @connections.each_pair do |player, connection|
      if @game.winner.class == Array
        @game.winner.each { |winner| connection.provide_input('You won!') if winner == player }
      elsif @game.winner == player
        connection.provide_input('You won!')
      elsif @game.winner
        connection.provide_input("You lost... Winner: #{@game.winner.name}")
      else
        @game.winner
      end
    end
  end

  private

  def handle_initial_round_input
    @connections[@game.turn].provide_input("Type the name of the card you would like to ask for and the name of the player you would like to ask like this: 'Player 2 for A'")
    @connections.each_pair do |player, connection|
      connection.provide_input("Waiting for #{@game.turn.name} to ask for card...") if @game.turn != player
    end
  end

  def handle_player_and_card_selection
    @connections[@game.turn].ready = false
    until @connections[@game.turn].ready
      @output = @connections[@game.turn].capture_output.chomp.split(' for ')
      @connections[@game.turn].ready = true unless @output.empty?
    end
  end

  def handle_take_card_from_player(player, connection)
    if player == @game.turn
      connection.provide_input(@round_result.gsub(@game.turn.name, 'You'))
    elsif player.name == @player_choice
      connection.provide_input(@round_result.sub(player.name, 'you'))
    else
      connection.provide_input(@round_result)
    end
  end

  def handle_draw_card_from_pool(player, connection)
    return connection.provide_input(@round_result.sub(@game.turn.name, 'You')) if player == @game.turn

    connection.provide_input(@round_result)
  end

  def handle_final_round_input(player, connection)
    if @round_result.include? 'took'
      handle_take_card_from_player(player, connection)
    elsif @round_result.include? 'drew'
      handle_draw_card_from_pool(player, connection)
    elsif player == @game.turn
      connection.provide_input(@round_result)
    end
  end
end

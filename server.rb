require 'sinatra'
require 'sinatra/reloader'
require 'sprockets'
require 'sass'
require 'pry'
require 'dotenv'
Dotenv.load('.env')
require 'pusher'
require_relative 'lib/game'
require_relative 'lib/player'
# require_relative 'lib/test_deck'

# Server setup
class Server < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  pusher_client = Pusher::Client.new(
    app_id: ENV['PUSHER_APP_ID'],
    key: ENV['PUSHER_KEY'],
    secret: ENV['PUSHER_SECRET'],
    cluster: ENV['PUSHER_CLUSTER'],
    encrypted: ENV['PUSHER_ENCRYPTED']
  )

  enable :sessions
  # Start Assets
  set :environment, Sprockets::Environment.new
  environment.append_path 'assets/images'
  environment.append_path 'assets/images/cards'
  environment.append_path 'assets/stylesheets'
  environment.append_path 'assets/javascripts'
  environment.css_compressor = :scss
  get '/assets/*' do
    env['PATH_INFO'].sub!('/assets', '')
    settings.environment.call(env)
  end
  # End Assets

  ['/lobby', '/start-game', '/game', '/select-card', '/select-player', '/play-round', '/game-over', '/restart-game'].each do |path|
    before path do
      redirect '/' unless defined? @@game
    end
  end

  def self.game
    @@game ||= Game.new # rubocop:disable Style/ClassVars
  end

  def self.clear_game
    @@game = nil # rubocop:disbale Style/ClassVars
  end

  get '/' do
    slim :index
  end

  post '/join' do
    redirect '/' if params['name'] == ''
    player = Player.new(params['name'])
    session[:current_player] = player
    session[:host] = self.class.game.players.empty? ? true : false
    self.class.game.add_player(player)
    session[:refresh] = false
    redirect '/lobby'
  end

  get '/lobby' do
    redirect '/game' if self.class.game.started
    slim :lobby, locals: { game: self.class.game, current_player: session[:current_player], host: session[:host], refresh: session[:refresh] }
  end

  post '/start-game' do
    self.class.game.start
    pusher_client.trigger('go-fish', 'refresh', {})
    redirect '/game'
  end

  get '/game' do
    redirect '/lobby' unless self.class.game.started
    redirect '/game-over' if self.class.game.winner
    round_result = create_message(self.class.game.round_result) if self.class.game.round_result
    slim :game, locals: { game: self.class.game, current_player: self.class.game.players[session[:current_player].name], card: session[:card], player: session[:player], result: round_result }
  end

  post '/select-card' do
    session[:card] = params['card']
    self.class.game.round_result = nil
    redirect '/game'
  end

  post '/select-player' do
    session[:player] = params['player']
    redirect '/game'
  end

  post '/play-round' do
    self.class.game.play_round(session[:player], session[:card])
    session[:card] = nil
    session[:player] = nil
    redirect '/game-refresh', 308 unless self.class.game.winner
    redirect '/game'
  end

  post '/game-refresh' do
    pusher_client.trigger('go-fish', 'refresh', {})
    redirect '/game'
  end

  get '/game-over' do
    redirect '/lobby' unless self.class.game.started
    pusher_client.trigger('go-fish', 'refresh', {})
    slim :game_over, locals: { game_results: self.class.game.winner, current_player: session[:current_player] }
  end

  post '/restart-game' do
    self.class.clear_game if session[:host]
    redirect '/join', 308
  end

  post '/refresh' do
    pusher_client.trigger('go-fish', 'refresh', {})
    session[:refresh] = true
    redirect '/lobby'
  end

  private

  def create_message(round_result)
    round_result['card_from'] == 'pool' ? handle_draw_from_pool_message(round_result) : handle_take_from_player_message(round_result)
  end

  def handle_draw_from_pool_message(round_result)
    card = round_result['cards'][0]
    return "You drew #{card.rank} of #{card.suit} from pool" if round_result['turn'] == session[:current_player].name

    "#{round_result['turn']} drew from pool"
  end

  def handle_take_from_player_message(round_result)
    cards = []
    round_result['cards'].each { |card| cards.push("#{card.rank} of #{card.suit}") }
    cards_string = cards.join(', ')
    return ['You took ', " from #{round_result['card_from']}"].join(cards_string) if round_result['turn'] == session[:current_player].name

    ["#{round_result['turn']} took ", ' from you'].join(cards_string)
  end
end

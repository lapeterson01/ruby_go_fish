require 'sinatra'
require 'sinatra/reloader'
require 'sprockets'
require 'sass'
require 'pry'
require_relative 'lib/game'
require_relative 'lib/player'
require_relative 'lib/card_deck'
require_relative 'lib/test_deck'

# Server setup
class Server < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

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

  def self.game(deck = CardDeck.new)
    @@game ||= Game.new(TestDeck.new) # rubocop:disable Style/ClassVars
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
    self.class.game.players.empty? ? session[:host] = true : session[:host] = false
    self.class.game.add_player(player)
    redirect '/lobby'
  end

  get '/lobby' do
    redirect '/game' if self.class.game.started
    slim :lobby, locals: { game: self.class.game, current_player: session[:current_player], host: session[:host] }
  end

  post '/start-game' do
    self.class.game.start
    redirect '/game'
  end

  get '/game' do
    redirect '/lobby' unless self.class.game.started
    redirect '/game-over' if self.class.game.winner
    slim :game, locals: { game: self.class.game, current_player: self.class.game.players[session[:current_player].name], card: session[:card], player: session[:player], result: self.class.game.round_result }
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
    redirect '/game'
  end

  get '/game-over' do
    redirect '/lobby' unless self.class.game.started
    slim :game_over, locals: { game_results: self.class.game.winner, current_player: session[:current_player] }
  end

  post '/restart-game' do
    self.class.clear_game if session[:host]
    redirect '/join', 308
  end
end

require 'sinatra'
require 'sinatra/reloader'
require 'sprockets'
require 'sass'
require 'pry'
require_relative 'lib/game'
require_relative 'lib/player'

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

  def self.game
    @@game ||= Game.new # rubocop:disable Style/ClassVars
  end

  get '/' do
    slim :index
  end

  post '/join' do
    redirect '/' if params['name'] == ''
    player = Player.new(params['name'])
    session[:current_player] = player
    session[:host] = true if self.class.game.players.empty?
    self.class.game.add_player(player)
    redirect '/lobby'
  end

  get '/lobby' do
    redirect '/' unless self.class.game
    redirect '/game' if self.class.game.started
    slim :lobby, locals: { game: self.class.game, current_player: session[:current_player], host: session[:host] }
  end

  post '/start-game' do
    self.class.game.start
    redirect '/game'
  end

  get '/game' do
    slim :game, locals: { game: self.class.game, current_player: session[:current_player] }
  end

  post '/select-card' do
    session[:card] = params['card']
    redirect '/game'
  end

  post '/select-player' do
    session[:player] = params['player']
    redirect '/game'
  end

  post '/play-round' do
    result = self.class.game.play_round(session[:player], session[:card])
binding.pry
    redirect '/game'
  end
end

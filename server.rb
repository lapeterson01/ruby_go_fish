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
  environment.append_path 'assets/stylesheets'
  environment.append_path 'assets/javascripts'
  environment.css_compressor = :scss
  get '/assets/*' do
    env['PATH_INFO'].sub!('/assets', '')
    settings.environment.call(env)
  end
  # End Assets

  def self.game
    @@game ||= Game.new
  end

  get '/' do
    slim :index
  end

  post '/join' do
    player = Player.new(params['name'])
    session[:current_player] = player
    host = true unless self.class.game
    self.class.game.add_player(player)
    redirect '/lobby'
    # host ? redirect '/start/host' : redirect '/start/guest'
  end

  get '/start/:host' do
    slim :start
  end

  get '/lobby' do
    redirect '/' unless self.class.game
    slim :lobby, locals: { game: self.class.game, current_player: session[:current_player] }
  end
end

require 'rack/test'
require 'rspec'
require 'pry'
require 'capybara'
require 'capybara/dsl'
require 'selenium/webdriver'
ENV['RACK_ENV'] = 'test'
require_relative '../server'
require_relative '../lib/playing_card'

class TestDeck
  attr_reader :cards

  RANKS = %w[A K Q J].freeze
  SUITS = %w[Spades Clubs Diamonds Hearts].freeze

  def initialize(cards = SUITS.map { |suit| RANKS.map { |rank| PlayingCard.new(rank, suit) } }.flatten)
    @cards = cards
  end

  def shuffle!
    # do nothing
  end

  def deal
    cards.shift
  end

  def out_of_cards?
    cards.empty?
  end

  def ==(other)
    equal = true
    other.cards.each do |card2|
      equal = false if cards[other.cards.index(card2)] != card2
    end
    equal
  end
end

RSpec.describe Server do
  let(:session1) { Capybara::Session.new(:rack_test, Server.new) }
  let(:session2) { Capybara::Session.new(:rack_test, Server.new) }

  def join_game(session, index = 0)
    player_name = "Player #{index + 1}"
    session.visit '/'
    session.fill_in :name, with: player_name
    session.click_on 'Join'
    player_name
  end

  def start_game
    session1.driver.refresh
    session1.click_on 'Start Game!'
    session2.visit '/game'
  end

  def play_round(rank)
    session1.click_on(rank)
    session1.click_on(class: 'opponent')
    session1.click_on 'Play!'
    session2.driver.refresh
  end

  include Capybara::DSL
  before do
    Capybara.app = Server.new
    Server.game(TestDeck.new)
  end

  after do
    Server.clear_game
  end

  it 'is possible to join a game' do
    join_game(session1)
    expect(session1).to have_content('Players')
    expect(session1).to have_content('Player 1')
  end

  it 'allows multiple players to join game' do
    [session1, session2].each_with_index do |session, index|
      player_name = join_game(session, index)
      expect(session).to have_content('Players')
      expect(session).to have_css('.players__list--current_player', text: player_name)
      expect(session).to have_content('Waiting for other player to join!') if index == 0
    end
    expect(session2).to have_content('Waiting for host to start game!') and have_content('Player 1')
    session1.driver.refresh
    expect(session1).to have_content('Player 2') and have_button('Start Game!')
  end

  it 'allows players to start a game' do
    [session1, session2].each_with_index { |session, index| join_game(session, index) }
    start_game
    expect(session1).to have_content 'Cards: 7' and have_content 'Books: 0'
    expect(session1).to have_content 'Player 1' and have_content 'Player 2'
    expect(session1).to have_content 'Choose a card to ask for...'
    expect(session2).to have_content 'Player 1' and have_content 'Player 2'
    expect(session2).to have_content 'Waiting for Player 1 to take their turn...'
  end

  it 'allows a player to play a round' do
    [session1, session2].each_with_index { |session, index| join_game(session, index) }
    start_game
    play_round('J')
    expect(session1).to have_content 'Cards: 9'
    expect(session2).to have_content 'Cards: 5'
  end

  it 'allows players to accumulate books' do
    [session1, session2].each_with_index { |session, index| join_game(session, index) }
    start_game
    play_round('A')
    expect(session1).to have_content 'Cards: 5' and have_content 'Books: 1'
    expect(session2).to have_content 'Cards: 5'
  end

  it 'ends game when a player or the deck is out of cards and announces winner' do
    [session1, session2].each_with_index { |session, index| join_game(session, index) }
    start_game
    2.times { play_round('Q') }
    2.times { play_round('J') }
    session2.visit '/game-over'
    expect(session1).to have_content 'Game Over!' and have_content 'Winner: Player 1'
    expect(session2).to have_content 'Game Over!' and have_content 'Winner: Player 1'
  end

  # it 'allows players to restart game' do
end

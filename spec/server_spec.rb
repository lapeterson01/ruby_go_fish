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
  include Capybara::DSL
  before do
    Capybara.app = Server.new
    Server.game(TestDeck.new)
  end

  after do
    Server.clear_game
  end

  it 'is possible to join a game' do
    visit '/'
    fill_in :name, with: 'John'
    click_on 'Join'
    expect(page).to have_content('Players')
    expect(page).to have_content('John')
  end

  it 'allows multiple players to join game' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)

    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
      expect(session).to have_content('Players')
      expect(session).to have_css('.players__list--current_player', text: player_name)
      expect(session).to have_content('Waiting for other player to join!') if index == 0
    end
    expect(session2).to have_content('Waiting for host to start game!')
    expect(session2).to have_content('Player 1')
    session1.driver.refresh
    expect(session1).to have_content('Player 2')
    expect(session1).to have_button('Start Game!')
  end

  it 'allows players to start a game' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)

    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
    end
    session1.driver.refresh
    session1.click_on 'Start Game!'
    session2.visit '/game'
    expect(session1).to have_content 'Cards: 7'
    expect(session1).to have_content 'Books: 0'
    expect(session1).to have_content 'Player 1'
    expect(session1).to have_content 'Player 2'
    expect(session1).to have_content 'Choose a card to ask for...'
    expect(session2).to have_content 'Player 1'
    expect(session2).to have_content 'Player 2'
    expect(session2).to have_content 'Waiting for Player 1 to take their turn...'
  end

  it 'allows a player to play a round' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)

    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
    end
    session1.driver.refresh
    session1.click_on 'Start Game!'
    session2.visit '/game'
    session1.click_on(id: 'J')
    session1.click_on(class: 'opponent')
    session1.click_on 'Play!'
    session2.driver.refresh
    expect(session1).to have_content 'Cards: 9'
    expect(session2).to have_content 'Cards: 5'
  end

  it 'allows players to accumulate books' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)

    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
    end
    session1.driver.refresh
    session1.click_on 'Start Game!'
    session2.visit '/game'
    session1.click_on(id: 'A')
    session1.click_on(class: 'opponent')
    session1.click_on 'Play!'
    session2.driver.refresh
    expect(session1).to have_content 'Cards: 5'
    expect(session2).to have_content 'Cards: 5'
    expect(session1).to have_content 'Books: 1'
  end

  it 'ends game when a player or the deck is out of cards and announces winner' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)

    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
    end
    session1.driver.refresh
    session1.click_on 'Start Game!'
    session2.visit '/game'
    2.times do
      session1.click_on(id: 'Q')
      session1.click_on(class: 'opponent')
      session1.click_on 'Play!'
      session1.click_on(id: 'J')
      session1.click_on(class: 'opponent')
      session1.click_on 'Play!'
    end
    session2.driver.refresh
    expect(session1).to have_content 'Game Over!' && 'Winner: Player 1'
    expect(session2).to have_content 'Game Over!' && 'Winner: Player 1'
  end
end

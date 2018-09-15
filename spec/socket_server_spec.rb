require 'rspec'
require_relative '../lib/socket_server'

class MockSocketClient
  attr_reader :socket

  def initialize(port)
    @socket = TCPSocket.new('localhost', port)
    loop do
      sleep(0.1)
      break if @socket
    end
  end

  def provide_input(text)
    @socket.puts(text)
  end

  def capture_output(delay = 0.1)
    sleep(delay)
    @output = @socket.read_nonblock(1000)
  rescue IO::WaitReadable
    @output = ''
  end

  def close
    @socket.close if @socket
  end
end

describe SocketServer do
  def setup_client2(server, clients)
    @client2 = MockSocketClient.new(server.port_number)
    server.accept_new_client
    clients.push(@client2)
  end

  def test_create_game_before_clients_ready(server, client)
    server.create_game_if_possible
    expect(server.games.length).to eq 0
    client.provide_input('start')
  end

  let(:server) { SocketServer.new }
  let(:clients) { [] }

  before do
    server.start
    @client1 = MockSocketClient.new(server.port_number)
    server.accept_new_client
    clients.push(@client1)
  end

  after do
    server.stop
    clients.each(&:close)
  end

  describe '#accept_new_client' do
    it 'accepts pending clients on the server' do
      expect(@client1.capture_output).to match(/You are connected!/) && match(/Waiting for more players/)
      expect(server.pending_clients.length).to eq 1
    end
  end

  describe '#create_game_if_possible' do
    it 'creates a game if there are enough clients to start' do
      server.create_game_if_possible
      expect(server.games.length).to eq 0
      setup_client2(server, clients)
      expect(@client1.capture_output && @client2.capture_output).to match(/2 players have joined.. Type 'start' to begin game or wait for more players/)
      clients.each { |client| client.provide_input('start') }
      server.create_game_if_possible
      expect(server.games.length).to eq 1
    end

    it 'will only create a game if all clients say they are ready to start' do
      setup_client2(server, clients)
      clients.each { |client| test_create_game_before_clients_ready(server, client) }
      server.create_game_if_possible
      expect(server.games.length).to eq 1
    end
  end

  describe '#run_game' do
    it 'runs the game from the server' do
      setup_client2(server, clients)
      clients.each { |client| client.provide_input('start') }
      game = server.create_game_if_possible
      expect(server.run_game(game)).to be_instance_of GameRunner
    end
  end
end

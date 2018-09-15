require 'rspec'
require_relative '../lib/socket_client'
require_relative '../lib/socket_server'
require_relative 'socket_server_spec'

describe SocketClient do
  let(:clients) { [] }
  let(:server) { SocketServer.new }

  before do
    server.start
    @client = MockSocketClient.new(server.port_number)
    server.accept_new_client
    clients.push(@client)
    @connection = server.pending_clients[0]
  end

  after do
    server.stop
    clients.each(&:close)
  end

  describe '#provide_input' do
    it 'sends a text from the server for the client to receive' do
      @connection.provide_input('You are connected')
      expect(@client.capture_output).to match(/You are connected/)
    end
  end

  describe '#capture_output' do
    it 'receives message sent from the clients' do
      @client.provide_input('I am connected')
      expect(@connection.capture_output).to match(/I am connected/)
    end
  end
end

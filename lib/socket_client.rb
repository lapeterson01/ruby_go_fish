# provides client connection information
class SocketClient
  attr_reader :connection
  attr_accessor :ready

  def initialize(connection)
    @connection = connection
    @ready = false
  end

  def provide_input(text)
    @connection.puts(text)
  end

  def capture_output(delay=0.1)
    sleep(delay)
    @connection.read_nonblock(1000)
  rescue IO::WaitReadable
    ''
  end
end
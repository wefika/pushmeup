require 'socket'
require 'openssl'
require 'json'

module APNS

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem_data = nil # this should be the contents of the pem file
  @pass = nil

  @persistent = false
  @mutex = Mutex.new
  @retries = 3 # TODO: check if we really need this

  @sock = nil
  @ssl = nil

  class << self
    attr_accessor :host, :pem_data, :port, :pass
  end

  def self.start_persistence
    @persistent = true
  end

  def self.stop_persistence
    @persistent = false

    @ssl.close
    @sock.close
  end

  def self.send_notification(device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end

  def self.send_notifications(notifications)
    @mutex.synchronize do
      self.with_connection do
        notifications.each do |n|
          @ssl.write(n.packaged_notification)
        end
      end
    end
  end

  def self.feedback
    sock, ssl = self.feedback_connection

    apns_feedback = []

    while line = ssl.read(38)   # Read lines from the socket
      line.strip!
      f = line.unpack('N1n1H140')
      apns_feedback << { :timestamp => Time.at(f[0]), :token => f[2] }
    end

    ssl.close
    sock.close

    return apns_feedback
  end

protected

  def self.with_connection
    attempts = 1

    begin
      # If no @ssl is created or if @ssl is closed we need to start it
      if @ssl.nil? || @sock.nil? || @ssl.closed? || @sock.closed?
        @sock, @ssl = self.open_connection
      end

      yield

    rescue StandardError, Errno::EPIPE
      raise unless attempts < @retries

      @ssl.close
      @sock.close

      attempts += 1
      retry
    end

    # Only force close if not persistent
    unless @persistent
      @ssl.close
      @ssl = nil
      @sock.close
      @sock = nil
    end
  end

  def self.open_connection
    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, self.context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    fhost = self.host.gsub('gateway','feedback')

    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, self.context)
    ssl.connect

    return sock, ssl
  end

  def self.context
    raise ConfigurationError.new("Pem_data not set! (APNS.pem_data = File.read(path/to/pem/file))") unless self.pem_data

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(self.pem_data)
    context.key  = OpenSSL::PKey::RSA.new(self.pem_data, self.pass)
    context
  end

end

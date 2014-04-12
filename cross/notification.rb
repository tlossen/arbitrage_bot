require 'net/smtp'

class Notification

  def self.init(config)
    config = config["smtp"]
    @from, @to = config["from"], config["to"]
    @options = [
      config["server"],
      config["port"],
      config["domain"],
      config["username"],
      config["password"],
      :plain
    ]
    true
  end

  def self.send(subject, body)
    Net::SMTP.start(*@options) do |smtp|
      smtp.send_message(message(subject, body), @from, @to)
    end
    true
  end

  def self.message(subject, body)
    "From: Arbitrage Bot <#{@from}>\n" +
    "To: <#{@to}>\n" +
    "Subject: #{subject}\n\n" +
    body
  end

end

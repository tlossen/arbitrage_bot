require "bter"


class BterClient < Client

	def initialize(currency, config)
    @currency = currency
    @pair = "#{currency}_BTC".downcase
    @client = BterApi.new(
      config["bter"]["key"], 
      config["bter"]["secret"]
    )
  end

  def orderbook
    raw = @client.depth(@pair)
    data = %w[bids asks].map do |type|
      raw[type].map do |row|
        rate, amount = row[0].to_f, row[1].to_f
        [rate, amount, rate * amount]
      end
    end
    Orderbook.new(self, data[0], data[1].reverse)
  end

  def balance
    @client.getfunds["available_funds"].remap do |hash, key, value|
      hash[key.to_s] = value.to_f
    end
  end

  def buy(amount, price)
    puts "#{Time.stamp}  %4s  [bter] buy %.2f for %.8f".cyan % [@currency, amount, price]
    result = @client.buy(@pair, amount, price)
    raise result["message"] unless "true" == result["result"].to_s
    true
  end

  def sell(amount, price)
    puts "#{Time.stamp}  %4s  [bter] sell %.2f for %.8f".cyan % [@currency, amount, price]
    result = @client.sell(@pair, amount, price)
    raise result["message"] unless "true" == result["result"].to_s
    true
  end

end
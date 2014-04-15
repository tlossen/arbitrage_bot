require "bter"


class BterClient

	def initialize(currency, config)
    @currency = currency
    @pair = "#{currency}_BTC".downcase
    @public = Bter::Public.new
    @private = Bter::Trade.new
    @private.key = config["bter"]["key"]
    @private.secret = config["bter"]["secret"]
  end

  def name
    :mintpal
  end

  def orderbook
    raw = @public.depth(@pair)
    data = [:bids, :asks].map do |type|
      raw[type].map do |row|
        rate, amount = row[0].to_f, row[1].to_f
        [rate, amount, rate * amount]
      end
    end
    Orderbook.new(self, data[0], data[1].reverse)
  end

  def balance
    @private.get_info[:available_funds].remap do |hash, key, value|
      hash[key.to_s] = value.to_f
    end
  end

  def buy(amount, price)
    puts "#{Time.stamp}  %4s  [bter] buy %.2f for %.8f".cyan % [@currency, amount, price]
    result = @private.buy(@pair, amount, price)
    raise result[:msg] unless "true" == result[:result].to_s
    true
  end

  def sell(amount, price)
    puts "#{Time.stamp}  %4s  [bter] sell %.2f for %.8f".cyan % [@currency, amount, price]
    result = @private.sell(@pair, amount, price)
    raise result[:msg] unless "true" == result[:result].to_s
    true
  end

  def inspect
    "<#{self.class.name}>"
  end


end
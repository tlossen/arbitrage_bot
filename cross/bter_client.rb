require "bter"


module Bter
  class Trade
    def buy(pair, amount, rate=nil)
      rate ||= get_rate(pair)
      trade({:pair => pair, :type => "BUY", :rate => rate, :amount => amount})
    end
    
    def sell(pair, amount, rate=nil)
      rate ||= get_rate(pair)
      trade({:pair => pair, :type => "SELL", :rate => rate, :amount => amount})
    end
  end
end   


class BterClient

	def initialize(currency, config)
    @currency = currency
    @pair = "#{currency}_BTC"
    @public = Bter::Public.new
    @private = Bter::Private.new
    @private.key = config["bter"]["key"]
    @private.secret = config["bter"]["secret"]
  end

  def name
    :bter
  end

  def orderbook
    raw = @public.depth(@pair)
    data = [:bids, :asks].map do |type|
      raw[type].map do |row|
        [row[0], row[1], row[0] * row[1]]
      end
    end
    Orderbook.new(self, data[0], data[1].reverse)
  end

  def balance
    @private.get_info["available_funds"].change(&:to_f)
  end

  def buy(amount, price)
    puts "#{Time.stamp}  %4s  [bter] buy %.2f for %.8f".cyan % [@currency, amount, price]
    @private.buy(@pair, amount, price)
  end

  def sell(amount, price)
    puts "#{Time.stamp}  %4s  [bter] sell %.2f for %.8f".cyan % [@currency, amount, price]
    @private.sell(@pair, amount, price)
  end

  def inspect
    "<#{self.class.name}>"
  end


end
class Orderbook

  attr_reader :client

  def initialize(client, buy, sell)
    @client, @buy, @sell = client, buy, sell
    raise "malformed orders #{client.inspect}" if top_buy > top_sell
  end

  def top_buy
    @buy[0][0]
  end

  def top_sell
    @sell[0][0]
  end

  def buy_volume(rate)
    volume = 0.0
    @buy.each do |row|
      break if row[0] < rate
      volume += row[1]
    end
    volume
  end

  def sell_volume(rate)
    volume = 0.0
    @sell.each do |row|
      break if row[0] > rate
      volume += row[1]
    end
    volume
  end

  def inspect
    @buy.map(&:inspect).join("\n") + "\n\n" + 
      @sell.map(&:inspect).join("\n")    
  end

end

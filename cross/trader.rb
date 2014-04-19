class Trader

  attr_reader :clients

  def initialize(currency, config)
    @currency = currency
    @clients = {
      bter: BterClient.new(currency, config),
      cryptsy: CryptsyClient.new(currency, config)
    }
    @step = 1.0
    @count = 0
    @volume = 0
    @rate = 0
  end

  def fetch_balance
    @clients.change { |client| client.balance }
  end

  def apply_balance(balance)
    balance = balance.change { |value| value[@currency] || 0 }
    total = balance.values.sum
    balance.each do |key, value| 
      @clients[key].amount = value
      @clients[key].total = total
    end
    @step = total / 200

    "#{Time.stamp}  %4s  [%d: %.3f]  #{ArbitrageBot.as_addition(balance.values)}  (%.3f)" % 
      [@currency, @count, @volume, total * @rate]
  end

  def execute
    books = @clients.values.map(&:orderbook)
    @rate = books.first.top_buy

    low = books.sort_by(&:top_sell).first
    high = books.sort_by(&:top_buy).last

    opp = (low.top_sell < high.top_buy) ?
      opportunity(low, high) :
      OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0, hurdle: 0)

    status = "#{Time.stamp}  %4s  %s: %.8f %.8f  %s: %.8f %.8f  spread: %.8f (%.2f%% > %.2f%%)  volume: %.1f" % [
      @currency, id(low.client), low.top_buy, low.top_sell,
      id(high.client), high.top_buy, high.top_sell,
      opp.spread, opp.percent * 100, opp.hurdle * 100, opp.volume
    ]
    status.gsub!(/0\.(\d{8})/) { |m| $1 } 
    
    if opp.percent > opp.hurdle && opp.volume * low.top_sell > 0.001
      puts status.green 
      amount = [@step * [opp.percent * 100, 20].min, opp.volume, high.client.amount].min
      high.client.exec_sell(amount, opp.limit_sell)
      low.client.exec_buy(amount, opp.limit_buy)
      @count += 1
      @volume += amount * opp.limit_sell
      return true
    elsif opp.percent > 0
      puts status.yellow
    else
      puts status
    end
    false
  end

private

  def opportunity(low, high)
    midrate = (low.top_sell + high.top_buy) / 2.0
    limit_sell = [(midrate * 1.003).round(8), high.top_buy].min
    limit_buy = [(midrate * 0.997).round(8), low.top_sell].max

    OpenStruct.new(
      limit_sell: limit_sell,
      limit_buy: limit_buy,
      spread: high.top_buy - low.top_sell,
      percent: (high.top_buy - low.top_sell) / low.top_sell,
      volume: [low.sell_volume(limit_buy), high.buy_volume(limit_sell)].min,
      hurdle: high.client.hurdle
    )
  end

  def id(client)
    client.class.name.downcase[0]
  end

end
class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)
    Notification.init(config)

    bots = [
      ArbitrageBot.new("LTC", config),
      ArbitrageBot.new("BC", config),
      ArbitrageBot.new("ZET", config)
    ]

    forever do
      maybe_update_balance(bots)
      bots.rotate! 
      bots.rotate!(-1) if bots.first.execute
      sleep(0.5)
    end
  end

  def self.maybe_update_balance(bots)
    append_regularly("balance.log", 40) do |out|
      lines = update_balance(bots)
      body = lines.join("\n")
      puts body.blue
      out.puts body
      append_regularly("balance_1h.log", 60*60) do |out2|
        Notification.send("status", body)
        out2.puts body
      end
    end
  end

  def self.update_balance(bots)
    lines = []
    balance = bots.first.fetch_balance
    bots.each do |bot| 
      lines << bot.apply_balance(balance)
    end
    lines.sort!

    btc = balance.values.map { |value| value["BTC"] || 0 }
    lines << "#{Time.stamp}   BTC  #{as_addition(btc)}"
    lines
  end

  def self.append_regularly(file, seconds, &block)
    modified_at = File.stat(file).ctime rescue 0
    return if Time.now.to_i - modified_at.to_i < seconds
    open(file, "a") do |out|
      yield out
    end
  end

  def self.as_addition(values)
    terms = values.map { |value| "%.1f" % value }.join(" + ")
    "#{terms} = %.1f" % values.sum
  end


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

  def execute
    books = @clients.values.map(&:orderbook)
    @rate = books.first.top_buy

    low = books.sort_by(&:top_sell).first
    high = books.sort_by(&:top_buy).last

    opp = (low.top_sell < high.top_buy) ?
      opportunity(low, high) :
      OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0, hurdle: 0)

    status = "#{Time.stamp}  %4s  lo: %.8f %.8f  hi: %.8f %.8f  spread: %.8f (%.2f%% > %.2f%%)  volume: %.1f" %
      [@currency, low.top_buy, low.top_sell, high.top_buy, high.top_sell, opp.spread, opp.percent * 100, opp.hurdle * 100, opp.volume]
    status.gsub!(/0\.(\d{8})/) { |m| $1 } 
    
    if opp.percent > opp.hurdle && opp.volume * low.top_sell > 0.001
      puts status.green 
      amount = [@step * [opp.percent * 100, 20].min, opp.volume].min
      # high.client.sell(amount, opp.limit_sell)
      # low.client.buy(amount, opp.limit_buy)
      # @count += 1
      # @volume += amount * opp.limit_sell
      return true
    elsif opp.percent > 0
      puts status.yellow
    else
      puts status
    end
    false
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

    "#{Time.stamp}  %4s  [%d: %.3f]  #{self.class.as_addition(balance.values)}  (%.3f)" % 
      [@currency, @count, @volume, total * @rate]
  end

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
      hurdle: min_spread(high.client.amount / high.client.total) / 100.0
    )
  end

  def min_spread(ratio)
    ratio > 0.5 ? 0.6 : [-Math.log(ratio, 10) * 5, 0.6].max
  end

end

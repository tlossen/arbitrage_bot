class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)
    Notification.init(config)

    bots = [
      ArbitrageBot.new("AUR", config),
      ArbitrageBot.new("LTC", config),
      ArbitrageBot.new("BC", config),
      ArbitrageBot.new("ZET", config)
    ]

    forever do
      append_regularly("balance.log", 40) do |out|
        lines = []
        balance = bots.first.fetch_balance
        bots.each do |bot| 
          line = bot.adjust(balance)
          lines << line
          puts line.blue
        end

        c, m = balance[:cryptsy]["BTC"], balance[:mintpal]["BTC"]
        line = "#{Time.stamp}   BTC  %.3f + %.3f = %.3f" % [ c, m, c + m ]
        lines << line
        puts line.blue.on_white
        out.puts line

        append_regularly("balance_1h.log", 60*60) do |out2|
          body = lines.join("\n")
          Notification.send("status", body)
          out2.puts body
        end
      end

      bots.rotate! unless bots.first.execute
      sleep(0.5)
    end
  end

  def self.append_regularly(file, seconds, &block)
    modified_at = File.stat(file).ctime rescue 0
    return if Time.now.to_i - modified_at.to_i < seconds
    open(file, "a") do |out|
      yield out
    end
  end


  attr_reader :mintpal, :cryptsy

  def initialize(currency, config)
    @currency = currency
    @mintpal = MintpalClient.new(currency, config)
    @cryptsy = CryptsyClient.new(currency, config)
    @hurdle = Hash.new(min_spread(0.5))
    @step = 1.0
    @count = 0
    @volume = 0
    @rate = 0
  end

  def execute
    m, c = @mintpal.orderbook, @cryptsy.orderbook
    @rate = c.sell
    
    low, high = nil, nil
    if m.valid? && c.valid?
      if m.sell < c.buy
        low, high = m, c
      elsif c.sell < m.buy
        low, high = c, m
      end
    end

    opp = low ? 
      opportunity(low, high) :
      OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0, hurdle: 0)

    status = "#{Time.stamp}  %4s  c: %.8f %.8f  m: %.8f %.8f  spread: %.8f (%.2f%% > %.2f%%)  volume: %.1f" %
      [@currency, c.buy, c.sell, m.buy, m.sell, opp.spread, opp.percent * 100, opp.hurdle * 100, opp.volume]
    status.gsub!(/0\.(\d{8})/) { |m| $1 } 
    
    if opp.percent > opp.hurdle && opp.volume >= 0.1
      puts status.green 
      amount = [@step * [opp.percent * 100, 20].min, opp.volume].min
      high.client.sell(amount, opp.limit_sell)
      low.client.buy(amount, opp.limit_buy)
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

  def fetch_balance
    Hash(
      :mintpal => @mintpal.balance,
      :cryptsy => @cryptsy.balance
    )
  end

  def adjust(balance)
    c = balance[:cryptsy][@currency] || 0
    m = balance[:mintpal][@currency] || 0
    total = m + c
    @step = total / 200
    @hurdle = {
      cryptsy: min_spread(c / total),
      mintpal: min_spread(m / total)
    }
    "#{Time.stamp}  %4s  [%d: %.3f]  %.1f + %.1f = %.1f  (%.3f)" % 
      [@currency, @count, @volume, c, m, c + m, (c + m) * @rate]
  end

  def opportunity(low, high)
    midrate = (low.sell + high.buy) / 2.0
    limit_sell = [(midrate * 1.003).round(8), high.buy].min
    limit_buy = [(midrate * 0.997).round(8), low.sell].max

    OpenStruct.new(
      limit_sell: limit_sell,
      limit_buy: limit_buy,
      spread: high.buy - low.sell,
      percent: (high.buy - low.sell) / low.sell,
      volume: [low.sell_volume(limit_buy), high.buy_volume(limit_sell)].min,
      hurdle: @hurdle[high.client.name] / 100.0
    )
  end

  def min_spread(ratio)
    ratio > 0.5 ? 0.6 : [-Math.log(ratio, 10) * 5, 0.6].max
  end

end

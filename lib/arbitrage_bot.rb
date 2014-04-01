class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)
    bots = [
      ArbitrageBot.new("AUR", config),
      ArbitrageBot.new("BC", config)
    ]

    forever do
      bots.rotate! unless bots.first.execute

      append_regularly("balance.log", 40) do |out|
        balance = bots.first.fetch_balance
        bots.each { |bot| bot.adjust(balance) }

        # TODO: balance wants to be an object
        line = "#{Time.stamp}  AUR: %.1f + %.1f = %.1f  BC: %.1f + %.1f = %.1f  BTC: %.3f + %.3f = %.3f" %
          [
            balance[:cryptsy]["AUR"],
            balance[:mintpal]["AUR"],
            balance[:cryptsy]["AUR"] + balance[:mintpal]["AUR"],
            balance[:cryptsy]["BC"],
            balance[:mintpal]["BC"],
            balance[:cryptsy]["BC"] + balance[:mintpal]["BC"],
            balance[:cryptsy]["BTC"],
            balance[:mintpal]["BTC"],
            balance[:cryptsy]["BTC"] + balance[:mintpal]["BTC"]
          ]
        puts line.blue
        out.puts line
      end

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
  end

  def execute
    m, c = @mintpal.orderbook, @cryptsy.orderbook
    
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

    status = "#{Time.stamp}  %3s  c: %.5f %.5f  m: %.5f %.5f  spread: %.5f (%.2f%% > %.2f%%)  volume: %.1f" %
      [@currency, c.buy, c.sell, m.buy, m.sell, opp.spread, opp.percent * 100, opp.hurdle * 100, opp.volume]
    
    if opp.percent > opp.hurdle && opp.volume >= 0.1
      puts status.green 
      amount = [@step * [opp.percent * 100, 20].min, opp.volume].min
      high.client.sell(amount, opp.limit_sell) && low.client.buy(amount, opp.limit_buy)
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
    m = balance[:mintpal][@currency] || 0
    c = balance[:cryptsy][@currency] || 0
    total = m + c
    @step = total / 200
    @hurdle = {
      mintpal: min_spread(m / total),
      cryptsy: min_spread(c / total)
    }
  end

  def opportunity(low, high)
    midrate = (low.sell + high.buy) / 2.0
    limit_sell = (midrate * 1.003).round(8)
    limit_buy = (midrate * 0.997).round(8)
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
    [-Math.log(ratio, 10) * 8, 0.6].max
  end

end

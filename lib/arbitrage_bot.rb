class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)
    bots = [
      ArbitrageBot.new("AUR", config)
    ]

    forever do
      bots.rotate!
      bots.first.execute

      append_regularly("balance.log", 60) do |out|
        balance = bots.first.balance
        bots.each { |bot| bot.adjust(balance) }

        line = "#{Time.stamp}  AUR: %.1f + %.1f = %.1f  BTC: %.3f + %.3f = %.3f" %
          [
            balance[:cryptsy]["AUR"],
            balance[:mintpal]["AUR"],
            balance[:cryptsy]["AUR"] + balance[:mintpal]["AUR"],
            balance[:cryptsy]["BTC"],
            balance[:mintpal]["BTC"],
            balance[:cryptsy]["BTC"] + balance[:mintpal]["BTC"]
          ]
        puts line.blue
        out.puts line
      end

      sleep(2)
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
    @mintpal = MintpalClient.new(currency, config)
    @cryptsy = CryptsyClient.new(currency, config)
    @hurdle = Hash.new(min_spread(0.5))
    @step = 1.0
  end

  def execute
    mo, co = @mintpal.orderbook, @cryptsy.orderbook
    
    low, high = nil, nil
    if mo.sell < co.buy
      low, high = mo, co
    elsif co.sell < mo.buy
      low, high = co, mo
    end

    opp = low ? 
      opportunity(low, high) :
      OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0, hurdle: 0)

    status = "#{Time.stamp}  c: %.7f %.7f  m: %.7f %.7f  spread: %.7f (%.2f%%)  vol: %.1f  hurdle: %.2f%%" % 
      [co.buy, co.sell, mo.buy, mo.sell, opp.spread, opp.percent * 100, opp.volume, opp.hurdle * 100]
    
    if opp.percent > opp.hurdle && opp.volume >= 0.1
      puts status.green 
      amount = [step * opp.percent * 100, opp.volume, 20.0].min
      unless high.client.sell(amount, opp.limit_sell) && low.client.buy(amount, opp.limit_buy)
        sleep(30)
      end
    elsif opp.percent > 0
      puts status.yellow
    else
      puts status
    end
  end

  def balance
    Hash(
      :mintpal => @mintpal.balance,
      :cryptsy => @cryptsy.balance
    )
  end

  def adjust(balance)
    m, c = balance[:mintpal], balance[:cryptsy]
    total = c[@currency] + m[@currency]
    @hurdle = {
      mintpal: min_spread(m[@currency] / total),
      cryptsy: min_spread(m[@currency] / total)
    }
    @step = total / 200
  end

  def opportunity(low, high)
    midrate = (low.sell + high.buy) / 2.0
    limit_sell = (midrate * 1.0025).round(8)
    limit_buy = (midrate * 0.9975).round(8)
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
    [-Math.log(ratio, 10) * 10, 0.5].max
  end

end

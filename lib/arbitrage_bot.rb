class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)

    m = MintpalClient.new("AUR", config)
    c = CryptsyClient.new("AUR", config)

    hurdle = Hash.new(min_spread(0.5))
    step = 1

    forever do
      mo, co = m.orderbook, c.orderbook
      
      low, high = nil, nil
      if mo.sell < co.buy
        low, high = mo, co
      elsif co.sell < mo.buy
        low, high = co, mo
      end

      opp = low ? 
        opportunity(low, high, hurdle) :
        OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0, hurdle: 0)

      status = "#{stamp}  c: %.7f %.7f  m: %.7f %.7f  spread: %.7f (%.2f%%)  vol: %.1f  hurdle: %.2f%%" % 
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

      sleep(2)

      append_regularly("balance.log", 60) do |out|
        mb, cb = m.balance, c.balance
        hurdle = {
          mintpal: min_spread(mb.aur / (cb.aur + mb.aur)),
          cryptsy: min_spread(cb.aur / (cb.aur + mb.aur))
        }
        step = cb.aur + mb.aur / 200
        line = "#{stamp}  AUR: %.1f + %.1f = %.1f  BC: %.1f + %.1f = %.1f  BTC: %.3f + %.3f = %.3f" %
          [cb.aur, mb.aur, cb.aur + mb.aur,  cb.bc, mb.bc, cb.bc + mb.bc,  cb.btc, mb.btc, cb.btc + mb.btc]
        puts line.blue
        out.puts line
      end
    end
  end

  def self.opportunity(low, high, hurdle)
    midrate = (low.sell + high.buy) / 2.0
    limit_sell = (midrate * 1.0025).round(8)
    limit_buy = (midrate * 0.9975).round(8)
    OpenStruct.new(
      limit_sell: limit_sell,
      limit_buy: limit_buy,
      spread: high.buy - low.sell,
      percent: (high.buy - low.sell) / low.sell,
      volume: [low.sell_volume(limit_buy), high.buy_volume(limit_sell)].min,
      hurdle: hurdle[high.client.name] / 100.0
    )
  end

  def self.min_spread(ratio)
    [-Math.log(ratio, 10) * 10, 0.5].max
  end

  def self.stamp
    Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.append_regularly(file, seconds, &block)
    modified_at = File.stat(file).ctime rescue 0
    return if Time.now.to_i - modified_at.to_i < seconds
    open(file, "a") do |out|
      yield out
    end
  end

end

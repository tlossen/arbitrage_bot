require "lib/orderbook.rb"
require "lib/cryptsy_bot.rb"
require "lib/mintpal_bot.rb"


class ArbitrageBot

  def self.run 
    m = MintpalBot.new
    c = CryptsyBot.new

    min_spread = Hash.new(3.5)

    forever do
      mo, co = m.orderbook, c.orderbook
      
      low, high = nil, nil
      if mo.sell < co.buy
        low, high = mo, co
      elsif co.sell < mo.buy
        low, high = co, mo
      end

      opp = low ? 
        opportunity(low, high) :
        OpenStruct.new(limit_sell: 0, limit_buy: 0, spread: 0, percent: 0, volume: 0)

      hurdle = low ?
        min_spread[high.bot.name] / 100.0 :
        0.0

      status = "#{stamp}  crypt: %.5f %.5f  mint: %.5f %.5f  spread: %.5f (%.2f%%)  volume: %.1f  hurdle: %.2f%%" % 
        [co.buy, co.sell, mo.buy, mo.sell, opp.spread, opp.percent * 100, opp.volume, hurdle * 100]
      
      if opp.percent > hurdle && opp.volume >= 0.1
        puts status.green 
        amount = [20.0, opp.percent * 100, opp.volume].min
        unless high.bot.sell(amount, opp.limit_sell) && low.bot.buy(amount, opp.limit_buy)
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
        min_spread = {
          mintpal: min_spread(mb.aur / (cb.aur + mb.aur)),
          cryptsy: min_spread(cb.aur / (cb.aur + mb.aur))
        }
        line = "#{stamp}  AUR: %.1f + %.1f = %.1f  BTC: %.3f + %.3f = %.3f" %
          [cb.aur, mb.aur, cb.aur + mb.aur, cb.btc, mb.btc, cb.btc + mb.btc]
        puts line.blue
        out.puts line
      end
    end
  end

  def self.min_spread(ratio)
    0.5 - Math.log(ratio, 10) * 10
  end

  def self.append_regularly(file, seconds, &block)
    modified_at = File.stat(file).ctime rescue 0
    return if Time.now.to_i - modified_at.to_i < seconds
    open(file, "a") do |out|
      yield out
    end
  end

  def self.opportunity(low, high)
    midrate = (low.sell + high.buy) / 2.0
    limit_sell = (midrate * 1.0025).round(8)
    limit_buy = (midrate * 0.9975).round(8)
    OpenStruct.new(
      limit_sell: limit_sell,
      limit_buy: limit_buy,
      spread: high.buy - low.sell,
      percent: (high.buy - low.sell) / low.sell,
      volume: [low.sell_volume(limit_buy), high.buy_volume(limit_sell)].min
    )
  end

  def self.stamp
    Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

end

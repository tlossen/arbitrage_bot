require "lib/orderbook.rb"
require "lib/cryptsy_bot.rb"
require "lib/mintpal_bot.rb"


class ArbitrageBot

  def self.run 
    m = MintpalBot.new
    c = CryptsyBot.new

    loop do
      mo, co = m.orderbook, c.orderbook
      
      low, high = nil, nil
      if mo.sell < co.buy
        low, high = mo, co
      elsif co.sell < mo.buy
        low, high = co, mo
      end

      opp = low ? 
        opportunity(low, high) :
        OpenStruct.new(midrate: 0, spread: 0, percent: 0, volume: 0)

      stamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      status = "#{stamp}  crypt: %.5f %.5f  mint: %.5f %.5f  spread: %.5f (%.2f%%)  mid: %.5f  volume: %.1f" % 
        [co.buy, co.sell, mo.buy, mo.sell, opp.spread, opp.percent * 100, opp.midrate, opp.volume]
      
      if opp.percent > 0.02 && opp.volume >= 0.1
        puts status.green 

        amount = [10.0, opp.volume].min
        if high.bot.sell(amount, opp.midrate)
          low.bot.buy(amount, opp.midrate)
        end
      elsif opp.percent > 0
        puts status.yellow
      else
        puts status
      end

      sleep(5)
    end
  end

  def self.opportunity(low, high)
    midrate = ((low.sell + high.buy) / 2.0).round(8)
    OpenStruct.new(
      :midrate => midrate,
      :spread => high.buy - low.sell,
      :percent => (high.buy - low.sell) / low.sell,
      :volume => [low.sell_volume(midrate), high.buy_volume(midrate)].min
    )
  end

end

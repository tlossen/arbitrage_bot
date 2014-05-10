class ArbitrageBot

  def self.run 
    config = JSON.parse(open("config.json").read)
    Notification.init(config)

    traders = config["currencies"].map do |currency|
      Trader.new(currency, config)
    end
    
    update_balance(traders)
    forever do
      maybe_update_balance(traders)
      traders.rotate! 
      traders.rotate!(-1) if traders.first.execute
    end
  end

  def self.maybe_update_balance(traders)
    append_regularly("balance.log", 60) do |out|
      lines = update_balance(traders)
      body = lines.join("\n")
      puts body.blue
      out.puts body
      append_regularly("balance_1h.log", 4*60*60) do |out2|
        Notification.send("status", body)
        out2.puts body
      end
    end
  end

  def self.update_balance(traders)
    lines = []
    balance = traders.first.fetch_balance
    traders.each do |trader| 
      lines << trader.apply_balance(balance)
    end
    lines.sort!

    btc = balance.values.map { |value| value["BTC"] || 0 }
    lines << "#{Time.stamp}   BTC  #{as_addition(btc, 3)}"
    lines
  end

  def self.append_regularly(file, seconds, &block)
    modified_at = File.stat(file).ctime rescue 0
    return if Time.now.to_i - modified_at.to_i < seconds
    open(file, "a") do |out|
      yield out
    end
  end

  def self.as_addition(values, precision=1)
    terms = values.map { |value| "%.#{precision}f" % value }.join(" + ")
    "#{terms} = %.#{precision}f" % values.sum
  end

end

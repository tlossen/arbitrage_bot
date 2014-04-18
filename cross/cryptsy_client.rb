require "cryptsy/api"


class CryptsyClient

  MARKET = {
    "AUR" => 160,
    "BC" => 179,
    "LTC" => 3,
    "VTC" => 151,
    "DOGE" => 132,
    "ZET" => 85
  }

  attr_accessor :amount, :total

  def initialize(currency, config)
    @currency = currency
    @market = MARKET[currency]
    @client = Cryptsy::API::Client.new(
      config["cryptsy"]["public_key"], 
      config["cryptsy"]["private_key"]
    )
  end

  def orderbook
    json = @client.marketorders(@market)["return"]
    data = %w[buy sell].map do |type|
      json["#{type}orders"].map do |row|
        [row["#{type}price"], row["quantity"], row["total"]].map(&:to_f)
      end
    end
    Orderbook.new(self, *data)
  end

  def balance
    data = @client.getinfo["return"]
    # TODO: data["balances_onhold"] || {}
    data["balances_available"].remap do |hash, key, value|
      hash[key] = value.to_f if value.to_f > 0
    end
  end

  def buy(amount, price)
    puts "#{Time.stamp}  %4s  [cryptsy] buy %.2f for %.8f".cyan % [@currency, amount, price]
    result = @client.createorder(@market, "buy", amount, price)
    raise result["error"] unless "1" == result["success"]
    true
  end

  def sell(amount, price)
    puts "#{Time.stamp}  %4s  [cryptsy] sell %.2f for %.8f".cyan % [@currency, amount, price]
    result = @client.createorder(@market, "sell", amount, price)
    raise result["error"] unless "1" == result["success"]
    true
  end

  def inspect
    "<#{self.class.name}>"
  end

end

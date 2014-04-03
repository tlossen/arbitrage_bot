require "cryptsy/api"


class CryptsyClient

  MARKET = {
    "AUR" => 160,
    "BC" => 179,
    "LTC" => 3,
    "VTC" => 151,
    "DOGE" => 132
  }

  def initialize(currency, config)
    @currency = currency
    @market = MARKET[currency]
    @client = Cryptsy::API::Client.new(
      config["cryptsy"]["public_key"], 
      config["cryptsy"]["private_key"]
    )
  end

  def name
    :cryptsy
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
    puts "#{Time.stamp} [cryptsy]  buy #{@currency} %.2f for %.8f".cyan % [amount, price]
    result = @client.createorder(@market, "buy", amount, price)
    success = ("1" == result["success"])
    # TODO: raise exception
    p result unless success
    success
  rescue
    false
  end

  def sell(amount, price)
    puts "#{Time.stamp} [cryptsy] sell #{@currency} %.2f for %.8f".cyan % [amount, price]
    result = @client.createorder(@market, "sell", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  rescue
    false
  end

  def inspect
    "<#{self.class.name}>"
  end

end

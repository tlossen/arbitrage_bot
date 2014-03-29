require "cryptsy/api"


class CryptsyClient

  MARKET = {
    aur: 160,
    bc: 179
  }

  def initialize(currency, config)
    @currency = currency
    @client = Cryptsy::API::Client.new(
      config["cryptsy"]["public_key"], 
      config["cryptsy"]["private_key"]
    )
  end

  def name
    :cryptsy
  end

  def orderbook
    json = @client.marketorders(market)["return"]
    data = %w[buy sell].map do |type|
      json["#{type}orders"].map do |row|
        [row["#{type}price"], row["quantity"], row["total"]].map(&:to_f)
      end
    end
    Orderbook.new(self, *data)
  end

  def balance
    data = @client.getinfo["return"]
    available, onhold = data["balances_available"], data["balances_onhold"] || {}
    OpenStruct.new(
      aur: available["AUR"].to_f + onhold["AUR"].to_f,
      bc:  available["BC"].to_f + onhold["BC"].to_f,
      btc: available["BTC"].to_f + onhold["BTC"].to_f
    )
  end

  def buy(amount, price)
    puts "[cryptsy] buy #{@currency.to_s.upcase} #{amount} for #{price}".cyan
    result = @client.createorder(market, "buy", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  rescue
    false
  end

  def sell(amount, price)
    puts "[cryptsy] sell #{@currency.to_s.upcase} #{amount} for #{price}".cyan
    result = @client.createorder(market, "sell", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  rescue
    false
  end

  def inspect
    "<#{self.class.name}>"
  end

private

  def market
    MARKET[@currency]
  end

end

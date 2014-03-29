require "cryptsy/api"


class CryptsyClient

  AUR_BTC = 160
  BC_BTC = 179

  def initialize(config)
    @client = Cryptsy::API::Client.new(
      config["cryptsy"]["public_key"], 
      config["cryptsy"]["private_key"]
    )
  end

  def name
    :cryptsy
  end

  def orderbook
    json = @client.marketorders(AUR_BTC)["return"]
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
      btc: available["BTC"].to_f + onhold["BTC"].to_f
    )
  end

  def buy(amount, price)
    puts "[cryptsy] buy #{amount} for #{price}".cyan
    # return true
    result = @client.createorder(AUR_BTC, "buy", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  rescue
    false
  end

  def sell(amount, price)
    puts "[cryptsy] sell #{amount} for #{price}".cyan
    # return true
    result = @client.createorder(AUR_BTC, "sell", amount, price)
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

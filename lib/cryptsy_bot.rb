require "cryptsy/api"


class CryptsyBot

  AUR_BTC = 160

  def initialize
    @client = Cryptsy::API::Client.new(
      config["cryptsy"]["public_key"], 
      config["cryptsy"]["private_key"]
    )
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

  def buy(amount, price)
    puts "[cryptsy] buy #{amount} for #{price}".cyan
    # return true
    result = @client.createorder(AUR_BTC, "buy", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  end

  def sell(amount, price)
    puts "[cryptsy] sell #{amount} for #{price}".cyan
    # return true
    result = @client.createorder(AUR_BTC, "sell", amount, price)
    success = ("1" == result["success"])
    p result unless success
    success
  end

  def inspect
    "<#{self.class.name}>"
  end

private

  def config
    @config ||= JSON.parse(open("config.json").read)
  end

end

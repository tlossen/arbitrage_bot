require "openssl"
require "httparty"
require "uri"


class BterApi
  include HTTParty
  
  base_uri "https://bter.com/api/1/private"

  def self.test
    config = JSON.parse(open("config.json").read)
    api = BterApi.new(
      config["bter"]["key"],
      config["bter"]["secret"]
    )
    api.orderlist["orders"].each do |order|
      puts "cancelling #{order["id"]}"
      api.cancel(order["id"])
    end
  end

  def initialize(key, secret)
    @key = key
    @secret = secret
  end

  def depth(pair)
    response = self.class.get("http://data.bter.com/api/1/depth/#{pair}")
    JSON.parse(response.body)    
  end

  def getfunds
    execute("getfunds")
  end

  def buy(pair, amount, rate)
    execute("placeorder", 
      type: "BUY",
      pair: pair,
      amount: amount,
      rate: rate 
    )
  end

  def sell(pair, amount, rate)
    execute("placeorder", 
      type: "SELL",
      pair: pair,
      amount: amount,
      rate: rate 
    )
  end

  def orderlist
    execute("orderlist")
  end

  def cancel(order_id)
    execute("cancelorder",
      order_id: order_id
    )
  end

private

  def execute(method, params={})
    params.merge!(
      method: method,
      nonce: Time.now.to_i
    )
    response = self.class.post("/#{method}", 
      headers: { "Key" => @key, "Sign" => signature(params) },
      body: params,
      verify: false 
    )
    JSON.parse(response.body)
  end

  def signature(params)
    data = URI.encode_www_form(params)
    OpenSSL::HMAC.hexdigest('sha512', @secret, data)
  end

end
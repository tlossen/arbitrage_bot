class MintpalClient

  AUR_BTC = 25

  BUY = 0
  SELL = 1

  def initialize
    @agent = Mechanize.new do |agent|
      agent.user_agent_alias = "Mac Safari"
    end
  end

  def name
    :mintpal
  end

  def with_login(&block)
    page = @agent.get("https://www.mintpal.com/login")
    token = page.forms.first["csrf_token"]
    begin
      @agent.post("https://www.mintpal.com/action/authenticateUser", {
        csrf_token: token,
        email: config["mintpal"]["email"],
        password: config["mintpal"]["password"]
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      yield token
    rescue
      return false
    ensure
      @agent.get("https://www.mintpal.com/logout")
    end
  end

  def balance
    with_login do |token|
      @agent.get("https://www.mintpal.com/market/AUR/BTC") do |page|
        return OpenStruct.new(
          aur: page.at("a.coinBalance").text.to_f,
          btc: page.at("a.exchangeBalance").text.to_f
        )
      end
    end
  end

  def buy(amount, price)
    puts "[mintpal] buy #{amount} for #{price}".cyan
    # return true
    total = amount * price
    fee = total * 0.0015

    with_login do |token|
      page = @agent.post("https://www.mintpal.com/action/addOrder", {
        csrf_token: token,
        type: BUY,
        market: AUR_BTC,
        amount: amount,
        price: price,
        buyNetTotal: total + fee      
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      result = JSON.parse(page.body)
      success = ("success" == result["response"])
      p result unless success
      success
    end
  end

  def sell(amount, price)
    puts "[mintpal] sell #{amount} for #{price}".cyan
    # return true
    total = amount * price
    fee = total * 0.0015
    with_login do |token|
      page = @agent.post("https://www.mintpal.com/action/addOrder", {
        csrf_token: token,
        type: SELL,
        market: AUR_BTC,
        amount: amount,
        price: price,
        sellNetTotal: total - fee
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      result = JSON.parse(page.body)
      success = ("success" == result["response"])
      p result unless success
      success
    end
  end

  def transfer
    # https://www.mintpal.com/action/requestWithdrawal
    # csrf_token: MTM5NTY4OTQwMm0wUDZQUXNGNXZpanFXTmdTUEZlVDVCS2Y3TnZkWlFi
    # coin: 26
    # amount: 30.00000000
    # address: ARJkGyZ43b6G9ocKiKtvbXPXDMkrZnUauZ
    # password: xxxx
  end

  def orderbook
    data = %w[buy sell].map do |type|
      result = open("https://api.mintpal.com/market/orders/AUR/BTC/#{type.upcase}").read
      JSON.parse(result)["orders"].map do |row|
        [row["price"], row["amount"], row["total"]].map(&:to_f)
      end
    end
    return Orderbook.new(self, *data)
  end

  def inspect
    "<#{self.class.name}>"
  end

private

  def config
    @config ||= JSON.parse(open("config.json").read)
  end

end

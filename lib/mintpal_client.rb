class MintpalClient

  BUY = 0
  SELL = 1

  MARKET = {
    "AUR" => 25,
    "BC" => 23,
    "LTC" => 19,
    "DOGE" => 16
  }

  def initialize(currency, config)
    @currency = currency
    @market = MARKET[currency]
    @config = config
    @agent = Mechanize.new do |agent|
      agent.user_agent_alias = "Mac Safari"
    end
  end

  def name
    :mintpal
  end

  def orderbook
    data = %w[buy sell].map do |type|
      result = open("https://api.mintpal.com/market/orders/#{@currency}/BTC/#{type.upcase}").read
      JSON.parse(result)["orders"].map do |row|
        [row["price"], row["amount"], row["total"]].map(&:to_f)
      end
    end
    return Orderbook.new(self, *data)
  end

  def balance
    with_login do |token|
      @agent.get("https://www.mintpal.com/balances") do |page|
        raw = page.search("#sidebar ul:nth-child(2) li a span").map(&:text)
        return Hash[*raw].change { |value| value.to_f }
      end
    end
  end

  def buy(amount, price)
    puts "#{Time.stamp} [mintpal]  buy #{@currency} %.2f for %.8f".cyan % [amount, price]
    total = amount * price
    fee = total * 0.0015
    with_login do |token|
      page = @agent.post("https://www.mintpal.com/action/addOrder", {
        csrf_token: token,
        type: BUY,
        market: @market,
        amount: amount,
        price: price,
        buyNetTotal: total + fee      
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      result = JSON.parse(page.body)
      success = ("success" == result["response"])
      raise result["reason"] unless success
      success
    end
  end

  def sell(amount, price)
    puts "#{Time.stamp} [mintpal] sell #{@currency} %.2f for %.8f".cyan % [amount, price]
    total = amount * price
    fee = total * 0.0015
    with_login do |token|
      page = @agent.post("https://www.mintpal.com/action/addOrder", {
        csrf_token: token,
        type: SELL,
        market: @market,
        amount: amount,
        price: price,
        sellNetTotal: total - fee
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      result = JSON.parse(page.body)
      success = ("success" == result["response"])
      raise result["reason"] unless success
      success
    end
  end

  def inspect
    "<#{self.class.name}>"
  end

private

  def with_login(&block)
    page = @agent.get("https://www.mintpal.com/login")
    token = page.forms.first["csrf_token"]
    begin
      @agent.post("https://www.mintpal.com/action/authenticateUser", {
        csrf_token: token,
        email: @config["mintpal"]["email"],
        password: @config["mintpal"]["password"]
      }, {
        "x-requested-with" => "XMLHttpRequest"
      })
      yield token
    ensure
      @agent.get("https://www.mintpal.com/logout")
    end
  end

end

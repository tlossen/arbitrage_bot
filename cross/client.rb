class Client

  attr_reader :currency
  attr_accessor :amount, :total

  def exec_buy(amount, limit)
    buy(amount, limit)
    self.amount += amount
  end

  def exec_sell(amount, limit)
    sell(amount, limit)
    self.amount -= amount
  end

  def hurdle
    ratio = amount / total.to_f
    spread = ratio > 0.5 ? 0.6 : [-Math.log(ratio, 10) * 5, 0.6].max
    spread / 100.0
  end

  def inspect
    "<#{self.class.name} #{currency}>"
  end

end
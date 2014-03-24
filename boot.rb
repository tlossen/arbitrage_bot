require "ostruct"
require "colorize"

$LOAD_PATH.unshift File.dirname(__FILE__)

require "lib/arbitrage_bot.rb"

if __FILE__ == $0
  ArbitrageBot.run
end

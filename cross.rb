require "mechanize"
require "ostruct"
require "colorize"

$LOAD_PATH.unshift File.dirname(__FILE__)

require "monkey/hash.rb"
require "monkey/time.rb"
require "monkey/kernel.rb"
require "monkey/mechanize.rb"

require "cross/notification.rb"
require "cross/orderbook.rb"
require "cross/cryptsy_client.rb"
require "cross/bter_client.rb"

require "cross/arbitrage_bot.rb"

if __FILE__ == $0
  ArbitrageBot.run
end

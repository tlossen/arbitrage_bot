require "mechanize"
require "open-uri"
require "ostruct"
require "colorize"

$LOAD_PATH.unshift File.dirname(__FILE__)

require "cross/hash_patch.rb"
require "cross/time_patch.rb"
require "cross/kernel_patch.rb"
require "cross/mechanize_patch.rb"

require "cross/notification.rb"
require "cross/orderbook.rb"
require "cross/cryptsy_client.rb"
require "cross/mintpal_client.rb"

require "cross/arbitrage_bot.rb"

if __FILE__ == $0
  ArbitrageBot.run
end

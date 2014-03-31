require "mechanize"
require "open-uri"
require "ostruct"
require "colorize"

$LOAD_PATH.unshift File.dirname(__FILE__)

require "lib/hash_patch.rb"
require "lib/time_patch.rb"
require "lib/kernel_patch.rb"
require "lib/mechanize_patch.rb"

require "lib/orderbook.rb"
require "lib/cryptsy_client.rb"
require "lib/mintpal_client.rb"

require "lib/arbitrage_bot.rb"

if __FILE__ == $0
  ArbitrageBot.run
end

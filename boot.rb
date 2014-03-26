require "mechanize"
require "open-uri"
require "ostruct"
require "colorize"

$LOAD_PATH.unshift File.dirname(__FILE__)

require "lib/kernel.rb"
require "lib/mechanize_patch.rb"
require "lib/arbitrage_bot.rb"

if __FILE__ == $0
  ArbitrageBot.run
end

# coding: utf-8
require "timeout"

module Kernel

  def forever(every = nil, &block)
    loop do
      begin
        start = Time.now.to_f
        Timeout.timeout(10) { yield }
        if every
          wait = every - (Time.now.to_f - start)
          sleep(wait) if wait > 0
        end
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts "#{Time.stamp}  #{e.message}".red
        # puts e.backtrace
        sleep(1)
      end
    end
  end

end

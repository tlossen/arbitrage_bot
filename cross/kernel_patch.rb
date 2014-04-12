# coding: utf-8
module Kernel

  def forever(&block)
    loop do
      begin
        yield
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts "#{Time.stamp}  #{e.message}".red
        puts e.backtrace
        5.times do
          puts
          sleep(1)
        end
      end
    end
  end

end

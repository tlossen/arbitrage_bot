# coding: utf-8
module Kernel

  def forever(&block)
    loop do
      begin
        yield
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts e.message.red
        sleep(3)
      end
    end
  end

end

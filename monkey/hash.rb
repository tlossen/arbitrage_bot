# coding: utf-8
class Hash

  # source: ruby cookbook, recipe 5.13
  def remap(hash = self.class.new)
    each { |k, v| yield hash, k, v }
    hash
  end

  def change(&block)
    remap { |hash, k, v| hash[k] = yield(v) }
  end

end

def Hash(h = Hash.new)
  h || Hash.new
end

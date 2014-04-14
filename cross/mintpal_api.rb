require "openssl"
require "Base64"
require "httparty"


class MintpalApi
  include HTTParty
  
  base_uri "https://api.mintpal.com/v2"

  def initialize(public_key, private_key)
    @public_key = public_key
    @private_key = private_key
  end

  def wallet_balances
    get("/wallet/balances")
  end

  def get(url, params)
    params.merge(key: @public_key, time: Time.now.to_i)
    params.merge(hash: hmac(...))
    self.class.get(url, query: params)
  end

  def hmac(data)
    digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), 
      @private_key, data)
    Base64.encode64(digest).strip
  end

end
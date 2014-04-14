require "openssl"
require "Base64"
require "httparty"
require "uri"


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

private

  def get(path, params)
    params.merge(key: @public_key, time: Time.now.to_i)
    params.merge(hash: hmac(base_uri + "?" + URI.encode_www_form(params)))
    self.class.get(path, query: params)
  end

  def hmac(data)
    sha256 = OpenSSL::Digest::Digest.new('sha256')
    digest = OpenSSL::HMAC.digest(sha256, @private_key, data)
    Base64.encode64(digest).strip
  end

end
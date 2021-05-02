require 'bitly'

class BitlyUrl
  def initialize(bitly_token, url)
    @client = Bitly::API::Client.new(token: bitly_token)
    @url = url
  end

  def short_url
    @client.shorten(long_url: @url).link
  end
end

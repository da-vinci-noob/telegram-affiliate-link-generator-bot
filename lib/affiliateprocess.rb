require "addressable/uri"

class AffiliateProcess
  attr_reader :updated_url

  def initialize(url, tag)
    @updated_url = url
    @tag = tag
  end

  def fetch_url
    response = HTTParty.get(@updated_url, follow_redirects: false)
    if response.code == 301
      @updated_url = response.headers[:location]
    else
      response.request.last_uri.to_s
    end
  end

  def clean_url
    uri = Addressable::URI.parse(@updated_url)
    params = uri.query_values
    params.delete('affid') unless params.nil?
    params.delete('tag') unless params.nil?
    uri.query_values = params
    @updated_url = uri.to_s
  end

  def add_tracking_id(tracking_id)
    @updated_url = "#{@updated_url}?" unless @updated_url.include?('?')
    @updated_url = "#{@updated_url}&#{@tag}=#{tracking_id}"
  end
  
end

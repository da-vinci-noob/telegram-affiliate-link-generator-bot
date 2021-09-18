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
    uri.query_values = remove_existing_tracking_ids(uri.query_values)
    @updated_url = uri.to_s
  end

  def add_tracking_id(tracking_id)
    @updated_url = "#{@updated_url}?" unless @updated_url.include?('?')
    @updated_url = "#{@updated_url}&#{@tag}=#{tracking_id}"
  end

  def remove_existing_tracking_ids(params)
    params&.delete('affid')
    params&.delete('tag')
    params&.delete('vsugd')
    params
  end
end

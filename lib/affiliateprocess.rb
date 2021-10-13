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
    url = @updated_url.to_s
    url = remove_existing_tracking_ids(url)
    uri = Addressable::URI.parse(url)
    @updated_url = uri.to_s.gsub!('&amp;', '&')
  end

  def add_tracking_id(tracking_id)
    @updated_url = "#{@updated_url}?" unless @updated_url.include?('?')
    @updated_url = "#{@updated_url}&#{@tag}=#{tracking_id}"
  end

  def remove_existing_tracking_ids(url)
    uri = url.split('?')
    url_query = []
    unless uri[1].nil?
      url_query = uri[1].split('&').reject do |param|
        param.match(/^aff.*=/) ||
          param.match(/^tag=/) ||
          param.match(/^vsugd.*=/)
      end
    end
    "#{uri.first}?#{url_query.join('&')}"
  end
end

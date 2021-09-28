require_relative 'bitlyurl'

module ProcessUrl
  class << self
    attr_accessor :chat_id
  end

  def self.individual(url)
    case url
    when /amazon.in/
      amazon(url, short: false)
    when /amzn.to/, /amzn.in/
      amazon(url, short: true)
    when /flipkart.com/
      flipkart(url, short: false)
    when /fkrt.it/
      flipkart(url, short: true)
    else
      redirection(url)
    end
  end

  def self.amazon(url, short: false)
    amazon = AffiliateProcess.new(url, 'tag')
    amazon.fetch_url if short
    amazon.clean_url
    amzn_id = Redis.current.get("#{chat_id}:amzn_id")
    amazon.add_tracking_id(amzn_id)
    shorten_url(amazon.updated_url)
  end

  def self.flipkart(url, short: false)
    flipkart = AffiliateProcess.new(url, 'affid')
    flipkart.fetch_url if short
    flipkart.clean_url
    fkrt_id = Redis.current.get("#{chat_id}:fkrt_id")
    flipkart.add_tracking_id(fkrt_id)
    shorten_url(flipkart.updated_url, flipkart: true)
  end

  def self.redirection(url)
    url = get_redirected_url(url)
    return "URL Not Supported: #{url}" if url.is_a?(String)

    return flipkart(url.request.last_uri) if url.request.last_uri.host.include? 'flipkart'

    return amazon(url.request.last_uri) if url.request.last_uri.host.include? 'amazon'

    urls = URI.extract(url.parsed_response, %w[http https])
    urls.each { |u| @flipkart = u if u.include? 'flipkart' }
    return flipkart(@flipkart) if defined? @flipkart

    url = get_redirected_url(urls[2]) if url.include? 'cashbackUrl'
    "URL Not Supported: #{url.is_a?(String) ? url : url.request.last_uri}"
  end

  def self.get_redirected_url(url)
    processed_url = url
    loop do
      @res = HTTParty.get(processed_url)
      break if @res.request.last_uri.to_s == processed_url

      processed_url = @res.request.last_uri.to_s
    end
    @res
  rescue StandardError => e
    "Error: #{e.message}: #{@res&.request&.last_uri} "
  end

  def self.shorten_url(url, flipkart: false)
    if flipkart
      fkrt_url = "https://affiliate.flipkart.com/a_url_shorten?url=#{CGI.escape(url)}"
      res = HTTParty.get(fkrt_url, follow_redirects: false)
      res['response']['shortened_url']
    else
      bitly_id = Redis.current.get("#{chat_id}:bitly_id")
      BitlyUrl.new(bitly_id, url).short_url
    end
  rescue StandardError => e
    puts e.inspect
    @error = e.inspect
  end
end

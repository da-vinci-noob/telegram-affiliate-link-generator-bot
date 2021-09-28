require 'telegram_bot'
require 'redis'
require 'uri'
require 'httparty'

require_relative 'bitlyurl'
require_relative 'affiliateprocess'
require_relative 'instruction'
require_relative 'setup'
require_relative 'validate'

class Bot
  def initialize
    @redis = Redis.new(host: ENV['REDIS_HOST'])
    bot = TelegramBot.new(token: ENV['BOT_TOKEN'])

    bot.get_updates(fail_silently: true) do |message|
      puts "@#{message.from.username}: #{message.text}"
      @command = message.get_command_for(bot)
      @chat_id = message.chat.id
      @first_name = message.from.first_name
      instruction = Instruction.new(@first_name)
      validate = Validate.new(@chat_id)
      setup = Setup.new(redis: @redis, chat_id: @chat_id, command: @command)
      message.reply do |reply|
        case @command
        when %r{^/start}
          reply.text = instruction.start
        when %r{^/help}
          reply.text = instruction.help
        when %r{^/bitly_setup}
          reply.text = instruction.bitly
        when %r{^/amazon }
          reply.text = setup.amazon
        when %r{^/bitly }
          reply.text = setup.bitly
        when %r{^/flipkart }
          reply.text = setup.flipkart
        when %r{^/previews }
          reply.text = setup.previews
        when %r{^/delete }
          reply.text = setup.delete
        when %r{^/forward }
          reply.text = setup.forward
        when %r{^/show_deleted}
          reply.text = setup.show_deleted
        when /http/i
          if validate.affiliate_tags
            urls = URI.extract(@command, %w[http https])
            updated_msg = @command
            begin
              @success = true
              urls.each do |url|
                new_url = process_url(url).to_s
                updated_msg.sub!(url, new_url)
                @success = false if (new_url.include? 'URL Not Supported') || new_url.nil? || new_url.empty?
              end
            rescue SocketError => e
              updated_msg = "Can't Connect to the server #{e.inspect}"
              @success = false
            rescue URI::InvalidURIError => e
              updated_msg = "Invalid URL #{e.inspect}"
              @success = false
            end
          else
            updated_msg = 'Please do the Setup First /help. If you want to use only Amazon Affiliate you can add any random work for flipkart or vice versa'
          end
          reply.text = updated_msg
          to_delete = @redis.smembers("#{@chat_id}:delete")
          reply.text.gsub!(Regexp.union(to_delete), '') unless to_delete.empty?
        else
          reply.text = "I have no idea what #{@command.inspect} means. You can view available commands with \help"
        end
        puts "sending #{reply.text.inspect} to @#{message.from.username}"
        reply.disable_web_page_preview = true if @redis.get("#{@chat_id}:previews") == 'disable'
        reply.send_with(bot)
        channel_id = @redis.get("#{@chat_id}:forward")
        if @success && channel_id
          begin
            send_to_channel(channel_id, reply.text).send_with(bot)
          rescue NameError => e
            reply.text = 'Please Double check Channel Username and if you have added the Bot as an Admin to the Channel.'
            reply.send_with(bot)
            puts 'Error with Channel ID'
          end
        end
        @success = false
      end
    end
  end

  def shorten_url(url, flipkart: false)
    begin
      if flipkart
        fkrt_url = "https://affiliate.flipkart.com/a_url_shorten?url=#{CGI.escape(url)}"
        res = HTTParty.get(fkrt_url, follow_redirects: false)
        res['response']['shortened_url']
      else
        bitly_id = @redis.get("#{@chat_id}:bitly_id")
        BitlyUrl.new(bitly_id, url).short_url
      end
    rescue => e
      @error = e.inspect
      puts e.inspect
    end
  end

  def process_url(url)
    case url
    when /amazon.in/
      process_amazon_url(url, short: false)
    when /amzn.to/, /amzn.in/
      process_amazon_url(url, short: true)
    when /flipkart.com/
      process_flipkart_url(url, short: false)
    when /fkrt.it/
      process_flipkart_url(url, short: true)
    else
      process_redirection(url)
    end
  end

  def process_amazon_url(url, short: false)
    amazon = AffiliateProcess.new(url, 'tag')
    amazon.fetch_url if short
    amazon.clean_url
    amzn_id = @redis.get("#{@chat_id}:amzn_id")
    amazon.add_tracking_id(amzn_id)
    shorten_url(amazon.updated_url)
  end

  def process_flipkart_url(url, short: false)
    flipkart = AffiliateProcess.new(url, 'affid')
    flipkart.fetch_url if short
    flipkart.clean_url
    fkrt_id = @redis.get("#{@chat_id}:fkrt_id")
    flipkart.add_tracking_id(fkrt_id)
    shorten_url(flipkart.updated_url, flipkart: true)
  end

  def process_redirection(url)
    url = get_redirected_url(url)
    return "URL Not Supported: #{url}" if url.is_a?(String)

    return process_flipkart_url(url.request.last_uri) if url.request.last_uri.host.include? 'flipkart'

    return process_amazon_url(url.request.last_uri) if url.request.last_uri.host.include? 'amazon'

    urls = URI.extract(url.parsed_response, %w[http https])
    urls.each { |u| @flipkart = u if u.include? 'flipkart' }
    return process_flipkart_url(@flipkart) if defined? @flipkart

    url = get_redirected_url(urls[2]) if url.include? 'cashbackUrl'
    "URL Not Supported: #{url.is_a?(String) ? url : url.request.last_uri}"
  end

  def get_redirected_url(url)
    processed_url = url
    begin
      loop do
        @res = HTTParty.get(processed_url)
        break if @res.request.last_uri.to_s == processed_url

        processed_url = @res.request.last_uri.to_s
      end
      @res
    rescue => e
      "Error: #{e.message}: #{@res&.request&.last_uri} "
    end
  end

  def send_to_channel(channel_id, text)
    channel = TelegramBot::Channel.new(id: channel_id)
    message = TelegramBot::OutMessage.new
    message.chat = channel
    message.text = text
    message.disable_web_page_preview = true if @redis.get("#{@chat_id}:previews") == 'disable'
    message
  end
end

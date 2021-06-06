require 'telegram_bot'
require 'redis'
require 'uri'
require 'httparty'

require_relative 'bitlyurl'
require_relative 'affiliateprocess'

class Bot
  def initialize
    @redis = Redis.new(host: ENV['REDIS_HOST'])
    bot = TelegramBot.new(token: ENV['BOT_TOKEN'])

    bot.get_updates(fail_silently: true) do |message|
      puts "@#{message.from.username}: #{message.text}"
      @command = message.get_command_for(bot)
      @chat_id = message.chat.id
      @first_name = message.from.first_name
      message.reply do |reply|
        case @command
        when %r{^/start}
          reply.text = start_text
        when /help/i
          reply.text = help_text
        when /bitly_setup/i
          reply.text = bityly_setup_text
        when %r{^/amazon }
          reply.text = "Hello, Your Amazon Affiliate ID has been set to #{setup_amazon}. 🤖"
        when %r{^/bitly }
          reply.text = "Hello, Your Bitly Access Token has been set to #{setup_bitly}. 🤖"
        when %r{^/flipkart }
          reply.text = "Hello, Your Flipkart Affiliate ID has been set to #{setup_flipkart}. 🤖"
        when %r{^/previews }
          previews = @command.sub('/previews ', '')
          @redis.set("#{@chat_id}:previews", previews)
          if previews == "disable"
            reply.text = "Your Link Previews will be disabled from now!"
          else
            reply.text = "Your Link Previews will be enabled from now!"
          end
        when %r{^/delete }
          delete = @command.sub('/delete ', '')
          @redis.sadd("#{@chat_id}:delete", [delete])
          reply.text = "#{delete}, has been added to the list of text which will be removed from the returned message by bot"
        when %r{^/forward }
          reply.text = "Hello, Your Messages will be forward to #{setup_forward}. 🤖"
        when %r{^/show_deleted}
          text = @redis.smembers("#{@chat_id}:delete")
          reply.text = "#{text.join(", ")}\nThese words has been added by you to the Bot and will be removed from the Returned Message"
        when %r{^/forward }
          reply.text = "Hello, Your Messages will be forward to #{setup_forward}. 🤖"
        when /http/i
          if validate_setup
            urls = URI.extract(@command)
            @updated_msg = @command
            begin
              urls.each do |url|
                new_url = process_url(url)
                @updated_msg = @updated_msg.sub(url, new_url)
              end
              @success = true
            rescue SocketError => e
              @updated_msg = "Can't Connect to the server #{e.inspect}"
              @success = false
            rescue URI::InvalidURIError => e
              @updated_msg = "Invalid URL #{e.inspect}"
              @success = false
            end
          else
            @updated_msg = "Please do the Setup First /help"
          end
          reply.text = @updated_msg
          to_delete = @redis.smembers("#{@chat_id}:delete")
          reply.text.gsub!(Regexp.union(to_delete),'') unless to_delete.empty?
        else
          reply.text = "I have no idea what #{@command.inspect} means. You can view available commands with \help"
        end
        puts "sending #{reply.text.inspect} to @#{message.from.username}"
        reply.disable_web_page_preview = true if @redis.get("#{@chat_id}:previews") == "disable"
        reply.send_with(bot)
        channel_id = @redis.get("#{@chat_id}:forward")
        if @success && channel_id
          begin
            send_to_channel(channel_id, reply.text).send_with(bot)
          rescue NameError => e
            reply.text = "Please Double check Channel Username and if you have added the Bot as an Admin to the Channel."
            reply.send_with(bot)
            puts "Error with Channel ID"
          end
        end
        @success = false
      end
    end
  end

  def start_text
    "Hello, #{@first_name} 🤖. All I can do is say hello for now.\nThis Bot can save you a lot time. Try /help to see available commands."
  end

  def help_text
    "Hello, #{@first_name}. 🤖\nYou need to make do some setup before the using this Bot\n\n\nAvailable Commands are\n\n
    1. Set your Amazon Affiliate Tracking ID\n/amazon <tracking_id>\nExample: /amazon track-21\n\n
    2. Set your Flipkart Affiliate Tracking ID\n/flipkart <tracking_id>\nExample: /flipkart track_id\n\n
    3. Set your Bitly API Key for link shortning\n/bitly <api_key>\nClick here to know how to setup /bitly_setup\nExample: /bitly API_KEYbhdsirb\n\n
    4. *NEW ADDITION* (Optional)\nForward your messages to Channel. Add this bot to your channel as an Admin and setup the Channel in the Bot by command /forward <username of the channel including @>\nExample: /forward @google\n\n
    5. *NEW ADDITION* (Optional)\nYou can disable link Previews for the messages that bot returns.\nExample: \n/previews disable (For Disabling Link previews)\n/previews *anything else* (For Enabling Link Previews)\n\n
    6. *NEW ADDITION* (Optional)\nYou can now add characters/text/word to delete from message (This can include any promotional message.) by /delete *text to delete*
    Example: /delete hello\n\n
    7. Show Your Words which you have included to the delete list.
    Example: /show_deleted\n\n\nAnd Finally\nSend Your Message with Flipkart or Amazon Link"
  end

  def bityly_setup_text
    "Hello, #{@first_name}. 🤖\nYou need to make an Account on Bit.ly/\n\n\n1. Goto https://bitly.com/\n\n2. Create an Account and Login\n\n3. Then goto https://bitly.is/accesstoken to and generate your access token for bit.ly to generate short links\n\n4. Then copy the generated Access Token\n\n5. Set your Bitly Access token for link shortning\n/bitly <access_token>\nExample: /bitly ACCESS_TOKENbhdsirb\n\n\nAnd Finally\nSend Your Message with Flipkart or Amazon Link"
  end

  def setup_amazon
    amzn_id = @command.sub('/amazon ', '')
    @redis.set("#{@chat_id}:amzn_id", amzn_id)
    amzn_id
  end

  def setup_flipkart
    fkrt_id = @command.sub('/flipkart ', '')
    @redis.set("#{@chat_id}:fkrt_id", fkrt_id)
    fkrt_id
  end
  
  def setup_bitly
    bitly_id = @command.sub('/bitly ', '')
    @redis.set("#{@chat_id}:bitly_id", bitly_id)
    bitly_id
  end

  def setup_forward
    channel_id = @command.sub('/forward ', '')
    @redis.set("#{@chat_id}:forward", channel_id)
    channel_id
  end

  def shorten_url(url)
    begin
      bitly_id = @redis.get("#{@chat_id}:bitly_id")
      BitlyUrl.new(bitly_id, url).short_url
    rescue => e
      @error = e.inspect
      puts e.inspect
    end
  end

  def process_url(url)
    case url
    when /amazon.in/
      process_amazon_url(url, short = false)
    when /amzn.to/, /amzn.in/
      process_amazon_url(url, short = true)
    when /flipkart.com/
      process_flipkart_url(url, short = false)
    when /fkrt.it/
      process_flipkart_url(url, short = true)
    else
      "URL Not Supported: #{url}"
    end
  end

  def process_amazon_url(url, short = false)
    amazon = AffiliateProcess.new(url, 'tag')
    amazon.fetch_url if short
    amazon.clean_url
    amzn_id = @redis.get("#{@chat_id}:amzn_id")
    amazon.add_tracking_id(amzn_id)
    shorten_url(amazon.updated_url)
  end

  def process_flipkart_url(url, short = false)
    flipkart = AffiliateProcess.new(url, 'affid')
    flipkart.fetch_url if short
    flipkart.clean_url
    fkrt_id = @redis.get("#{@chat_id}:fkrt_id")
    flipkart.add_tracking_id(fkrt_id)
    shorten_url(flipkart.updated_url)
  end

  def validate_setup
    @redis.exists?("#{@chat_id}:bitly_id") && @redis.exists?("#{@chat_id}:fkrt_id") && @redis.exists?("#{@chat_id}:amzn_id")
  end

  def send_to_channel(channel_id, text)
    channel = TelegramBot::Channel.new(id: channel_id)
    message = TelegramBot::OutMessage.new
    message.chat = channel
    message.text = text
    message.disable_web_page_preview = true if @redis.get("#{@chat_id}:previews") == "disable"
    message
  end
end

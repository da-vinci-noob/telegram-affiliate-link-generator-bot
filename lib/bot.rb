require 'telegram_bot'
require 'redis'
require 'uri'
require 'httparty'

require_relative 'affiliateprocess'
require_relative 'instruction'
require_relative 'setup'
require_relative 'validate'
require_relative 'process_url'

class Bot
  include ProcessUrl
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
      setup = Setup.new(chat_id: @chat_id, command: @command)
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
              ProcessUrl.chat_id = @chat_id
              urls.each do |url|
                new_url = ProcessUrl.individual(url).to_s
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
          to_delete = Redis.current.smembers("#{@chat_id}:delete")
          reply.text.gsub(/#{Regexp.union(to_delete).source}/i, '') unless to_delete.empty?
        else
          reply.text = "I have no idea what #{@command} means. You can view available commands with \help"
        end
        puts "sending #{reply.text.inspect} to @#{message.from.username}"
        reply.disable_web_page_preview = true if Redis.current.get("#{@chat_id}:previews") == 'disable'
        reply.send_with(bot)
        channel_id = Redis.current.get("#{@chat_id}:forward")
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

  def send_to_channel(channel_id, text)
    channel = TelegramBot::Channel.new(id: channel_id)
    message = TelegramBot::OutMessage.new
    message.chat = channel
    message.text = text
    message.disable_web_page_preview = true if Redis.current.get("#{@chat_id}:previews") == 'disable'
    message
  end
end

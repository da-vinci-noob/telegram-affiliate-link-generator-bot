# Class contain all the setup configurations
class Setup
  def initialize(chat_id:, command:)
    @chat_id = chat_id
    @command = command
  end

  def amazon
    amzn_id = @command.sub('/amazon ', '')
    Redis.current.set("#{@chat_id}:amzn_id", amzn_id)
    "Hello, Your Amazon Affiliate ID has been set to #{amzn_id}. 🤖"
  end

  def flipkart
    fkrt_id = @command.sub('/flipkart ', '')
    Redis.current.set("#{@chat_id}:fkrt_id", fkrt_id)
    "Hello, Your Flipkart Affiliate ID has been set to #{fkrt_id}. 🤖"
  end

  def bitly
    bitly_id = @command.sub('/bitly ', '')
    Redis.current.set("#{@chat_id}:bitly_id", bitly_id)
    "Hello, Your Bitly Access Token has been set to #{bitly_id}. 🤖"
  end

  def forward
    channel_id = @command.sub('/forward ', '')
    Redis.current.set("#{@chat_id}:forward", channel_id)
    "Hello, Your Messages will be forward to #{channel_id}. 🤖"
  end

  def previews
    previews = @command.sub('/previews ', '')
    Redis.current.set("#{@chat_id}:previews", previews)
    if %w[disable false].include?(previews)
      'Your Link Previews will be disabled from now!'
    else
      'Your Link Previews will be enabled from now!'
    end
  end

  def delete
    content = @command.sub('/delete ', '')
    Redis.current.sadd("#{@chat_id}:delete", [content])
    "#{content}, has been added to the list of text which will be removed from the returned message by bot"
  end

  def show_deleted
    content = Redis.current.smembers("#{@chat_id}:delete")
    "#{content.join(', ')}\nThese words has been added by you to the Bot and will be removed from the Returned Message"
  end
end

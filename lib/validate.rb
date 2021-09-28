# Class contain validations
class Validate
  def initialize(chat_id)
    @chat_id = chat_id
  end

  def affiliate_tags
    Redis.current.exists?("#{@chat_id}:bitly_id") &&
      Redis.current.exists?("#{@chat_id}:fkrt_id") &&
      Redis.current.exists?("#{@chat_id}:amzn_id")
  end
end

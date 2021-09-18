# Class Have all the long instruction at one place
class Instruction
  def initialize(first_name)
    @first_name = first_name
  end

  def start
    "Hello, #{@first_name} 🤖. All I can do is say hello for now.\nThis Bot can save you a lot time. Try /help to see available commands."
  end

  def bitly
    "Hello, #{@first_name}. 🤖\nYou need to make an Account on Bit.ly/\n\n\n1. Goto https://bitly.com/\n\n2. Create an Account and Login\n\n3. Then goto https://bitly.is/accesstoken to and generate your access token for bit.ly to generate short links\n\n4. Then copy the generated Access Token\n\n5. Set your Bitly Access token for link shortning\n/bitly <access_token>\nExample: /bitly ACCESS_TOKENbhdsirb\n\n\nAnd Finally\nSend Your Message with Flipkart or Amazon Link"
  end

  def help
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
end

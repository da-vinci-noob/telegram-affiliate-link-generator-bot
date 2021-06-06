# Telegram Affliate Link Generator Bot [Amazon/Flipkart]

**NEW ADDITION** (Optional)

1. Forward your messages to channel.
2. Disable Link Previews for the Messages returned with Affiliate links.
3. You can now add characters/text/word to delete from message
4. See What words you added to delete.

## Setup

1. Fork the Repo
2. Make your changes.
3. Commit and push to your Git
4. Deploy the code to heroku or any other service which you like
5. Add Redis DB Server to the Service (Used to save user's details)
6. Open Telegram
7. Goto [BotFather](https://t.me/BotFather), if link not working search @BotFather in telegram.
8. Then type `/start` in Botfather
9. Click on `/newbot` or type `/newbot`
10. Add Any name you like for the Telegram Bot.
11. Add Username for your bot you like which needs to end with `_bot`
12. Copy the Token generated which will be needed in the next step
13. Add below Environment Variables to your Service.

```
BOT_TOKEN = <token which you got from BotFather>idle
REDIS_URL = <URL for Redis Server>
```

14. Goto your bot in telegram.
15. Click on `start` or type /start
16. Click on `help` or type /help
17. Add your Amazon affliate tracking id. Example below

```
/amazon tracking_id-21
```

18. Add your Flipkart affliate tracking id. Example below

```
/flipkart tracking_id
```

19. Add your Bit.ly Access token. Example below

```
/bitly API-KETuIB
```

20. (Optional) Add your channel username to the bot for auto-forwarding of messages. Example below

```
/forward @username
```

21. (Optional) Disable Link Previews for messages sent back to the bot and channel with affiliate link. Example below

```
/previews disable (For Disabling Previews)
/previews *any other text* (For Enabling Previews if disabled)
```

22. (Optional) You can now add characters/text/word to delete from message (This can include any promotional message). Example below

```
/delete *text to delete*
/delete hello
```

23. Show Your Words which you have included to the delete list.. Example below

```
/show_deleted
```

Note:

1. Bot will guide you how to get Bit.ly Access token by below command.

```
/bitly_setup
```

2. This Bot only supports below URL's.

```
https://amazon.in
https://amzn.to
http://fkrt.it
https://flipkart.com
```

3. You can open an issue on github if you find any.

### Demo

1. Goto

   > [Telegram Bot Link](http://t.me/affiliate_link_gen_bot)

2. Continue from the Setup No. 14

---

## To Contribute (Add new Feature, Improve Something )

- Fork the project repository
- Clone your fork
- Navigate to your local repository
- Check that your fork is the 'origin' remote by:
  > `git remote -v`
  - if not add 'origin' remote by:
    > `git remote add origin <URL_OF_YOUR_FORK>`
- Add the project repository as the 'upstream' remote by:
  > `git remote add upstream <URL_OF_THIS_PROJECT>`
- Check that you now have two remotes: an origin that points to your fork, and an upstream that points to the project repository by:
  > `git remote -v`
- Pull the latest changes from upstream into your local repository.
  > `git pull upstream main`
- Create a new branch
  > `git checkout -b BRANCH_NAME`
- Make changes in your local repository
- Commit your changes
- Push your changes to your fork
  > `git push origin BRANCH_NAME`
- Create Pull Request
  > baseRepo - base:main <- yourRepo - compare:BRANCH_NAME
- Add Your description, Add any Images/Videos if required and Submit PR.
- You can add more commits/comments to the PR.
- You can delete the Branch (BRANCH_NAME) after your PR has been accepted and merged
- Sync your local Fork Repo to Updated Project Repo.

  > `git pull upstream main`

  > `git push origin main`

---

Thanks, Contributions are welcome! <3.

Made with :heart: and ![Ruby](https://img.shields.io/badge/-Ruby-000000?style=flat&logo=ruby)

#### DISCLAIMER: This software is for educational purposes only. This software should not be used for illegal activity. The author is not responsible for its use.

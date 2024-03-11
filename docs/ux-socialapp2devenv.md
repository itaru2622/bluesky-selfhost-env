# check social-app with dev-env

condition: 
 - follows https://github.com/bluesky-social/social-app/blob/main/docs/build.md 
 - atproto/packages/dev-env
 - socia-app self build
 - operation from social-app

## check which features work, asof-2024-03-10

- create account
   - NG: 'continue' after inputing password (arial-label='Continue to next step')
   - ok: 'clear'    after inputing password (arial-label='Clear onboarding state')

- post/reply:
   - ok: post article
   - ok: reply article

- vote:
   - ok: vote 'like' to article

- search:
   - ok: search users in social-app
   - ok: search posts in social-app

- feed:
   - NO: get list just by 'more feeds'
   - ok: search feeds in #feeds tab
   - ok: pin to home for feed


## check which features work, asof-2024-02-06

- create account
   - NG: 'continue' after inputing password (arial-label='Continue to next step')
   - ok: 'clear' after inputing password (arial-label='Clear onboarding state')

- post/reply:
   - ok: post article
   - ok: reply article

- vote:
   - ok: vote 'like' to article

- search:
   - ok: search users in social-app
   - NG: search posts in social-app

- feed:
   - ok: get list by 'more feeds'
   - ok: pin to home for feed


## check which features work, asof-2024-01-06

- search:
   - NG: search posts in social-app

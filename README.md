# Messenger Uber Bot

Simple messenger bot to book a driver in Uber

## Setup

```
  rbenv install 2.3.1
  rbenv local 2.3.1

  gem install bundler
  bundle install

  bundle exec rake db:create
  bundle exec rake db:migrate
  bundle exec rake db:seed

  rails s
```

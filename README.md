# Unione

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/unione`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unione'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install unione

## Usage

update the settings for action_mailer

```ruby
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address: 'smtp.example.ru',
    port: '25',
    user_name: 'your_username',
    password: 'your_password',
    authentication: :plain,
    openssl_verify_mode: 'none'
  }
```

add api_key and username to secretes.yml

```ruby
  unione:
    username: your_username
    api_key: your_api_key
```

Add follow code to application_mailer

```ruby
  self.delivery_method = :unione
  self.unione_settings = Rails.application.secrets.unione
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/siraz-provectus/unione.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

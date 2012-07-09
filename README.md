## Web Scraping in Ruby using Bobik

This is a community-supported Bobik SDK for web scraping in Ruby.

### Installing

+ Either install directly and system-wide:
  1. Run `gem install bobik` from command line
  2. Add `require 'bobik'` to your Ruby code

+ Or, add to bundler:
  1. add `gem 'bobik'` to Gemfile
  2. Unless you're using Rails (which includes all gems from Gemfile automatically), add `require 'bobik'` to your Ruby code

### Using
Here's a quick example to get you started.

```ruby
  client = Bobik::Client.new(:auth_token => YOUR_AUTH_TOKEN, :timeout_ms => 60000)
  
  sample_data = {
    urls:       ['amazon.com', 'zynga.com', 'http://finance.yahoo.com/'],
    queries:    ["//th", "//img/@src", "return document.title", "return $('script').length"]
  }
  
  client.scrape(sample_data, true) do |results, errors|
    pust "Errors: #{errors}"
    results.each do |url, queries|
      puts "Printing results for #{url}"
      queries.each do |query, result|
        puts " Result of query #{query}: #{result}"
      end
    end
  end
```

Full API reference is available at http://usebobik.com/sdk/

### Contributing

Write to support@usebobik.com to become a collaborator.

### Bugs?
Submit them here on GitHub: https://github.com/emirkin/bobik_ruby_gem/issues
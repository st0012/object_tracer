# TappingDevice

![GitHub Action](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)
[![Gem Version](https://badge.fury.io/rb/tapping_device.svg)](https://badge.fury.io/rb/tapping_device)
[![Maintainability](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/maintainability)](https://codeclimate.com/github/st0012/tapping_device/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/test_coverage)](https://codeclimate.com/github/st0012/tapping_device/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/st0012/tapping_device/badges/users.svg)](https://www.codetriage.com/st0012/tapping_device)


## Introduction

I'm a super lazy person and I hate digging into code. So I created `TappingDevice` to make the program tell me what it does, instead of me reading the code and simulate it in my head.

### Contract Tracing For Objects

The concept is very simple, it's basically like [contact tracing](https://en.wikipedia.org/wiki/Contact_tracing) for your Ruby objects. You can use 

- `print_calls(object)` to see what method calls the object performs
- `print_traces(object)` to see how the object interacts with other objects (like used as an arugment)

### Example - `print_calls`

Still sounds vague? Let's see some examples:

In [Discourse](https://github.com/discourse/discourse), it uses `Guardian` class for authorization (like policy objects). It's barely visible in controller actions, but it does many checks under the hood. Now, let's see what `Guadian` does when a user creates a post, here's the action:


```ruby
  def create
    @manager_params = create_params
    @manager_params[:first_post_checks] = !is_api?

    manager = NewPostManager.new(current_user, @manager_params)

    if is_api?
      memoized_payload = DistributedMemoizer.memoize(signature_for(@manager_params), 120) do
        result = manager.perform
        MultiJson.dump(serialize_data(result, NewPostResultSerializer, root: false))
      end

      parsed_payload = JSON.parse(memoized_payload)
      backwards_compatible_json(parsed_payload, parsed_payload['success'])
    else
      result = manager.perform
      json = serialize_data(result, NewPostResultSerializer, root: false)
      backwards_compatible_json(json, result.success?)
    end
  end
```

You don't see anything like it in the action, how should you know what it does? Digging into the code? Not so hurry!

With `TappingDevice` installed

```ruby
gem 'tapping_device', group: :development
```

you can use `print_calls` to show what method calls the object performs

```ruby
  def create
    print_calls(guardian)
    @manager_params = create_params
   
    # .....
```


Now if you execute the code, like via tests 

```shell
$ rspec spec/requests/posts_controller_spec.rb:1687
```

You'll see all the method calls made by the `guardian` object, e.g.


[image:A21F4511-E86B-4DD2-BCDE-F1C9124C7255-9062-0004D558933A8267/截圖 2020-05-24 下午3.01.28.png]


Each entry consists of 5 parts


[image:51B41D29-A063-430B-87AE-C8D8EF9D8FF6-9062-0004D62BF838E17C/Payload Explained.png]


### Example - `print_traces`

If you're not interested in what an object does, but what it interacts with other parts of the program, e.g. used as arguments. You can use the `print_traces` helper. Let's see how `Discourse` uses the `manager` object when creating a post

```ruby
  def create
    @manager_params = create_params
    @manager_params[:first_post_checks] = !is_api?
   
    manager = NewPostManager.new(current_user, @manager_params)

    print_traces(manager)
    # .....
```

And after running the test case

```shell
$ rspec spec/requests/posts_controller_spec.rb:603
```

[image:5D190BF6-989C-444D-AE56-0B4956457A16-9062-0004D6D314CD4DCF/截圖 2020-05-24 下午3.28.02.png]

You can see that it performs 2 calls: `perform` and `perform_create_post`. And it's also used as `manager` argument in various of calls of the `NewPostManager` class.

**You can try these examples yourself on [my fork of discourse](https://github.com/st0012/discourse/tree/demo-for-tapping-device)**


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'tapping_device', group: :development
```

And then execute:

```
$ bundle
```

Or install it directly:

```
$ gem install tapping_device
```

**Depending on the size of your application, `TappingDevice` could harm the performance significantly.  So make sure you don't put it inside the production group**


## Advance Usages & Options 

### Add Conditions With `.with`

Sometimes we don't need to know all the calls or traces of an object, we just want some of them. In those cases, we can chain the helpers with `.with` to filter the calls/traces.

```ruby
# only prints calls with name matches /foo/
print_calls(object).with do |payload|
  payload.method_name.to_s.match?(/foo/)
end
```

### `colorize: false`

By default `print_calls` and `print_traces` colorize their output. If you don't want the colors, you can use `colorize: false` to disable it.


```ruby
print_calls(object, colorize: false)
```


### `inspect: true`

As you might have noticed, all the objects are converted into strings with `#to_s` instead of `#inspect`.  This is because when used on some Rails objects, `#inspect` can generate a significantly larger string than `#to_s`. For example:

``` ruby
post.to_s #=> #<Post:0x00007f89a55201d0>
post.inspect #=> #<Post id: 649, user_id: 3, topic_id: 600, post_number: 1, raw: "Hello world", cooked: "<p>Hello world</p>", created_at: "2020-05-24 08:07:29", updated_at: "2020-05-24 08:07:29", reply_to_post_number: nil, reply_count: 0, quote_count: 0, deleted_at: nil, off_topic_count: 0, like_count: 0, incoming_link_count: 0, bookmark_count: 0, score: nil, reads: 0, post_type: 1, sort_order: 1, last_editor_id: 3, hidden: false, hidden_reason_id: nil, notify_moderators_count: 0, spam_count: 0, illegal_count: 0, inappropriate_count: 0, last_version_at: "2020-05-24 08:07:29", user_deleted: false, reply_to_user_id: nil, percent_rank: 1.0, notify_user_count: 0, like_score: 0, deleted_by_id: nil, edit_reason: nil, word_count: 2, version: 1, cook_method: 1, wiki: false, baked_at: "2020-05-24 08:07:29", baked_version: 2, hidden_at: nil, self_edits: 0, reply_quoted: false, via_email: false, raw_email: nil, public_version: 1, action_code: nil, image_url: nil, locked_by_id: nil, image_upload_id: nil>
```


## Lower-Level Helpers
`print_calls` and `print_traces` aren't the only helpers you can get from `TappingDevice`. They are actually built on top of other helpers, which you can use as well. To know more about them, please check [this page](https://github.com/st0012/tapping_device/wiki/Advance-Usages)


## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/st0012/tapping_device. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TappingDevice project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tapping_device/blob/master/CODE_OF_CONDUCT.md).

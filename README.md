# TappingDevice

![GitHub Action](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)
[![Gem Version](https://badge.fury.io/rb/tapping_device.svg)](https://badge.fury.io/rb/tapping_device)
[![Maintainability](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/maintainability)](https://codeclimate.com/github/st0012/tapping_device/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/test_coverage)](https://codeclimate.com/github/st0012/tapping_device/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/st0012/tapping_device/badges/users.svg)](https://www.codetriage.com/st0012/tapping_device)


## Introduction
`TappingDevice` makes the objects tell you what they do, so you don't need to track them yourself.

#### Contact Tracing For Objects

The concept is very simple. It's basically like [contact tracing](https://en.wikipedia.org/wiki/Contact_tracing) for your Ruby objects. You can use 

- `print_calls(object)` to see what the object does
- `print_traces(object)` to see how the object interacts with other objects (like used as an argument)
- `print_mutations(object)` to see what actions changed the object's state (instance variables)

Still sounds vague? Let's see some examples:

### `print_calls` - Track Method Calls

In [Discourse](https://github.com/discourse/discourse), it uses the `Guardian` class for authorization (like policy objects). It's barely visible in controller actions, but it does many checks under the hood. Now, let's say we want to know what the `Guardian` would do when a user creates a post; here's the controller action:

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

As you can see, it doesn't even exist in the controller action, which makes tracking it by reading code very hard to do.

But with `TappingDevice`. You can use `print_calls` to show what method calls the object performs

```ruby
  def create
    # you can retrieve the current guardian object by calling guardian in the controller
    print_calls(guardian)
    @manager_params = create_params
   
    # .....
```

Now, if you execute the code, like via tests:

```shell
$ rspec spec/requests/posts_controller_spec.rb:603
```

You can get all the method calls it performs with basically everything you need to know

<img src="https://github.com/st0012/tapping_device/blob/master/images/print_calls.png" alt="image of print_calls output" width="50%">

Let's take a closer look at each entry. Everyone of them contains the method call's
- method name 
- method source class/module
- call site
- arguments
- return value

![explanation of individual entry](https://github.com/st0012/tapping_device/blob/master/images/print_calls%20-%20single%20entry.png)

These are the information you'd have to look up one by one manually (probably with many debug code writing). Now you can get all of them in just one line of code.


### `print_traces` - See The Object's Traces

If you're not interested in what an object does, but what it interacts with other parts of the program, e.g., used as arguments. You can use the `print_traces` helper. Let's see how `Discourse` uses the `manager` object when creating a post

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

You will see that it performs 2 calls: `perform` and `perform_create_post`. And it's also used as `manager` argument in various of calls of the `NewPostManager` class.

![image of print_traces output](https://github.com/st0012/tapping_device/blob/master/images/print_traces.png)

### `print_mutations` - Display All State Changes At Once

Another thing that often bothers developers in debugging is to track an object's internal state changes. And `tapping_device` allows you to see all state changes with just one line of code. Let me keep using [Discourse](https://github.com/discourse/discourse) to demonstrate it. 

When updating a post, it uses an object called `PostRevisor` to revise it:

```ruby
# app/controllers/posts_controller.rb
class PostsController
  def update
    # ......
    revisor = PostRevisor.new(post, topic)
    revisor.revise!(current_user, changes, opts)
    # ......
  end
end
```

In the `PostReviser#revise!`, it uses many instance variables to track different information:

```ruby
  # lib/post_revisor.rb
  def revise!(editor, fields, opts = {})
    @editor = editor
    @fields = fields.with_indifferent_access
    @opts = opts

    @topic_changes = TopicChanges.new(@topic, editor)
    
    # ......

    @revised_at = @opts[:revised_at] || Time.now
    @last_version_at = @post.last_version_at || Time.now

    @version_changed = false
    @post_successfully_saved = true

    @validate_post = true
    # ......
  end
```

Tracking the changes of that many instance variables can be a painful task, especially when we want to know the values before and after certain method call. This is why I created `print_mutations` to save us from this. 

Like other helpers, you only need 1 line of code

```ruby
# app/controllers/posts_controller.rb
class PostsController
  def update
    # ......
    revisor = PostRevisor.new(post, topic)
    print_mutations(revisor)
    revisor.revise!(current_user, changes, opts)
    # ......
  end
end
```

And then you'll see all the state changes:

<img src="https://github.com/st0012/tapping_device/blob/master/images/print_mutations.png" alt="image of print_mutations output" width="50%">

Now you can see what method changes which states. And more importantly, you get to see all the sate changes at once!

**You can try these examples on [my fork of discourse](https://github.com/st0012/discourse/tree/demo-for-tapping-device)**

### `write_*` helpers

`tapping_device` also provides helpers that write the events into files:

- `write_calls(object)`
- `write_traces(object)`
- `write_mutations(object)`

The default destination is `/tmp/tapping_device.log`. You can change it with the `log_file`  option:

```ruby
write_calls(object, log_file: "/tmp/another_file")
```


### Use `with_HELPER` for chained method calls

One thing that really bothers me when debugging is to break method chains from time to time. Let's say I call a service object like this:

```ruby
SomeService.new(params).perform
```

In order to debug it, I'll need to break the method chain into

```ruby
service = SomeService.new(params)
print_calls(service, options)
service.perform
```

That's a 3-line change! Which obviously violates the goal of `tapping_device` - making debugging easier with 1 line of code.

So here's another option, just insert a `with_HELPER_NAME` call in between:

```ruby
SomeService.new(params).with_print_calls(options).perform
```

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

Sometimes we don't need to know all the calls or traces of an object; we just want some of them. In those cases, we can chain the helpers with `.with` to filter the calls/traces.

```ruby
# only prints calls with name matches /foo/
print_calls(object).with do |payload|
  payload.method_name.to_s.match?(/foo/)
end
```

### Options

There are many options you can pass when using a helper method. You can list all available options and their default value with

```ruby
TappingDevice::Configurable::DEFAULTS #=> {
  :filter_by_paths=>[], 
  :exclude_by_paths=>[], 
  :with_trace_to=>50, 
  :event_type=>:return, 
  :hijack_attr_methods=>false, 
  :track_as_records=>false, 
  :inspect=>false, 
  :colorize=>true, 
  :log_file=>"/tmp/tapping_device.log"
}
```

Here are some commonly used options:

#### `colorize: false` 

- default: `true`

By default `print_calls` and `print_traces` colorize their output. If you don't want the colors, you can use `colorize: false` to disable it.


```ruby
print_calls(object, colorize: false)
```


#### `inspect: true` 

- default: `false`

As you might have noticed, all the objects are converted into strings with `#to_s` instead of `#inspect`.  This is because when used on some Rails objects, `#inspect` can generate a significantly larger string than `#to_s`. For example:

``` ruby
post.to_s #=> #<Post:0x00007f89a55201d0>
post.inspect #=> #<Post id: 649, user_id: 3, topic_id: 600, post_number: 1, raw: "Hello world", cooked: "<p>Hello world</p>", created_at: "2020-05-24 08:07:29", updated_at: "2020-05-24 08:07:29", reply_to_post_number: nil, reply_count: 0, quote_count: 0, deleted_at: nil, off_topic_count: 0, like_count: 0, incoming_link_count: 0, bookmark_count: 0, score: nil, reads: 0, post_type: 1, sort_order: 1, last_editor_id: 3, hidden: false, hidden_reason_id: nil, notify_moderators_count: 0, spam_count: 0, illegal_count: 0, inappropriate_count: 0, last_version_at: "2020-05-24 08:07:29", user_deleted: false, reply_to_user_id: nil, percent_rank: 1.0, notify_user_count: 0, like_score: 0, deleted_by_id: nil, edit_reason: nil, word_count: 2, version: 1, cook_method: 1, wiki: false, baked_at: "2020-05-24 08:07:29", baked_version: 2, hidden_at: nil, self_edits: 0, reply_quoted: false, via_email: false, raw_email: nil, public_version: 1, action_code: nil, image_url: nil, locked_by_id: nil, image_upload_id: nil>
```

#### `hijack_attr_methods: true` 

- default: `false`
	- except for `tap_mutation!` and `print_mutations`
	
Because `TracePoint` doesn't track methods generated by `attr_*` helpers (see [this issue](https://bugs.ruby-lang.org/issues/16383) for more info), we need to redefine those methods with the normal method definition. 

For example, it generates

```ruby
def name=(val)
  @name = val
end
```

for

```ruby
attr_writer :name
```

This hack will only be applied to the target instance with `instance_eval`. So other instances of the class remain untouched.

The default is `false` because

1. Checking what methods are generated by `attr_*` helpers isn't free. It's an `O(n)` operation, where `n` is the number of methods the target object has. 
2. It's still unclear if this hack safe enough for most applications.


### Global Configuration

If you don't want to pass options every time you use a helper, you can use global configuration to change the default values:

```ruby
TappingDevice.config[:colorize] = false
TappingDevice.config[:hijack_attr_methods] = true
```

And if you're using Rails, you can put the configs under `config/initializers/tapping_device.rb` like this:

```ruby
if defined?(TappingDevice)
  TappingDevice.config[:colorize] = false
  TappingDevice.config[:hijack_attr_methods] = true
end
```


### Lower-Level Helpers
`print_calls` and `print_traces` aren't the only helpers you can get from `TappingDevice`. They are actually built on top of other helpers, which you can use as well. To know more about them, please check [this page](https://github.com/st0012/tapping_device/wiki/Advance-Usages)


### Related Blog Posts
- [Optimize Your Debugging Process With Object-Oriented Tracing and tapping_device](http://bit.ly/object-oriented-tracing) 
- [Debug Rails issues effectively with tapping_device](https://dev.to/st0012/debug-rails-issues-effectively-with-tappingdevice-c7c)
- [Want to know more about your Rails app? Tap on your objects!](https://dev.to/st0012/want-to-know-more-about-your-rails-app-tap-on-your-objects-bd3)


## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/st0012/tapping_device. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TappingDevice project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tapping_device/blob/master/CODE_OF_CONDUCT.md).

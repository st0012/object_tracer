# TappingDevice

![GitHub Action](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)
[![Gem Version](https://badge.fury.io/rb/tapping_device.svg)](https://badge.fury.io/rb/tapping_device)
[![Maintainability](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/maintainability)](https://codeclimate.com/github/st0012/tapping_device/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/test_coverage)](https://codeclimate.com/github/st0012/tapping_device/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/st0012/tapping_device/badges/users.svg)](https://www.codetriage.com/st0012/tapping_device)


## Introduction
As the name states, `TappingDevice` allows you to secretly listen to different events of an object:

- `Method Calls` - what does the object do
- `Traces` - how is the object used by the application
- `State Mutations` - what happens inside the object

After collecting the events, `TappingDevice` will output them in a nice, readable format to either stdout or a file. 

**Ultimately, its goal is to let you know all the information you need for debugging with just 1 line of code.**

## Usages

### Track Method Calls

By tracking an object's method calls, you'll be able to observe the object's behavior very easily

<img src="https://github.com/st0012/tapping_device/blob/master/images/print_calls.png" alt="image of print_calls output" width="50%">

Each entry consists of 5 pieces of information:
- method name
- source of the method
- call site
- arguments
- return value

![explanation of individual entry](https://github.com/st0012/tapping_device/blob/master/images/print_calls%20-%20single%20entry.png)

#### Helpers

- `print_calls(object)` - prints the result to stdout
- `write_calls(object, log_file: "file_name")` - writes the result to a file
	- the default file is `/tmp/tapping_device.log`, but you can change it with `log_file: "new_path"` option

#### Use Cases
- Understand a service object/form object's behavior
- Debug a messy controller

### Track Traces

By tracking an object's traces, you'll be able to observe the object's journey in your application

![image of print_traces output](https://github.com/st0012/tapping_device/blob/master/images/print_traces.png)

#### Helpers

- `print_traces(object)` - prints the result to stdout
- `write_traces(object, log_file: "file_name")` - writes the result to a file
	- the default file is `/tmp/tapping_device.log`, but you can change it with `log_file: "new_path"` option

#### Use Cases
- Debug argument related issues
- Understand how a library uses your objects

### Track State Mutations

By tracking an object's traces, you'll be able to observe the state changes happen inside the object between each method call

<img src="https://github.com/st0012/tapping_device/blob/master/images/print_mutations.png" alt="image of print_mutations output" width="50%">

#### Helpers

- `print_mutations(object)` - prints the result to stdout
- `write_mutations(object, log_file: "file_name")` - writes the result to a file
	- the default file is `/tmp/tapping_device.log`, but you can change it with `log_file: "new_path"` option

#### Use Cases
- Debug state related issues
- Debug memoization issues

### Track All Instances Of A Class

It's not always easy to directly access the objects we want to track, especially when they're managed by a library (e.g. `ActiveRecord::Relation`). In such cases, you can use these helpers to track the class's instances:

- `print_instance_calls(ObjectKlass)`
- `print_instance_traces(ObjectKlass)`
- `print_instance_mutations(ObjectKlass)`
- `write_instance_calls(ObjectKlass)`
- `write_instance_traces(ObjectKlass)`
- `write_instance_mutations(ObjectKlass)`


### Use `with_HELPER_NAME` for chained method calls

In Ruby programs, we often chain multiple methods together like this:

```ruby
SomeService.new(params).perform
```

And to debug it, we'll need to break the method chain into

```ruby
service = SomeService.new(params)
print_calls(service, options)
service.perform
```

This kind of code changes are usually annoying, and that's one of the problems I want to solve with `TappingDevice`.

So here's another option, just insert a `with_HELPER_NAME` call in between:

```ruby
SomeService.new(params).with_print_calls(options).perform
```

And it'll behave exactly like

```ruby
service = SomeService.new(params)
print_calls(service, options)
service.perform
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

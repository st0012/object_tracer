# TappingDevice

![](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)

`tapping_device` is a gem built on top of Ruby’s `TracePoint` class that allows you to tap method calls of specified objects. The purpose for this gem is to make debugging Rails applications easier. For example, you can use it to see who calls you `Post` records

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    device = TappingDevice.new do |payload|
      puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
    end
    device.tap_on!(@post)
  end
end
```

And you can see these in log:

```
Method: name line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
Method: user_id line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
Method: to_param line: /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```

Or you can use `tap_assoc!`. This is very useful for tracking potential n+1 query calls, here’s a sample from my work

```ruby
device = TappingDevice.new do |payload|
  puts "Assoc: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
end
device.tap_assoc!(order)
```

```
Assoc: payments line: /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
Assoc: line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:44
Assoc: effective_line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:110
Assoc: amending_orders line: /MY_PROJECT/app/models/order.rb:385
Assoc: amends_order line: /MY_PROJECT/app/models/order.rb:432
```

However, depending on the size of your application, tapping any object could **harm the performance significantly**. **Don't use this on production**


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tapping_device', group: :development
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install tapping_device
```

## Usage

### Create a device object
In order to tap on something, you need to first initialize a tapping device with a block that process the call info.

```ruby
device = TappingDevice.new do |payload|
  if payload[:method_name].to_s.match?(/foo/)
    puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
  end
end
```

### Performance issue and setup stop condition

Because `tapping_device` is built upon `TracePoint`, which literally scans **every method call** on **every object**. Even if we filter out the calls we’re not interested in, just filtering out through those method calls takes time if your application isn’t a small one. So it’s very important to stop the tapping device at a certain point. You can do this in 2 ways:

#### Use `device.stop_when(&block)` to set a stop condition
To define a stop condition, you can use `stop_when` method.

```ruby
device.stop_when do |payload|
  device.calls.count >= 10 # stop after gathering 10 calls' data
end
```

**If you don’t set a stop condition, you need to use tapping methods that has exclamation mark**, like `device.tap_on!(post)`.

#### `device.stop!`
If you don’t define a stop condition, you can also use `device.stop!` to stop it manually.

### Start tapping

#### Methods
- `TappingDevice#tap_init(class)` -  tracks a class’ instance initialization
- `TappingDevice#tap_on(object)` - tracks any calls received by the object
- `TappingDevice#tap_assoc(activerecord_object)` - tracks association calls on a record, like `post.comments`

#### Info of the call
All tapping methods (start with `tap_`) takes a block and yield a hash as block argument. 

```ruby
{
  :receiver=>#<Student:0x00007fabed02aeb8 @name="Stan", @age=18, @tapping_device=[#<TracePoint:return `age'@/PROJECT_PATH/tapping_device/spec/trackable_spec.rb:17>]>, 
  :method_name=>:age, 
  :arguments=>[], 
  :return_value=>18, 
  :filepath=>"/PROJECT_PATH/tapping_device/spec/trackable_spec.rb", 
  :line_number=>"171", 
  :defined_class=>Student, 
  :trace=>[], 
  :tp=>#<TracePoint:return `age'@/PROJECT_PATH/tapping_device/spec/trackable_spec.rb:17>
}
```

The hash contains

- `receiver` - the receiver object
- `method_name` - method’s name (symbol) 
	- e.g. `:name`
- `arguments` - arguments of the method call
	- e.g. `[[:name, “Stan”], [:age, 25]]`
- `return_value` - return value of the method call
- `filepath` - path to the file that performs the method call
- `line_number` 
- `defined_class` - in which class that defines the method being called
- `trace` - stack trace of the call. Default is an empty array unless `with_trace_to` option is set
- `tp` - trace point object of this call


### Options
- `with_trace_to: 10` - the number of traces we want to put into `trace`. Default is `nil`, so `trace` would be empty
- `exclude_by_paths: [/path/]` - an array of call path patterns that we want to skip. This could be very helpful when working on large project like Rails applications.
- `filter_by_paths: [/path/]` - only contain calls from the specified paths

### `#tap_init`

```ruby
calls = []
device = TappingDevice.new do |payload|
  calls << [payload[:method_name], payload[:arguments]]
end
device.tap_init!(Student) 

Student.new("Stan", 18)
Student.new("Jane", 23)

puts(calls.to_s) #=> [[:initialize, [[:name, "Stan"], [:age, 18]]], [:initialize, [[:name, "Jane"], [:age, 23]]]]
```

### `tap_on!`

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts/1
  # GET /posts/1.json
  def show
    device = TappingDevice.new do |payload|
      puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
    end

    device.tap_on!(@post)
  end
end
```

And you can see these in log:

```
Method: name line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
Method: user_id line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
Method: to_param line: /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```

### `tap_assoc!`

```ruby
device = TappingDevice.new do |payload|
  puts "Assoc: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
end
device.tap_assoc!(order) 
```

```
Assoc: payments line: /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
Assoc: line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:44
Assoc: effective_line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:110
Assoc: amending_orders line: /MY_PROJECT/app/models/order.rb:385
Assoc: amends_order line: /MY_PROJECT/app/models/order.rb:432
```

### Device states & Managing Devices

Every `TappingDevice` instance can have 3 states:

- `Initial` - means the instance is initialized but hasn’t been used to tap on anything.
- `Enabled` - means the instance has started to tap on something (has called `tap_*` methods).
- `Disabled` - means the instance has been disabled. It will no longer receive any call info.

When debugging, we may create many device instances and tap objects in several places. Then it’ll be quite annoying to manage their states. So `TappingDevice` has several class methods that allows you to manage all `TappingDevice` instances:

- `TappingDevice.devices` - Lists all registered devices with `initial` or `enabled` state. Note that any instance that’s been stopped  will be removed from the list.
- `TappingDevice.stop_all!` - Stops all registered devices and remove them from the `devices` list.
- `TappingDevice.suspend_new!` - Suspends any device instance from changing their state from `initatial` to `enabled`. Which means any  `tap_*` calls after it will no longer work. 
- `TappingDevice.reset!` - Cancels `suspend_new` (if called) and stops/removes all created devices. Useful to reset environment between test cases.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/st0012/tapping_device. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TappingDevice project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tapping_device/blob/master/CODE_OF_CONDUCT.md).

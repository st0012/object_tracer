# TappingDevice

![](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)

**Please use 0.3.0+ versions, older versions have serious performance issues**

`tapping_device` is a gem built on top of Ruby’s `TracePoint` class that allows you to tap method calls of specified objects. The purpose for this gem is to make debugging Rails applications easier.  Here are some sample usages:

### Track method calls

```ruby
class PostsController < ApplicationController
  include TappingDevice::Trackable

  def show
    @post = Post.find(params[:id])
    tap_on!(@post) do |payload|
      puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
    end
  end
end
```

And you can see these in log:

```
Method: name line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
Method: user_id line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
Method: to_param line: /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```


### Track ActiveRecord records’ association calls

Or you can use `tap_assoc!`. This is very useful for tracking potential n+1 query calls, here’s a sample from my work

```ruby
tap_assoc!(order) do |payload|
  puts "Assoc: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
end
```

```
Assoc: payments line: /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
Assoc: line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:44
Assoc: effective_line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:110
Assoc: amending_orders line: /MY_PROJECT/app/models/order.rb:385
Assoc: amends_order line: /MY_PROJECT/app/models/order.rb:432
```


### Track calls that generates sql queries! (Beta)

`tap_sql!` method helps you track which method calls generate sql queries. This is particularly helpful when tracking calls created from a reused `ActiveRecord::Relation` object.

```ruby
class PostsController < ApplicationController
  def index
    # simulate current_user
    @current_user = User.last
    # reusable ActiveRecord::Relation
    @posts = Post.all

    tap_sql!(@posts) do |payload|
      puts("Method: #{payload[:method_name]} generated sql: #{payload[:sql]} from #{payload[:filepath]}:#{payload[:line_number]}")
    end
  end
end
```

```erb
<h1>Posts (<%= @posts.count %>)</h1>
......
  <% @posts.each do |post| %>
    ......
  <% end %>
......
<p>Posts created by you: <%= @posts.where(user: @current_user).count %></p>
```

And the output would be

```
Method: count generated sql: SELECT COUNT(*) FROM "posts" from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:3
Method: each generated sql: SELECT "posts".* FROM "posts" from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:16
Method: count generated sql: SELECT COUNT(*) FROM "posts" WHERE "posts"."user_id" = ? from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:31
```


However, depending on the size of your application, tapping any object could **harm the performance significantly**. **Don’t use this on production**

## Installation

Add this line to your application’s Gemfile:

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
In order to use `tapping_device`, you need to include `TappingDevice::Trackable` module in where you want to track your code.

### Methods
- `tap_init!(class)` -  tracks a class’ instance initialization
- `tap_on!(object)` - tracks any calls received by the object
- `tap_assoc!(activerecord_object)` - tracks association calls on a record, like `post.comments`
- `tap_sql!(activerecord_relation_or_model)` - tracks sql queries generated from the target

### Info of the call
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

```ruby
tap_on!(@post, exclude_by_paths: [/active_record/]) do |payload|
  puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
end
```

```
Method: _read_attribute line: /RUBY_PATH/gems/2.6.0/gems/activerecord-5.2.0/lib/active_record/attribute_methods/read.rb:40
Method: name line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
Method: _read_attribute line: /RUBY_PATH/gems/2.6.0/gems/activerecord-5.2.0/lib/active_record/attribute_methods/read.rb:40
Method: user_id line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
.......

# versus

Method: name line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
Method: user_id line: /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
Method: to_param line: /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```


### `#tap_init!`

```ruby
calls = []
tap_init!(Student) do |payload|
  calls << [payload[:method_name], payload[:arguments]]
end

Student.new("Stan", 18)
Student.new("Jane", 23)

puts(calls.to_s) #=> [[:initialize, [[:name, "Stan"], [:age, 18]]], [:initialize, [[:name, "Jane"], [:age, 23]]]]
```

### `tap_on!`

```ruby
class PostsController < ApplicationController
  include TappingDevice::Trackable

  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def show
    tap_on!(@post) do |payload|
      puts "Method: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
    end
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
tap_assoc!(order) do |payload|
  puts "Assoc: #{payload[:method_name]} line: #{payload[:filepath]}:#{payload[:line_number]}"
end
```

```
Assoc: payments line: /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
Assoc: line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:44
Assoc: effective_line_items line: /MY_PROJECT/app/models/line_item_container_helpers.rb:110
Assoc: amending_orders line: /MY_PROJECT/app/models/order.rb:385
Assoc: amends_order line: /MY_PROJECT/app/models/order.rb:432
```

### `tap_sql!` (beta)

```ruby
class PostsController < ApplicationController
  def index
    # simulate current_user
    @current_user = User.last
    # reusable ActiveRecord::Relation
    @posts = Post.all

    tap_sql!(@posts) do |payload|
      puts("Method: #{payload[:method_name]} generated sql: #{payload[:sql]} from #{payload[:filepath]}:#{payload[:line_number]}")
    end
  end
end
```

```erb
<h1>Posts (<%= @posts.count %>)</h1>
......
  <% @posts.each do |post| %>
    ......
  <% end %>
......
<p>Posts created by you: <%= @posts.where(user: @current_user).count %></p>
```

```
Method: count generated sql: SELECT COUNT(*) FROM "posts" from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:3
Method: each generated sql: SELECT "posts".* FROM "posts" from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:16
Method: count generated sql: SELECT COUNT(*) FROM "posts" WHERE "posts"."user_id" = ? from /PROJECT_PATH/rails-6-sample/app/views/posts/index.html.erb:31
```



### Advance Usages

Tapping methods introduced above like `tap_on!` are designed for simple use cases. They’re actually short for

```ruby
device = TappingDevice.new { # tapping action }
device.tap_on!(object)
```

And if you want to do some more configurations like stopping them manually or setting stop condition, you must have a `TappingDevie` instance. You can either get them like the above code, or save the return value of `tap_*!` method calls.

#### Stop tapping

Once you have a `TappingDevice` instance in hand, you will be able to stop the tapping by
1. Manually calling `device.stop!`
2. Setting stop condition with `device.stop_when`, like

```ruby
device.stop_when do |payload|
  device.calls.count >= 10 # stop after gathering 10 calls’ data
end
```

#### Device states & Managing Devices

Each `TappingDevice` instance can have 3 states:

- `Initial` - means the instance is initialized but hasn’t tapped on anything.
- `Enabled` - means the instance are tapping on something (has called `tap_*` methods).
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

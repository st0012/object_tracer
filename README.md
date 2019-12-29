# TappingDevice

![](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/maintainability)](https://codeclimate.com/github/st0012/tapping_device/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3e3732a6983785bccdbd/test_coverage)](https://codeclimate.com/github/st0012/tapping_device/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/st0012/tapping_device/badges/users.svg)](https://www.codetriage.com/st0012/tapping_device)

## Related Posts
- [Debug Rails issues effectively with tapping_device](https://dev.to/st0012/debug-rails-issues-effectively-with-tappingdevice-c7c)
- [Want to know more about your Rails app? Tap on your objects!](https://dev.to/st0012/want-to-know-more-about-your-rails-app-tap-on-your-objects-bd3)

## Table of Content
- [Introduction](#introduction)
	- [Track Method Calls](#track-method-calls)
	- [Track Association Calls](#track-association-calls)
	- [Track Calls that Generates SQL Queries](#track-calls-that-generates-sql-queries)
- [Installation](#installation)
- [Usages](#usage)
	- [Methods](#methods)
	- [Payload](#payload-of-the-call)
	- [Options](#options)
	- [Advance Usages](#advance-usages)

## Introduction

`tapping_device` is a gem built on top of Ruby’s `TracePoint` class that allows you to tap method calls of specified objects. The purpose for this gem is to make debugging Rails applications easier.  Here are some sample usages:

### Track Method Calls

```ruby
class PostsController < ApplicationController
  include TappingDevice::Trackable

  def show
    @post = Post.find(params[:id])
    tap_on!(@post).and_print(:method_name_and_location)
  end
end
```

And you can see these in log:

```
name FROM /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
user_id FROM /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
to_param FROM /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```


### Track Association Calls

Or you can use `tap_assoc!`. This is very useful for tracking potential n+1 query calls, here’s a sample from my work

```ruby
tap_assoc!(order).and_print(:method_name_and_location)
```

```
payments FROM /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
line_items FROM /MY_PROJECT/app/models/line_item_container_helpers.rb:44
effective_line_items FROM /MY_PROJECT/app/models/line_item_container_helpers.rb:110
amending_orders FROM /MY_PROJECT/app/models/order.rb:385
amends_order FROM /MY_PROJECT/app/models/order.rb:432
```


### Track Calls that Generates SQL Queries

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

### Payload of the call
All tapping methods (start with `tap_`) takes a block and yield a `Payload` object as block argument. It responds to

- `target` - the target for `tap_x` call
- `receiver` - the receiver object
- `method_name` - method’s name (symbol) 
	- e.g. `:name`
- `method_object` - the method object that’s being called. It might be `nil` in some edge cases.
- `arguments` - arguments of the method call
	- e.g. `{name: “Stan”, age: 25}`
- `return_value` - return value of the method call
- `filepath` - path to the file that performs the method call
- `line_number` 
- `defined_class` - in which class that defines the method being called
- `trace` - stack trace of the call. Default is an empty array unless `with_trace_to` option is set
- `tp` - trace point object of this call


#### Symbols for helpers
- `FROM` for method call’s location
- `<=` for arguments
- `=>` for return value
- `@` for defined class

#### Helpers
- `method_name_and_location` - `initialize FROM /PROJECT_PATH/tapping_device/spec/payload_spec.rb:7`
- `method_name_and_arguments` - `initialize <= {:name=>\"Stan\", :age=>25}`
- `method_name_and_return_value` - `ten => 10`
- `method_name_and_defined_class` - `initialize @ Student`
- `passed_at` - 
```
Passed as 'object' in method ':initialize'
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionview-6.0.0/lib/action_view/helpers/tags/label.rb:60
```

You can also set `passed_at(with_method_head: true)` to see the method’s head

```
Passed as 'object' in method ':initialize'
  > def initialize(template_object, object_name, method_name, object, tag_value)
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionview-6.0.0/lib/action_view/helpers/tags/label.rb:60
```

- `detail_call_info` 

```
initialize @ Student
  <= {:name=>"Stan", :age=>25}
  => 25
  FROM /Users/st0012/projects/tapping_device/spec/payload_spec.rb:7
```


### Options
#### with_trace_to
It takes an integer as the number of traces we want to put into `trace`. Default is `nil`, so `trace` would be empty. 

```ruby
stan = Student.new("Stan", 18)
tap_on!(stan, with_trace_to: 5)

stan.name

puts(device.calls.first.trace) #=>
/Users/st0012/projects/tapping_device/spec/tapping_device_spec.rb:287:in `block (4 levels) in <top (required)>'
/Users/st0012/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/rspec-core-3.8.2/lib/rspec/core/example.rb:257:in `instance_exec'
/Users/st0012/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/rspec-core-3.8.2/lib/rspec/core/example.rb:257:in `block in run'
/Users/st0012/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/rspec-core-3.8.2/lib/rspec/core/example.rb:503:in `block in with_around_and_singleton_context_hooks'
/Users/st0012/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/rspec-core-3.8.2/lib/rspec/core/example.rb:460:in `block in with_around_example_hooks'
/Users/st0012/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/rspec-core-3.8.2/lib/rspec/core/hooks.rb:464:in `block in run'
```

#### track_as_records
It makes the device to track objects as they are ActiveRecord instances. For example:

```ruby
tap_on!(@post, track_as_records: true)
post = Post.find(@post.id) # same record but a different object
post.title #=> this call will be recorded as well
```

#### exclude_by_paths
It takes an array of call path patterns that we want to skip. This could be very helpful when working on large project like Rails applications.

```ruby
tap_on!(@post, exclude_by_paths: [/active_record/]).and_print(:method_name_and_location)
```

```
_read_attribute FROM  /RUBY_PATH/gems/2.6.0/gems/activerecord-5.2.0/lib/active_record/attribute_methods/read.rb:40
name FROM  /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
_read_attribute FROM  /RUBY_PATH/gems/2.6.0/gems/activerecord-5.2.0/lib/active_record/attribute_methods/read.rb:40
user_id FROM  /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
.......

# versus

name FROM  /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
user_id FROM  /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
to_param FROM  /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```

#### filter_by_paths

Like `exclude_by_paths`, but work in an opposite way.

### `#tap_init!`

```ruby
calls = []
tap_init!(Student) do |payload|
  calls << [payload[:method_name], payload[:arguments]]
end

Student.new("Stan", 18)
Student.new("Jane", 23)

puts(calls.to_s) #=> [[:initialize, {:name=>"Stan", :age=>18}], [:initialize, {:name=>"Jane", :age=>23}]]
```

### `tap_on!`

```ruby
class PostsController < ApplicationController
  include TappingDevice::Trackable

  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def show
    tap_on!(@post).and_print(:method_name_and_location)
  end
end
```

And you can see these in log:

```
name FROM /PROJECT_PATH/sample/app/views/posts/show.html.erb:5
user_id FROM /PROJECT_PATH/sample/app/views/posts/show.html.erb:10
to_param FROM /RUBY_PATH/gems/2.6.0/gems/actionpack-5.2.0/lib/action_dispatch/routing/route_set.rb:236
```

Also check the `track_as_records` option if you want to track `ActiveRecord` records.

### `tap_passed!`

This is particularly useful when debugging libraries. It saves your time from jumping between files and check which path the object will go.

```ruby
class PostsController < ApplicationController
  include TappingDevice::Trackable
  # GET /posts/new
  def new
    @post = Post.new

    tap_passed!(@post) do |payload|
      puts(payload.passed_at(with_method_head: true))
    end
  end
end
```

```
Passed as 'record' in method ':polymorphic_mapping'
  > def polymorphic_mapping(record)
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionpack-6.0.0/lib/action_dispatch/routing/polymorphic_routes.rb:131
Passed as 'klass' in method ':get_method_for_class'
  > def get_method_for_class(klass)
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionpack-6.0.0/lib/action_dispatch/routing/polymorphic_routes.rb:269
Passed as 'record' in method ':handle_model'
  > def handle_model(record)
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionpack-6.0.0/lib/action_dispatch/routing/polymorphic_routes.rb:227
Passed as 'record_or_hash_or_array' in method ':polymorphic_method'
  > def self.polymorphic_method(recipient, record_or_hash_or_array, action, type, options)
  at /Users/st0012/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/actionpack-6.0.0/lib/action_dispatch/routing/polymorphic_routes.rb:139
```

### `tap_assoc!`

```ruby
tap_assoc!(order).and_print(:method_name_and_location)
```

```
payments FROM /RUBY_PATH/gems/2.6.0/gems/jsonapi-resources-0.9.10/lib/jsonapi/resource.rb:124
line_items FROM /MY_PROJECT/app/models/line_item_container_helpers.rb:44
effective_line_items FROM /MY_PROJECT/app/models/line_item_container_helpers.rb:110
amending_orders FROM /MY_PROJECT/app/models/order.rb:385
amends_order FROM /MY_PROJECT/app/models/order.rb:432
```

### `tap_sql!`

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

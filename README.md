# TappingDevice

![](https://github.com/st0012/tapping_device/workflows/Ruby/badge.svg)

`tapping_device` is a gem built on top of Ruby’s `TracePoint` class that allows you to tap method calls of specified objects. The purpose for this gem is to make debugging Rails applications easier. For example, you can use it to see who calls you `Post` records

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
In order to use `tapping_device`, you need to include `TappingDevice::Trackable` module in where you want to track your code.

### Methods
- `tap_init!(class)` -  tracks a class’ instance initialization
- `tap_on!(object)` - tracks any calls received by the object
- `tap_assoc!(activerecord_object)` - tracks association calls on a record, like `post.comments`
- `untap!(object)` - this stops tapping on the given object

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

  # GET /posts/1
  # GET /posts/1.json
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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/st0012/tapping_device. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TappingDevice project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tapping_device/blob/master/CODE_OF_CONDUCT.md).

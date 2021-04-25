test:
	bundle exec rspec
	WITH_ACTIVE_RECORD=true bundle exec rspec spec/active_record_spec.rb

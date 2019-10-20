require 'active_record'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = nil

ActiveRecord::Schema.define do
  create_table :posts, force: true  do |t|
    t.string :title
    t.string :content
  end
end

class Post < ActiveRecord::Base
end

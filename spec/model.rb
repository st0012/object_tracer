require 'active_record'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = nil

ActiveRecord::Schema.define do
  create_table :posts, force: true  do |t|
    t.string :title
    t.string :content
    t.references :user
  end
  create_table :users, force: true do |t|
    t.string :name
  end
  create_table :comments, force: true do |t|
    t.references :post
    t.references :user
    t.string :content
  end
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
end

class Student
  def initialize(name, age)
    @name = name
    @age = age
  end

  def self.foo; end

  def name
    @name
  end

  def age
    @age
  end

  def age=(age)
    @age = age
  end

  def id=(id)
    @id = id
  end

  def id
    @id
  end
end

class HighSchoolStudent < Student;end

class School
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end



$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

require "rubygems"
require "activerecord"

if ARGV.empty? or ARGV.first == '1'
  ActiveRecord::Schema.define do
  
    #START:catalog_table
    create_table :catalog_entries, :force => true do |t|
      t.string :name
      t.datetime :acquired_at
      t.integer :resource_id
      t.string :resource_type
    end
    #END:catalog_table
  
    #START:asset_tables
    create_table :articles, :force => true do |t|
      t.text :content
    end
  
    create_table :sounds, :force => true do |t|
      t.binary :content
    end
  
    create_table :images, :force => true do |t|
      t.binary :content
    end
    #END:asset_tables
  
  end
end

#START:catalog_model
class CatalogEntry < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true
end
#END:catalog_model

#START:asset_models
class Article < ActiveRecord::Base
  has_one :catalog_entry, :as => :resource
end

class Sound < ActiveRecord::Base
  has_one :catalog_entry, :as => :resource
end

class Image < ActiveRecord::Base
  has_one :catalog_entry, :as => :resource
end
#END:asset_models

case ARGV.shift
when "1"
  #START:try1
  a = Article.new(:content => "This is my new article")
  c = CatalogEntry.new(:name => 'Article One', :acquired_at => Time.now)
  c.resource = a
  c.save!
  #END:try1
  #START:op1
  article = Article.find(1)
  p article.catalog_entry.name  #=> "Article One"
  
  cat = CatalogEntry.find(1)
  resource = cat.resource 
  p resource                    #=> #<Article:0x640d80 @attributes={"id"=>"1", 
                                #     "content"=>"This is my new article"}>
  #END:op1

when "2"
  #START:try2
  c = CatalogEntry.new(:name => 'Article One', :acquired_at => Time.now)
  c.resource = Article.new(:content => "This is my new article")
  c.save!

  c = CatalogEntry.new(:name => 'Image One', :acquired_at => Time.now)
  c.resource = Image.new(:content => "some binary data")
  c.save!

  c = CatalogEntry.new(:name => 'Sound One', :acquired_at => Time.now)
  c.resource = Sound.new(:content => "more binary data")
  c.save!

  #END:try2
  #START:op2
  CatalogEntry.find(:all).each do |c|
    puts "#{c.name}:  #{c.resource.class}"
  end
  #END:op2
else
  a = Sound.new(:content => "ding!")
  c = CatalogEntry.new(:name => 'Sound One', :acquired_at => Time.now)
  c.resource = a

  c.save!

  c = CatalogEntry.find 1
  p c.resource

  a = Sound.find :first
  p a.catalog_entry
end

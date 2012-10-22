require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  #START:test_empty_attributes
  test "product attributes must not be empty" do
    product = Product.new
    assert product.invalid?
    assert product.errors[:title].any?
    assert product.errors[:description].any?
    assert product.errors[:price].any?
    assert product.errors[:image_url].any?
  end
  #END:test_empty_attributes

  #START:test_positive_price
  test "product price must be positive" do
    product = Product.new(:title       => "My Book Title",
                          :description => "yyy",
                          :image_url   => "zzz.jpg")
    product.price = -1
    assert product.invalid?
    assert_equal ["must be greater than or equal to 0.01"],
      product.errors[:price]

    product.price = 0
    assert product.invalid?
    assert_equal ["must be greater than or equal to 0.01"], 
      product.errors[:price]

    product.price = 1
    assert product.valid?
  end
  #END:test_positive_price

  #START:test_image_url
  def new_product(image_url)
    Product.new(:title       => "My Book Title",
                :description => "yyy",
                :price       => 1,
                :image_url   => image_url)
  end
  #END:test_image_url
  #START:test_image_url2

  test "image url" do
    ok = %w{ fred.gif fred.jpg fred.png FRED.JPG FRED.Jpg
             http://a.b.c/x/y/z/fred.gif }
    bad = %w{ fred.doc fred.gif/more fred.gif.more }
    
    ok.each do |name|
      assert new_product(name).valid?, "#{name} shouldn't be invalid"
    end

    bad.each do |name|
      assert new_product(name).invalid?, "#{name} shouldn't be valid"
    end
  end
  #END:test_image_url2

  #START:test_unique_title
  test "product is not valid without a unique title" do
    product = Product.new(:title       => products(:ruby).title,
                          :description => "yyy", 
                          :price       => 1, 
                          :image_url   => "fred.gif")

    assert product.invalid?
    assert_equal ["has already been taken"], product.errors[:title]
  end
  #END:test_unique_title

  #START:test_unique_title1
  test "product is not valid without a unique title - i18n" do
    product = Product.new(:title       => products(:ruby).title,
                          :description => "yyy", 
                          :price       => 1, 
                          :image_url   => "fred.gif")

    assert product.invalid?
    assert_equal [I18n.translate('activerecord.errors.messages.taken')],
                 product.errors[:title]
  end
  #END:test_unique_title1
  
end

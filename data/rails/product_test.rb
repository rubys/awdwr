require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    Product.import('public/testdata.xml')
  end

  test "Pragmatic Project Automation" do
    product = Product.find_by_base_id(2)
    assert_equal 'Pragmatic Project Automation', product.title
    assert_match /^<p>\s+<em>Pragmatic Project Automation/, product.description
    assert_equal '/images/auto.jpg', product.image_url
    assert_equal 24.95, product.price
  end

  test "Pragmatic Version Control" do
    product = Product.find_by_base_id(3)
    assert_equal 'Pragmatic Version Control', product.title
    assert_match /^<p>\s+This book is a recipe-based approach/, product.description
    assert_equal '/images/svn.jpg', product.image_url
    assert_equal 28.5, product.price
  end

  test "Pragmatic Unit Testing" do
    product = Product.find_by_base_id(4)
    assert_equal 'Pragmatic Unit Testing (C#)', product.title
    assert_match /<p>\s+Pragmatic programmers use feedback/, product.description
    assert_equal '/images/utc.jpg', product.image_url
    assert_equal 27.75, product.price
  end
end

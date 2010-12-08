require 'product_server'
require 'test/unit'
require 'rack/test'

class ProductServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    ProductServer.new
  end

  def test_product_list
    response = get('/products')
    assert response.ok?
    assert 3, response.body.scan('<h2>').count
    assert_match /<h2>Pragmatic Project Automation<\/h2>/, response.body
  end
end

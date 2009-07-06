require 'test/unit'

class Product_Load_Test < Test::Unit::TestCase
  def setup
    @db = `sqlite3 -line products.db 'select * from products'`
  end

  def test_automate
    assert_match /title = Pragmatic Project Automation/, @db
    assert_match /description = <p>\s+<em>Pragmatic Project Automation/, @db
    assert_match %r|image_url = /images/auto.jpg|, @db
    assert_match /price = 24.95/, @db
  end

  def test_version
    assert_match /title = Pragmatic Version Control/, @db
    assert_match /description = <p>\s+This book is a recipe-based approach/, @db
    assert_match %r|image_url = /images/svn.jpg|, @db
    assert_match /price = 28.5/, @db
  end

  def test_unit
    assert_match /title = Pragmatic Unit Testing/, @db
    assert_match /description = <p>\s+Pragmatic programmers use feedback/, @db
    assert_match %r|image_url = /images/utc.jpg|, @db
    assert_match /price = 27.75/, @db
  end
end

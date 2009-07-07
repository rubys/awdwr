require 'test_gorp'

class InsideOutTest < Book::TestCase
  input 'insideout'
  output 'checkinout'

  section 1.1, 'XML to Raw SQLite3' do
    assert_select '.stderr', 'SQL error: no such table: products'
    assert_select '.stdout', '3 tests, 3 assertions, 3 failures, 0 errors'
    assert_select '.stdout', '3 tests, 12 assertions, 0 failures, 0 errors'
    assert_select '.stderr', /table products already exists/
    assert_select '.stdout', /Initialized empty Git repository/
  end

  section 1.2, 'Update Using Raw SQLite3' do
    assert_select '.stderr', /no such column: base_id/
    assert_select '.stdout', '3 tests, 12 assertions, 0 failures, 0 errors'
  end

  section 1.3, 'Update Using Raw SQLite3' do
    assert_select '.stdout', '3 tests, 12 assertions, 0 failures, 0 errors'
  end

  section 2.1, 'Rack' do
    assert_select '.stdout', '1 tests, 3 assertions, 0 failures, 0 errors'
    assert_select 'h1', 'Pragmatic Bookshelf'
    assert_select 'h2', 'Pragmatic Unit Testing (C#)'
    assert_select 'p', '27.75'
    assert_select '.stdout', '&lt;products type="array"&gt;'
    assert_select '.stdout', '3 tests, 12 assertions, 0 failures, 0 errors'
  end

  section 3.1, 'Capistrano' do
    assert_select '.stdout', '[done] capified!'
    assert_select '.stdout', 'You appear to have all necessary dependencies installed'
    assert_select '.stderr', ' ** transaction: commit'
    assert_select 'h1', 'Pragmatic Bookshelf'
    assert_select 'h2', 'Pragmatic Unit Testing (C#)'
    assert_select 'p', '27.75'
    assert_select '.stdout', '&lt;products type="array"&gt;'
  end

  section 4.1, 'whenever' do
    assert_select '.stdout', '3 tests, 12 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '[done] wheneverized!'
    assert_select '.stdout', /15 4 \* \* \* cd .*; ruby load_products.rb/
    assert_select '.stderr', /crontab file updated/
  end
end

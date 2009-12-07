require 'rubygems'
require 'gorp/test'

class DepotTest < Book::TestCase

  input 'makedepot'
  output 'checkdepot'

  section 4, 'Instant Gratification' do
    stdout = collect_stdout

    assert_equal '<ul>', stdout.shift
    assert_equal '  <li>Addition: 3 </li>', stdout.shift
    assert_equal '  <li>Concatenation: cowboy </li>', stdout.shift
    assert_match /^  <li>Time in one hour:  (\w+ \w+ \d\d \d\d:\d\d:\d\d [+-]\d+ \d+|\d+-\d\d-\d\d \d\d:\d\d:\d\d [+-]\d+) <\/li>/, stdout.shift
    assert_equal '</ul>', stdout.shift

    3.times do
      assert_equal ' ', stdout.shift
      assert_equal 'Ho!<br />', stdout.shift
    end
    stdout.shift if stdout.first == ' '
    assert_equal 'Merry Christmas!', stdout.shift

    3.times { assert_equal 'Ho!<br />', stdout.shift }
    stdout.shift if stdout.first == ' '
    assert_equal 'Merry Christmas!', stdout.shift

    3.times { assert_equal 'Ho!<br />', stdout.shift }
    assert_equal 'Merry Christmas!', stdout.shift

    assert stdout.empty?
  end

  section 6.2, 'Creating the Products Model and Maintenance Application' do
    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=Pragmatic Version Control]'
    assert_select "a[href=http://127.0.0.1:#{$PORT}/products/1]", 'redirected'
    assert_select '.stdout', /"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL/
    assert_select '.stdout', /^7 tests, 10 assertions, 0 failures, 0 errors/
  end

  section 6.3, "Iteration A2: Add a Missing Column" do
    assert_select '.stdout', 
      /add_column\(:products, :price, :decimal, \{.*:precision=&gt;8.*\}\)/
    assert_select '.stdout', /"price" decimal\(8,2\) DEFAULT 0/
    assert_select 'th', 'Price'
    assert_select 'input#product_price[value=0.0]'
  end

  section 6.4, "Iteration A3: Validate!" do
    assert_select 'h2', '3 errors prohibited this product from being saved'
    assert_select 'li', "Image url can't be blank"
    assert_select 'li', 'Price is not a number'
    assert_select '.fieldWithErrors input[id=product_price]'
  end

  section 6.5, "Iteration A4: Prettier Listings" do
    assert_select '.list-line-even'
  end

  section 7.1, "Iteration B1: Create the Catalog Listing" do
    assert_select 'p', 'Find me in app/views/store/index.html.erb'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '28.5'
  end

  section 7.2, "Iteration B2: Add a Page Layout" do
    assert_select '#banner', /Pragmatic Bookshelf/
  end

  section 7.3, "Iteration B3: Use a Helper to Format the Price" do
    assert_select 'span.price', '$28.50'
  end

  section 7.4, "Iteration B4: Linking to the Cart" do
    assert_select 'input[type=submit][value=Add to Cart]'
  end

  section 8.1, "Sessions" do
    assert_select '.stdout', /CREATE TABLE "sessions"/
  end

  section 8.2, "Iteration C1: Creating a Cart" do
    assert_select 'p', /Missing template store\/add_to_cart/
    assert_select 'h2', 'Your Pragmatic Cart'
    assert_select 'li', 'Pragmatic Project Automation'
  end

  section 8.3, "Iteration C2: A Smarter Cart" do
    assert_select 'h1', /NoMethodError/
    assert_select 'h1', /in StoreController#add_to_cart/
    assert_select 'li', /2 (.|&#?\w+;) Pragmatic Project Automation/u
    assert_select 'pre', "Couldn't find Product with ID=wibble"
  end

  section 8.4, "Iteration C3: Handling Errors" do
    assert_select "a[href=http://127.0.0.1:#{$PORT}/store]", 'redirected'
    assert_select '.hilight', 'Attempt to access invalid product wibble'
    assert_select '#notice', 'Invalid product'
  end

  section 8.5, "Iteration C4: Finishing the Cart" do
    assert_select '#notice', 'Your cart is currently empty'
    assert_select '.total-cell', '$88.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 9.1, "Iteration D1: Moving the Cart" do
    assert_select '.cart-title', 'Your Cart'
    assert_select '.total-cell', '$88.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 9.5, "Iteration D5: Degrading If Javascript Is Disabled" do
    assert_select '#cart[style=display: none]'
    assert_select '.total-cell', '$28.50'
  end

  section 10.1, "Iteration E1: Capturing an Order" do
    assert_select 'input[type=submit][value=Place Order]'
    assert_select 'p', /No action responded to save_order.|The action 'save_order' could not be found/
    assert_select 'h2', '5 errors prohibited this order from being saved'
    assert_select '#notice', 'Thank you for your order'
  end

  section 11.1, "Iteration F1: Adding Users" do
    assert_select 'legend', 'Enter User Details'
    if ActiveSupport::VERSION::STRING =~ /^2\.[23]/
      assert_select 'p[style=color: green]', 'User dave was successfully created.'
    else
      assert_select 'p.notice', 'User dave was successfully created.'
    end
  end

  section 11.2, "Iteration F2: Logging in" do
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
  end

  section 11.3, "Iteration F3: Limiting Access" do
    assert_select "a[href=http://127.0.0.1:#{$PORT}/admin/login]", 'redirected'
    assert_select 'h1', 'Listing products'
  end

  section 11.4, "Iteration F4: A Sidebar, More Administration" do
    assert_select 'h1', /NoMethodError in/
    assert_select 'h1', /Admin#index/
    assert_select '#main h1', 'Listing users'
    assert_select '.stdout', /=&gt; #&lt;Product id: nil/
  end

  section 12.1, "Generating the XML Feed" do
    # assert_select '.stdout', /No route matches &amp;quot;\/info\/who_bought\//
    assert_select '.stdout', /&lt;email&gt;customer@example.com&lt;\/email&gt;/
    assert_select '.stdout', /title = Pragmatic Project Automation/
    assert_select '.stdout', /total_price = 28.5/
    assert_select '.stdout', /&lt;id type="integer"&gt;3&lt;\/id&gt;/
    assert_select '.stdout', /&lt;td&gt;Pragmatic Version Control&lt;\/td&gt;/
    assert_select '.stdout', /, ?"title": ?"Pragmatic Version Control"/
  end

  section 13, "Internationalization" do
    assert_select '#notice', 'es translation not available'
    assert_select 'option[value=es]'
    assert_select '.price', /28,50(.|&#?\w+;)\$US/u
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_select 'input[type=submit][value$=dir al Carrito]'
    assert_select 'h2', '5 errores han impedido que este pedido se guarde'
    assert_select '#notice', 'Gracias por su pedido'
  end

  section 14.2, "Unit Testing of Models" do
    assert_select '.stdout', /SQLite3::SQLException: no such table: \w+/
    assert_select '.stdout', /1 tests, 1 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /4 tests, 4 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /9 tests, 27 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /2 tests, 5 assertions, 0 failures, 0 errors/
  end

  section 14.3, "Functional Testing of Controllers" do
    assert_select '.stdout', /5 tests, 8 assertions, 0 failures, 0 errors/
  end

  section 14.4, "Integration Testing of Applications" do
    assert_select '.stdout', /1 tests, 17 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /2 tests, 49 assertions, 0 failures, 0 errors/
  end

  section 14.5, "Performance Testing" do
    assert_select '.stderr', 'Using the standard Ruby profiler.'
    assert_select '.stderr', /Math.sin/
  end

  section 15, "Rails In Depth" do
    assert_select '.stdout', 'Current version: 20100301000007'
  end

  section 17, "Migration" do
    assert_select '.stderr', /near "auto_increment": syntax error/
    assert_select '.stderr', 'uninitialized constant TestDiscounts::Sku'

    stdout = css_select('.stdout').map {|tag| tag.children.join}
    stdout = stdout.select {|line| line =~ /^== / and line !~ /ing ===/}
    stdout.shift if stdout.first =~ /AddStatusToUser: migrated/
    assert_match /CreateDiscounts: migrated/, stdout.shift
    stdout.shift if stdout.first =~ /AddStatusToUser: migrated/
    assert_match /AddEmailToOrders: migrated/, stdout.shift
    assert_match /AddPlacedAtToOrders: migrated/, stdout.shift
    assert_match /AddColumnsToOrders: migrated/, stdout.shift
    assert_match /RenameEmailColumn: migrated/, stdout.shift
    assert_match /ChangeOrderTypeToString: migrated/, stdout.shift
    assert_match /CreateOrderHistories: migrated/, stdout.shift
    assert_match /RenameOrderHistories: migrated/, stdout.shift
    assert_match /CreateOrderHistories2: migrated/, stdout.shift
    assert_match /AddCustomerNameIndexToOrders: migrated/, stdout.shift
    assert_match /CreateAuthorBook: migrated/, stdout.shift
    assert_match /CreateTableTickets: migrated/, stdout.shift
    assert_match /TestDiscounts: reverted/, stdout.shift
    assert_match /LoadUserData: reverted/, stdout.shift
    assert_match /LoadUserData: migrated/, stdout.shift
    assert_match /ChangePriceToInteger: migrated/, stdout.shift
    assert_match /TotalPriceToUnit: migrated/, stdout.shift
    assert_match /AddForeignKey: migrated/, stdout.shift
    assert stdout.empty?
  end

  section 18, 'Active Record: The Basics' do
    prelude = /Loading development environment|Switch to inspect mode/
    stdout = collect_stdout
    stdout.shift while stdout.first =~ prelude
    assert_equal ">> Order.column_names", stdout.shift
    assert_equal "=> [\"id\", \"name\", \"address\", \"email\", \"pay_type\", \"created_at\", \"updated_at\", \"customer_email\", \"placed_at\", \"attn\", \"order_type\", \"ship_class\", \"amount\", \"state\"]", stdout.shift
    assert_equal ">> ", stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_equal ">> Order.columns_hash[\"pay_type\"]", stdout.shift
    assert_match /ActiveRecord::ConnectionAdapters::SQLiteColumn/, stdout.shift
    assert_equal ">> ", stdout.shift
    assert_equal "            id = 1", stdout.shift
    assert_equal "          name = Dave Thomas", stdout.shift
    assert_equal "       address = 123 Main St", stdout.shift
    assert_equal "         email = customer@example.com", stdout.shift
    assert_equal "      pay_type = check", stdout.shift
    assert_match /^    created_at = \d+-\d+-\d+ \d+:\d+:\d+(\.\d+)?$/, stdout.shift
    assert_match /^    updated_at = \d+-\d+-\d+ \d+:\d+:\d+(\.\d+)?$/, stdout.shift
    assert_equal "customer_email = ", stdout.shift
    assert_match /^     placed_at = \d+-\d+-\d+ \d+:\d+:\d+(\.\d+)?$/, stdout.shift
    assert_equal "          attn = ", stdout.shift
    assert_equal "    order_type = ", stdout.shift
    assert_equal "    ship_class = priority", stdout.shift
    assert_equal "        amount = ", stdout.shift
    assert_equal "         state = ", stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_equal ">> Product.find(:first).price_before_type_cast", stdout.shift
    assert_equal "=> \"29.95\"", stdout.shift
    assert_equal ">> ", stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_equal ">> Product.find(:first).updated_at_before_type_cast", stdout.shift
    assert_match /^=> "\d+-\d+-\d+ \d+:\d+:\d+(\.\d+)?"$/, stdout.shift
    assert_equal ">> ", stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_match /^=> \[.*\]/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Order id: nil, name: nil/, stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> \"dave@example.com\"", stdout.shift
    assert_equal "=> \"123 Main St\"", stdout.shift
    assert_equal "=> \"check\"", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> #<Order id: 4, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> #<Order id: nil, name: \"Dave Thomas\"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> #<Order id: nil, name: nil/, stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "The ID of this order is 6", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Order id: 7, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> \[#<Order id: 8, name: "Dave Thomas"/, stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal '=> ["PP"]', stdout.shift
    assert_equal "=> {}", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Proc:.*>$/, stdout.shift
    assert_match /^=> #<Proc:.*>$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> #<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> #<Order id: 8, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> \[#<LineItem id: 1, product_id: 3.*\]$/, stdout.shift
    assert_match /^=> \[#<Order name: "Dave Thomas",.*\]$/, stdout.shift
    assert_equal "=> #<Order name: \"Dave Thomas\", pay_type: \"check\">", stdout.shift
    assert_equal "{\"name\"=>\"Dave Thomas\", \"pay_type\"=>\"check\"}", stdout.shift
    assert_match /^=> (nil|\{"name")/, stdout.shift
    assert_equal "[\"name\", \"pay_type\"]", stdout.shift
    assert_match /^=> (nil|\["name")/, stdout.shift
    assert_equal "false", stdout.shift
    assert_match /^=> (nil|false)/, stdout.shift
    assert_match /^#<ActiveRecord::Relation:|\[.*#<Order id: 9, name: "Andy Hunt".*>\]/, stdout.shift
    assert_match /^=> (nil|#<ActiveRecord::Relation|\[#<Order)/, stdout.shift
    assert_match /^#<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> (nil|\#<Order)/, stdout.shift
    assert_equal "1", stdout.shift
    assert_match /^=> (nil|1)/, stdout.shift
    assert_match /^#<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> (nil|\#<Order)/, stdout.shift
    assert_match /^\[#<Order id: 9, name: "Andy Hunt"/, stdout.shift
    assert_match /^=> (nil|\[#<Order)/, stdout.shift
    assert_match /^\[#<Order id: 9, name: "Andy Hunt"/, stdout.shift
    assert_match /^=> (nil|\[#<Order)/, stdout.shift
    assert_equal "=> 2", stdout.shift
    assert_equal "=> 3", stdout.shift
    assert_match /^=> #<Product id: 5, title: "Programming Ruby"/, stdout.shift
    assert_match /^=> #<LineItem id: 3, product_id: 5/, stdout.shift
    assert_match /^=> \[#<LineItem id: 5, product_id: 5/, stdout.shift
    assert_match /^=> #<LineItem id: 5, product_id: 5/, stdout.shift
    assert_equal "Programming Ruby: 2x49.95 => 99", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "=> 7", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "Dave has 1 line items in 7 orders (9 orders in all)", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> \[#<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> \[#<Order id: 4, name: "Dave Thomas"/, stdout.shift
    assert_match /^=> \[#<LineItem id: 3, product_id: 5/, stdout.shift
    assert_equal "1", stdout.shift
    assert_match /^=> (nil|1)/, stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_match /^=> (nil|9)/, stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_match /^=> (nil|9)/, stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> [\"PP\"]", stdout.shift
    assert_equal "-- create_table(:purchases, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> Object", stdout.shift
    assert_equal "=> #<Purchase id: nil, name: nil, last_five: nil>", stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> [\"shoes\", \"shirt\", \"socks\", \"ski mask\", \"shorts\"]", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> #<Purchase id: 1, name: \"Dave Thomas\", last_five: [\"shoes\", \"shirt\", \"socks\", \"ski mask\", \"shorts\"]>", stdout.shift
    assert_equal "[\"shoes\", \"shirt\", \"socks\", \"ski mask\", \"shorts\"]", stdout.shift
    assert_match /^=> (nil|\[.*\])/, stdout.shift
    assert_equal "\"ski mask\"", stdout.shift
    assert_match /^=> (nil|"ski mask")/, stdout.shift
    stdout.shift while stdout.first =~ prelude
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> [\"PP\"]", stdout.shift
    assert_equal "-- create_table(:customers, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<ActiveRecord::Reflection::AggregateReflection/, stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> #<Purchase id: 2, name: nil, last_five: \"3,4,5\">", stdout.shift
    assert_equal "=> #<Purchase id: 2, name: nil, last_five: \"3,4,5\">", stdout.shift
    assert_equal "4", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<ActiveRecord::Reflection::AggregateReflection/, stdout.shift
    assert_equal "=> 0", stdout.shift
    assert_match /^=> .*Eisenhower/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_equal "Dwight", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Dwight D Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> .*Truman/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert stdout.empty?
  end

  section 19, 'Active Record: Relationships Between Tables' do
    stdout = collect_stdout
    stdout.reject! {|line| line =~ /' -> `vendor\/plugins\//}
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:products, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:line_items, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (nil|#<Proc:.*>|\[#<.*>\]|Product\(id:.*)$/, stdout.shift
    assert_match /^=> (nil|#<Proc:.*>|\[#<.*>\])$/, stdout.shift
    assert_equal "=> 0", stdout.shift
    assert_match /^=> #<Product id: 1, title: "Programming Ruby"/, stdout.shift
    assert_equal "=> #<LineItem id: nil, product_id: nil, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "=> 2", stdout.shift
    assert_match /^=> #<Product id: 1, title: "Programming Ruby"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> #<LineItem id: nil, product_id: nil, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_match /^=> #<Product id: 1, title: "Programming Ruby"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "Simple Belongs to", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<LineItem id: 2, product_id: 1, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "Current product is 1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Programming Ruby", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Product id: nil, title: "Rails for Java Developers"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "New product is 2", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Rails for Java Developers", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "Create belongs to", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<LineItem id: 2, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "Current product is 2", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Rails for Java Developers", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Product id: 3, title: "Rails Recipes"/, stdout.shift
    assert_equal "New product is 3", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Rails Recipes", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "", stdout.shift
    assert_equal "product belongs to", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<LineItem id: 2, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "Current product is 2", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Rails for Java Developers", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<LineItem id: nil, product_id: nil, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_match /^=> #<Product id: 4, title: "Advanced Rails"/, stdout.shift
    assert_equal "New product is 4", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Advanced Rails", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^#<Product id: 4, title: "Advanced Rails"/, stdout.shift
    assert_match /^=> (nil|#<Product id: 4)/, stdout.shift
    assert_equal "=============", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Product id: 4, title: "Advanced Rails"/, stdout.shift
    assert_equal "1", stdout.shift
    assert_match /^=> (nil|1)/, stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "-- create_table(:people, {:force=>true})", stdout.shift
    stdout.shift if stdout.first =~ /\s+-> \d\.\d+s$/
    stdout.shift if stdout.first =~ /=> nil/
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)/, stdout.shift
    stdout.shift if stdout.first =~ /=> nil/
    assert_match /^=> #<Customer id: 1, type: "Customer"/, stdout.shift
    assert_match /^=> #<Manager id: 2, type: "Manager"/, stdout.shift
    assert_match /^=> #<Customer id: 3, type: "Customer"/, stdout.shift
    assert_match /^=> #<Employee id: nil, type: "Employee"/, stdout.shift
    assert_match /^=> #<Manager id: 2, type: "Manager"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> #<Manager id: 2, type: \"Manager\", name: \"Wilma Flint\", email: \"wilma@here.com\", balance: nil, reports_to: nil, dept: 23>", stdout.shift
    assert_equal "Manager", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "wilma@here.com", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "23", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Customer id: 3, type: "Customer"/, stdout.shift
    assert_equal "Customer", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "b@public.net", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "12.45", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Employee id: 4, type: \"Employee\", name: \"Barney Rub\", email: \"barney@here.com\", balance: nil, reports_to: 2, dept: 23>", stdout.shift
    assert_equal "#<Manager id: 2, type: \"Manager\", name: \"Wilma Flint\", email: \"wilma@here.com\", balance: nil, reports_to: nil, dept: 23>", stdout.shift
    assert_match /^=> (nil|#<Manager)/, stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:catalog_entries, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:articles, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:sounds, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:images, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    4.times { assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift }
    assert_equal "\"Article One\"", stdout.shift
    assert_equal "#<Article id: 1, content: \"This is my new article\">", stdout.shift
    assert_match /^=> (nil|#<Article)/, stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "content = This is my new article", stdout.shift
    assert_equal "           id = 1", stdout.shift
    assert_equal "         name = Article One", stdout.shift
    assert_match /^  acquired_at = \d+-\d+-\d+ \d+:\d+:\d+/, stdout.shift
    assert_equal "  resource_id = 1", stdout.shift
    assert_equal "resource_type = Article", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> nil", stdout.shift
    4.times { assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift }
    assert_equal "Article One:  Article", stdout.shift
    assert_equal "Image One:  Image", stdout.shift
    assert_equal "Sound One:  Sound", stdout.shift
    assert_match /^=> \[#<CatalogEntry id: 2, name: "Article One"/, stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "content = This is my new article", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "     id = 2", stdout.shift
    assert_equal "content = This is my new article", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "content = some binary data", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "content = more binary data", stdout.shift
    assert_equal "           id = 2", stdout.shift
    assert_equal "         name = Article One", stdout.shift
    assert_match /^  acquired_at = \d+-\d+-\d+ \d+:\d+:\d+/, stdout.shift
    assert_equal "  resource_id = 2", stdout.shift
    assert_equal "resource_type = Article", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "           id = 3", stdout.shift
    assert_equal "         name = Image One", stdout.shift
    assert_match /^  acquired_at = \d+-\d+-\d+ \d+:\d+:\d+/, stdout.shift
    assert_equal "  resource_id = 1", stdout.shift
    assert_equal "resource_type = Image", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "           id = 4", stdout.shift
    assert_equal "         name = Sound One", stdout.shift
    assert_match /^  acquired_at = \d+-\d+-\d+ \d+:\d+:\d+/, stdout.shift
    assert_equal "  resource_id = 1", stdout.shift
    assert_equal "resource_type = Sound", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:employees, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (Employee\(.*\)|nil|#<Proc:.*>|\[#<.*>\])$/, stdout.shift
    assert_equal "=> 0", stdout.shift
    assert_equal "=> #<Employee id: 1, name: \"Adam\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: 2, name: \"Beth\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: nil, name: \"Clem\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: 1, name: \"Adam\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: 2, name: \"Beth\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> #<Employee id: nil, name: \"Dawn\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: 1, name: \"Adam\", manager_id: nil, mentor_id: nil>", stdout.shift
    assert_equal "=> #<Employee id: 3, name: \"Clem\", manager_id: 1, mentor_id: 2>", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "[\"Clem\", \"Dawn\"]", stdout.shift
    assert_match /^=> (nil|\["Clem", "Dawn"\])/, stdout.shift
    assert_equal "[]", stdout.shift
    assert_match /^=> (nil|\[\])/, stdout.shift
    assert_equal "\"Clem\"", stdout.shift
    assert_match /^=> (nil|"Clem")/, stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_match /^=> (Parent\(.*\)|nil|#<Proc:.*>|\[#<.*>\])$/, stdout.shift
    assert_match /^=> (Child\(.*\)|nil|\[.*?\])/, stdout.shift
    assert_equal "=> #<Parent id: 1>", stdout.shift
    assert_equal "=> [\"One\", \"Two\", \"Three\", \"Four\"]", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "One, Two, Three, Four", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "true", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Child id: 2, parent_id: 1, name: \"Two\", position: 2>", stdout.shift
    assert_equal "Three", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "One", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "Two, One, Three, Four", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "Three, Two, One, Four", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Child id: 1, parent_id: 1, name: \"One\", position: nil>", stdout.shift
    assert_equal "Three, Two, Four", stdout.shift
    assert_equal "=> nil", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:categories, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Category id: 1, name: \"Books\", parent_id: nil>", stdout.shift
    assert_equal "=> #<Category id: 2, name: \"Fiction\", parent_id: 1>", stdout.shift
    assert_equal "=> #<Category id: 3, name: \"Non Fiction\", parent_id: 1>", stdout.shift
    assert_equal "=> #<Category id: 4, name: \"Computers\", parent_id: 3>", stdout.shift
    assert_equal "=> #<Category id: 5, name: \"Science\", parent_id: 3>", stdout.shift
    assert_equal "=> #<Category id: 6, name: \"Art History\", parent_id: 3>", stdout.shift
    assert_equal "=> #<Category id: 7, name: \"Mystery\", parent_id: 2>", stdout.shift
    assert_equal "=> #<Category id: 8, name: \"Romance\", parent_id: 2>", stdout.shift
    assert_equal "=> #<Category id: 9, name: \"Science Fiction\", parent_id: 2>", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Fiction, Non Fiction", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Category id: 2, name: \"Fiction\", parent_id: 1>", stdout.shift
    assert_equal "3", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Mystery, Romance, Science Fiction", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Category id: 3, name: \"Non Fiction\", parent_id: 1>", stdout.shift
    assert_equal "Art History, Computers, Science", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Books", stdout.shift
    assert_equal "=> nil", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:invoices, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:orders, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift
    assert_match /^=> #<Order id: 1, name: "Dave"/, stdout.shift
    assert_match /^=> #<Order id: 1, name: "Dave"/, stdout.shift
    assert_equal "nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Invoice id: nil, order_id: nil>", stdout.shift
    assert_equal "=> #<Invoice id: 1, order_id: 1>", stdout.shift
    assert_equal "#<Invoice id: 1, order_id: 1>", stdout.shift
    assert_match /^=> (nil|#<Invoice)/, stdout.shift
    assert_equal "=> #<Order id: nil, name: nil, email: nil, address: nil, pay_type: nil, shipped_at: nil>", stdout.shift
    assert_equal "nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Order id: nil, name: nil, email: nil, address: nil, pay_type: nil, shipped_at: nil>", stdout.shift
    assert_equal "nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "2", stdout.shift
    assert_match /^=> (nil|2)/, stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:products, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:line_items, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (Product\(.*\)|nil|#<Proc:.*>|\[#<.*>\])$/, stdout.shift
    assert_match /^=> (nil|#<Proc:.*>|\[#<.*>\])$/, stdout.shift
    assert_equal "=> #<Product id: 1, title: \"Programming Ruby\", description: \" ... \", line_items_count: 0>", stdout.shift
    assert_equal "=> #<LineItem id: nil, product_id: nil, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "=> #<Product id: 1, title: \"Programming Ruby\", description: \" ... \", line_items_count: 0>", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "In memory size = 0", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Refreshed size = 1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> #<Product id: 2, title: \"Programming Ruby\", description: \" ... \", line_items_count: 0>", stdout.shift
    assert_equal "=> #<LineItem id: 2, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>", stdout.shift
    assert_equal "In memory size = 0", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Refreshed size = 1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert stdout.empty?
  end

  section 20, 'Active Record: Object Life Cycle' do
    stdout = collect_stdout
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_match /^=> (true|false)/, stdout.shift
    assert_equal '=> []', stdout.shift
    assert_equal '=> []', stdout.shift
    assert_equal "-- create_table(:orders, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:users, {:force=>:true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> Encrypter", stdout.shift
    assert_match /^=> #<Proc:0x\w+@.*\/encrypt.rb:\d+.*>$/, stdout.shift
    assert_equal "=> #<Order id: nil, user_id: nil, name: nil, address: nil, email: nil>", stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> \"123 The Street\"", stdout.shift
    assert_equal "=> \"dave@example.com\"", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "Dave Thomas", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Order id: 1, user_id: nil, name: \"Dave Thomas\", address: \"123 The Street\", email: \"dave@example.com\">", stdout.shift
    assert_equal "Dave Thomas", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "user_id = ", stdout.shift
    assert_equal "   name = Dbwf Tipnbt", stdout.shift
    assert_equal "address = 123 The Street", stdout.shift
    assert_equal "  email = ebwf@fybnqmf.dpn", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> false", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> (true|\[\])/, stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "-- create_table(:payments, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<OrderObserver:.*>$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<AuditObserver:.*>$/, stdout.shift
    assert_select '.stderr', "Order 2 created"
    assert_select '.stderr', "[Audit] Order 2 created"
    assert_equal "=> #<Order id: 2, user_id: nil, name: nil, address: nil, email: nil>", stdout.shift
    assert_select '.stderr', "[Audit] Payment 1 created"
    assert_equal "=> #<Payment id: 1>", stdout.shift
    assert_equal "?> >> ", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> [\"PP\"]", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_match /^=> #<LineItem id: 3, product_id: 27/, stdout.shift
    assert_match /^=> #<LineItem id: 4, product_id: nil/, stdout.shift
    assert_match /^=> #<LineItem id: 5, product_id: nil/, stdout.shift
    assert_match /^=> #<LineItem id: 3, product_id: 27/, stdout.shift
    assert_equal "1", stdout.shift
    assert_match /^=> (nil|1)/, stdout.shift
    assert_match /^#<BigDecimal:.*>/, stdout.shift
    assert_match /^=> (nil|#<BigDecimal)/, stdout.shift
    assert_equal "=> [#<LineItem quantity: 1>, #<LineItem quantity: 2>, #<LineItem quantity: 1>]", stdout.shift
    assert_equal "{\"quantity\"=>1, unit_price\"=>\"29.95\"}", sort_hash(stdout.shift)
    assert_match /^=> (nil|\{"quantity"=>)/, stdout.shift
    assert_equal "                                      quantity*unit_price as total_price \" +", stdout.shift
    assert_equal "=> [#<LineItem quantity: 1>, #<LineItem quantity: 2>, #<LineItem quantity: 1>]", stdout.shift
    assert_equal "{\"quantity\"=>1, \"total_price\"=>\"29.95\"}", sort_hash(stdout.shift)
    assert_match /^=> (nil|\{"quantity"=>)/, stdout.shift
    assert_equal "\"29.95\"", stdout.shift
    assert_match /^=> (nil|"29.95")/, stdout.shift
    assert_match /^=> 0.07/, stdout.shift
    assert_equal "\"\"", stdout.shift
    assert_match /^=> (nil|"")/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "2.54", stdout.shift
    assert_match /^=> (nil|2.54)/, stdout.shift
    assert_equal "=> 500", stdout.shift
    assert_equal "true", stdout.shift
    assert_match /^=> (nil|true)/, stdout.shift
    assert_equal "?> >> ", stdout.shift
    assert_equal "                 id = 3", stdout.shift
    assert_equal "quantity*unit_price = 29.95", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "                 id = 4", stdout.shift
    assert_equal "quantity*unit_price = 59.9", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "                 id = 5", stdout.shift
    assert_equal "quantity*unit_price = 44.95", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:accounts, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Account id: 1, number: \"12345\", .*>$/, stdout.shift
    assert_match /^=> #<Account id: 2, number: \"54321\", .*>$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal " number = 12345", stdout.shift
    assert_equal "balance = 90", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "     id = 2", stdout.shift
    assert_equal " number = 54321", stdout.shift
    assert_equal "balance = 210", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:accounts, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Account id: 1, number: \"12345\", .*>$/, stdout.shift
    assert_match /^=> #<Account id: 2, number: \"54321\", .*>$/, stdout.shift
    assert_match /^\sfrom .*\/transactions.rb:\d+$/, stdout.shift
    stdout.shift while stdout.first =~ /^\tfrom /
    assert_equal "     id = 1", stdout.shift
    assert_equal " number = 12345", stdout.shift
    assert_equal "balance = 100", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "     id = 2", stdout.shift
    assert_equal " number = 54321", stdout.shift
    assert_equal "balance = 200", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:accounts, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Account id: 1, number: \"12345\", .*>$/, stdout.shift
    assert_match /^=> #<Account id: 2, number: \"54321\", .*>$/, stdout.shift
    assert_equal "Transfer aborted", stdout.shift
    assert_equal "Paul has 550.0", stdout.shift
    assert_equal "Peter has -250.0", stdout.shift
    assert_equal "=> nil", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:accounts, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Account id: 1, number: \"12345\", .*>$/, stdout.shift
    assert_match /^=> #<Account id: 2, number: \"54321\", .*>$/, stdout.shift
    assert_equal "Transfer aborted", stdout.shift
    assert_equal "Paul has 200.0", stdout.shift
    assert_equal "Peter has 100.0", stdout.shift
    assert_equal "=> nil", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:accounts, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Account id: 1, number: \"12345\", .*>$/, stdout.shift
    assert_match /^=> #<Account id: 2, number: \"54321\", .*>$/, stdout.shift
    assert_equal "Transfer aborted", stdout.shift
    assert_equal "Paul has 200.0", stdout.shift
    assert_equal "Peter has 100.0", stdout.shift
    assert_equal "=> nil", stdout.shift
    stdout.shift if stdout.first == 'Switch to inspect mode.'
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:counters, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 0", stdout.shift
    assert_equal "=> #<Counter id: 1, count: 0, lock_version: 0>", stdout.shift
    assert_equal "=> #<Counter id: 1, count: 0, lock_version: 0>", stdout.shift
    assert_equal "=> #<Counter id: 1, count: 0, lock_version: 0>", stdout.shift
    assert_equal "=> 3", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> 4", stdout.shift
    assert_match /^\sfrom /, stdout.shift
    stdout.shift while stdout.first =~ /^\sfrom /
    assert stdout.empty?
  end

  section 21, "Action Controller: Routing and URLs" do
    assert_select '.stdout', /^ \s*
      edit_article_comment \s GET \s+
      \/articles\/:article_id\/comments\/:id\/edit (\(.:format\))? \s+
      ( \{:controller=&gt;"comments", \s :action=&gt;"edit"\} |
      \{:action=&gt;"edit", \s :controller=&gt;"comments"\} ) $
    /x
    assert_select '.stdout', /5 tests, 29 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /1 tests, 1 assertions, 0 failures, 0 errors/
  end

  section 21.2, 'Routing Requests' do
    # routes_for_depot.rb
    stdout = collect_stdout.grep(/^=>/).map {|line| sort_hash(line)}
    assert_equal '=> true', stdout.shift
    assert_match /^=> (nil|\[.*?\])/, stdout.shift
    assert_match /^=> (nil|\[.*?\])/, stdout.shift
    stdout.shift if stdout.first =~ /^=> (nil|\[.*?\])/
    assert_match /^=> #<Action\w+::Routing::RouteSet:.*>/, stdout.shift
    assert_match /^=> #<Action\w+::Integration::Session:.*>/, stdout.shift
    assert_equal '=> nil', stdout.shift
    assert_equal '=> {:action=>"index", :controller=>"store"}', stdout.shift
    assert_equal '=> {:action=>"add_to_cart", :controller=>"store", :id=>"1"}', stdout.shift
    assert_equal '=> {:action=>"add_to_cart", :controller=>"store", :format=>"xml", :id=>"1"}', stdout.shift
    assert_equal '=> "/store"', stdout.shift
    assert_equal '=> "/store/index/123"', stdout.shift
    if stdout.first =~ /coupon/ # Rails 2.x
      # Demo ActionController::Routing.use_controllers!
      assert_equal '=> {:action=>"show", :controller=>"coupon", :id=>"1"}', stdout.shift
      assert_equal '=> []', stdout.shift
      assert_equal '=> {:action=>"show", :controller=>"coupon", :id=>"1"}', stdout.shift
    end
    assert_equal '=> "http://www.example.com/store/display/123"', stdout.shift

    # routes_for_blog.rb
    stdout.shift if stdout.first == '=> false'
    assert_equal '=> true', stdout.shift
    stdout.shift if stdout.first == '=> []'
    assert_equal '=> nil', stdout.shift
    assert_match /^=> \[("article", "blog")?\]/, stdout.shift
    assert_match /^=> #<Action\w+::Routing::RouteSet:.*>/, stdout.shift
    assert_match /^=> #<Action\w+::Integration::Session:.*>/, stdout.shift
    assert_match /^=> \[ActionController::Base, ActionView::Base\]|#<Rack::Mount::RouteSet.*>/, stdout.shift
    assert_equal '=> {:action=>"index", :controller=>"blog"}', stdout.shift
    assert_equal '=> {:action=>"show", :controller=>"blog", :id=>"123"}', stdout.shift
    assert_equal '=> {:action=>"show_date", :controller=>"blog", :year=>"2004"}', stdout.shift
    assert_equal '=> {:action=>"show_date", :controller=>"blog", :month=>"12", :year=>"2004"}', stdout.shift
    assert_equal '=> {:action=>"show_date", :controller=>"blog", :day=>"25", :month=>"12", :year=>"2004"}', stdout.shift
    assert_equal '=> {:action=>"edit", :controller=>"article", :id=>"123"}', stdout.shift
    assert_equal '=> {:action=>"show_stats", :controller=>"article"}', stdout.shift
    assert_equal '=> {:action=>"unknown_request", :controller=>"blog"}', stdout.shift
    assert_equal '=> {:action=>"unknown_request", :controller=>"blog"}', stdout.shift
    assert_equal '=> {:action=>"show_date", :controller=>"blog", :day=>"28", :month=>"07", :year=>"2006"}', stdout.shift
    assert_equal '=> "/blog/2006/07/25"', stdout.shift
    assert_equal '=> "/blog/2005"', stdout.shift
    assert_equal '=> "/blog/show/123"', stdout.shift
    assert_equal '=> "/blog/2006/07/28"', stdout.shift
    assert_equal '=> "/blog/2006"', stdout.shift
    assert_equal '=> "http://www.example.com/blog/2002"', stdout.shift
    assert_equal '=> "http://www.example.com/blog/2002"', stdout.shift
  end

  section 23.3, 'Helpers for Formatting, Linking, and Pagination' do
    assert_select '.stdout', /^==  CreateUsers: migrated/
    assert_select '.stdout', '=&gt; 763'
    assert_select "a[href=http://localhost:#{$PORT}/pager/user_list?page=27]", '27'
  end

  section 23.5, 'Forms That Wrap Model Objects' do
    assert_select "input[name='product[price]'][value=0.0]"
    assert_select 'option[selected=selected]', 'United States'
    assert_select 'input[id=details_sku]'
  end

  section 23.6, 'Custom Form Builders' do
    assert_select "textarea[id=product_description]"
  end

  section 23.7, 'Working with Nonmodel Fields' do
    assert_select "input[id=arg1]"
  end

  section 23.8, 'Uploading Files to Rails Applications' do
    assert_select "input[id=picture_uploaded_picture][type=file]"
  end

  section 23.9, 'Layouts and Components' do
    assert_select "hr"
  end

  section '23.10', 'Caching, Part Two' do
    # not exactly a good test of the function in question...
    assert_select "p", 'There are a total of 4 articles.'
  end

  section 23.11, 'Adding New Templating Systems' do
    next if ActiveSupport::VERSION::STRING == '2.2.2'
    assert_select "em", 'real'
    assert_select ".body", /(over|almost) \d+ years/u
    assert_select ".body", /request\.path =(>|&gt;) \/test\/example1/u
    assert_select ".body", /a \+ b =(>|&gt;) 3/u
  end

  section 25.1, "Sending E-mail" do
    assert_select 'pre', /Thank you for your recent order/
    assert_select 'pre', /1 x Programming Ruby, 2nd Edition/
    assert_select '.body', 'Thank you...'
    assert_select '.stdout', /2 tests, 4 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /1 tests, 5 assertions, 0 failures, 0 errors/
  end

  section 26, "Active Resources" do
    assert_select '.stdout', /ActiveResource::Redirection: Failed.* 302/
    assert_select '.stdout', '29.95'
    assert_select '.stdout', '=&gt; true'
    assert_select '.price', '$24.95'
    assert_select '.stdout', '=&gt; "Dave Thomas"'
    assert_select '.stdout', /NoMethodError: undefined method `line_items'/
    assert_select '.stdout', /&lt;id type="integer"&gt;1&lt;\/id&gt;/
    assert_select '.stdout', /"product_id"=&gt;3/
    assert_select '.stdout', /=&gt; 22.8/
  end
end

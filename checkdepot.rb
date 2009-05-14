require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'

class DepotTest < ActiveSupport::TestCase
  # just enough infrastructure to get 'assert_select' to work
  require 'action_controller'
  require 'action_controller/assertions/selector_assertions'
  include ActionController::Assertions::SelectorAssertions

  # micro DSL allowing the definition of optional tests
  def self.section number, title, &tests
    @@sections ||= self.sections
    return if ARGV.include? 'partial' and !@@sections.has_key? number.to_s
    test "#{number} #{title}" do
      instance_eval {select number}
      instance_eval &tests
    end
  end

  # read and pre-process makedepot.html (only needs to be done once)
  def self.sections
    # read makedepot output; remove front matter and footer
    output = open('makedepot.html').read
    output.sub! /.*<body>\s+/m, ''
    output.sub! /\s+<\/body>.*/m, ''

    # split into sections
    @@sections = output.split(/<a class="toc" name="section-(.*?)">/)

    # convert to a Hash
    @@sections = Hash[*@@sections.unshift('head')]

    # reattach anchors
    @@sections.each do |key,value|
      @@sections[key] = "<a class='toc' name='#{key}'>#{value}"
    end

    # report version
    output =~ /rails .*?-v<\/pre>\s+.*?>(.*)<\/pre>/
    @@version = $1
    @@version += ' (git)' if output =~ /ln -s.*vendor.rails/
    @@version += ' (edge)' if output =~ /rails:freeze:edge/
    STDERR.puts @@version

    @@sections
  end

  # select an individual section from the HTML
  def select number
    raise "Section #{number} not found" unless @@sections.has_key? number.to_s
    @selected = HTML::Document.new(@@sections[number.to_s]).root.children
    assert @@sections[number.to_s] !~
      /<pre class="traceback">\s+#&lt;IndexError: regexp not matched&gt;/,
      "edit failed"
  end

  def collect_stdout
    css_select('.stdout').map do |tag|
      tag.children.join.gsub('&lt;','<').gsub('&gt;','>')
    end
  end

  section 4, 'Instant Gratification' do
    stdout = collect_stdout

    assert_equal '<ul>', stdout.shift
    assert_equal '  <li>Addition: 3 </li>', stdout.shift
    assert_equal '  <li>Concatenation: cowboy </li>', stdout.shift
    assert_match /^  <li>Time in one hour:  \w+ \w+ \d+ \d\d:\d\d:\d\d [+-]\d+ \d+ <\/li>/, stdout.shift
    assert_equal '</ul>', stdout.shift

    3.times do
      assert_equal ' ', stdout.shift
      assert_equal 'Ho!<br />', stdout.shift
    end
    assert_equal ' ', stdout.shift
    assert_equal 'Merry Christmas!', stdout.shift

    3.times { assert_equal 'Ho!<br />', stdout.shift }
    assert_equal ' ', stdout.shift
    assert_equal 'Merry Christmas!', stdout.shift

    3.times { assert_equal 'Ho!<br />', stdout.shift }
    assert_equal 'Merry Christmas!', stdout.shift

    assert stdout.empty?
  end

  section 6.2, 'Creating the Products Model and Maintenance Application' do
    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=Pragmatic Version Control]'
    assert_select 'a[href=http://127.0.0.1:3000/products/1]', 'redirected'
    assert_select '.stdout', /"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL/
    assert_select '.stdout', /7 tests, 10 assertions, 0 failures, 0 errors/
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
    assert_select '.stdout', /Missing template store\/add_to_cart/
    assert_select 'h2', 'Your Pragmatic Cart'
    assert_select 'li', 'Pragmatic Project Automation'
  end

  section 8.3, "Iteration C2: A Smarter Cart" do
    assert_select '.stdout', /NoMethodError/
    assert_select '.stdout', /in StoreController#add_to_cart/
    assert_select 'li', '2 &times; Pragmatic Project Automation'
    assert_select 'pre', "Couldn't find Product with ID=wibble"
  end

  section 8.4, "Iteration C3: Handling Errors" do
    assert_select 'a[href=http://127.0.0.1:3000/store]', 'redirected'
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
    assert_select 'p', /No action responded to save_order./
    assert_select 'h2', '5 errors prohibited this order from being saved'
    assert_select '#notice', 'Thank you for your order'
  end

  section 11.1, "Iteration F1: Adding Users" do
    assert_select 'legend', 'Enter User Details'
    assert_select 'p[style=color: green]', 'User dave was successfully created.'
  end

  section 11.2, "Iteration F2: Logging in" do
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
  end

  section 11.3, "Iteration F3: Limiting Access" do
    assert_select 'a[href=http://127.0.0.1:3000/admin/login]', 'redirected'
    assert_select 'h1', 'Listing products'
  end

  section 11.4, "Iteration F4: A Sidebar, More Administration" do
    assert_select '.stdout', /NoMethodError in/
    assert_select '.stdout', /Admin#index/
    assert_select '#main h1', 'Listing users'
    assert_select '.stdout', /=&gt; #&lt;Product id: nil/
  end

  section 12.1, "Generating the XML Feed" do
    assert_select '.stdout', /No route matches &amp;quot;\/info\/who_bought\//
    assert_select '.stdout', /&lt;email&gt;customer@pragprog.com&lt;\/email&gt;/
    assert_select '.stdout', /title = Pragmatic Project Automation/
    assert_select '.stdout', /total_price = 28.5/
    assert_select '.stdout', /&lt;id type="integer"&gt;3&lt;\/id&gt;/
    assert_select '.stdout', /&lt;td&gt;Pragmatic Version Control&lt;\/td&gt;/
    assert_select '.stdout', /, "title": "Pragmatic Version Control"/
  end

  section 13, "Internationalization" do
    assert_select '#notice', 'es translation not available'
    assert_select 'option[value=es]'
    assert_select '.price', '28,50&nbsp;$US'
    assert_select 'h1', 'Su Cat&aacute;logo de Pragmatic'
    assert_select 'input[type=submit][value=A&ntilde;adir al Carrito]'
    assert_select 'h2', '5 errores han impedido que este pedido se guarde'
    assert_select '#notice', 'Gracias por su pedido'
  end

  section 14.2, "Unit Testing of Models" do
    assert_select '.stdout', /SQLite3::SQLException: no such table: users/
    assert_select '.stdout', '1 tests, 1 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '4 tests, 4 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '9 tests, 27 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '2 tests, 5 assertions, 0 failures, 0 errors'
  end

  section 14.3, "Functional Testing of Controllers" do
    assert_select '.stdout', '5 tests, 8 assertions, 0 failures, 0 errors'
  end

  section 14.4, "Integration Testing of Applications" do
    assert_select '.stdout', '1 tests, 17 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '2 tests, 49 assertions, 0 failures, 0 errors'
  end

  section 14.5, "Performance Testing" do
    assert_select '.stderr', 'Using the standard Ruby profiler.'
    assert_select '.stderr', /Math.sin/
  end

  section 15, "Rails In Depth" do
    assert_select '.stdout', 'Current version: 20080601000007'
  end

  section 17, "Migration" do
    assert_select '.stderr', /near "auto_increment": syntax error/
    assert_select '.stderr', 'uninitialized constant TestDiscounts::Sku'

    stdout = css_select('.stdout').map {|tag| tag.children.join}
    stdout = stdout.select {|line| line =~ /^== / and line !~ /ing ===/}
    assert_match /AddEmailToOrders: migrated/, stdout.shift
    assert_match /CreateDiscounts: migrated/, stdout.shift
    assert_match /AddStatusToUser: migrated/, stdout.shift
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
    stdout = collect_stdout
    assert_equal ">> Order.column_names", stdout.shift
    assert_equal "=> [\"id\", \"name\", \"address\", \"email\", \"pay_type\", \"created_at\", \"updated_at\", \"customer_email\", \"placed_at\", \"attn\", \"order_type\", \"ship_class\", \"amount\", \"state\"]", stdout.shift
    assert_equal ">> ", stdout.shift
    assert_equal ">> Order.columns_hash[\"pay_type\"]", stdout.shift
    assert_match /ActiveRecord::ConnectionAdapters::SQLiteColumn/, stdout.shift
    assert_equal ">> ", stdout.shift
    assert_equal "            id = 1", stdout.shift
    assert_equal "          name = Dave Thomas", stdout.shift
    assert_equal "       address = 123 Main St", stdout.shift
    assert_equal "         email = customer@pragprog.com", stdout.shift
    assert_equal "      pay_type = check", stdout.shift
    assert_match /^    created_at = \d+-\d+-\d+ \d+:\d+:\d+$/, stdout.shift
    assert_match /^    updated_at = \d+-\d+-\d+ \d+:\d+:\d+$/, stdout.shift
    assert_equal "customer_email = ", stdout.shift
    assert_match /^     placed_at = \d+-\d+-\d+ \d+:\d+:\d+$/, stdout.shift
    assert_equal "          attn = ", stdout.shift
    assert_equal "    order_type = ", stdout.shift
    assert_equal "    ship_class = priority", stdout.shift
    assert_equal "        amount = ", stdout.shift
    assert_equal "         state = ", stdout.shift
    assert_equal ">> Product.find(:first).price_before_type_cast", stdout.shift
    assert_equal "=> \"29.95\"", stdout.shift
    assert_equal ">> ", stdout.shift
    assert_equal ">> Product.find(:first).updated_at_before_type_cast", stdout.shift
    assert_match /^=> "\d+-\d+-\d+ \d+:\d+:\d+"$/, stdout.shift
    assert_equal ">> ", stdout.shift
    assert_match /^=> \[.*\]/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Order id: nil, name: nil/, stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> \"dave@pragprog.com\"", stdout.shift
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
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "[\"name\", \"pay_type\"]", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "false", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^\[.*#<Order id: 9, name: "Andy Hunt".*>\]/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^#<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^#<Order id: 1, name: "Dave Thomas"/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^\[#<Order id: 9, name: "Andy Hunt"/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^\[#<Order id: 9, name: "Andy Hunt"/, stdout.shift
    assert_equal "=> nil", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_equal "=> nil", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "\"ski mask\"", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
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
    assert_match /^=> #<Name:0x\w+ @last="Eisenhower"/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_equal "Dwight", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Dwight D Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Name:0x\w+ @last="Truman"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert stdout.empty?
  end

  section 19, 'Active Record: Relationships Between Tables' do
    stdout = collect_stdout
    stdout.reject! {|line| line =~ /' -> `vendor\/plugins\//}
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
    assert_match /^=> #<Proc:.*>$/, stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "=============", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Product id: 4, title: "Advanced Rails"/, stdout.shift
    assert_equal "1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "-- create_table(:people, {:force=>true})", stdout.shift
    assert_equal " FROM sqlite_master", stdout.shift
    assert_equal " WHERE type = 'table' AND NOT name = 'sqlite_sequence'", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)/, stdout.shift
    assert_equal "=> nil", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "content = This is my new article", stdout.shift
    assert_equal "           id = 1", stdout.shift
    assert_equal "         name = Article One", stdout.shift
    assert_match /^  acquired_at = \d+-\d+-\d+ \d+:\d+:\d+/, stdout.shift
    assert_equal "  resource_id = 1", stdout.shift
    assert_equal "resource_type = Article", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
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
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:employees, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Proc:.*>$/, stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "[]", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "\"Clem\"", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> false", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_match /^=> #<Proc:.*>$/, stdout.shift
    assert_match /^=> \[#<ActiveSupport::Callbacks::Callback/, stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Order id: nil, name: nil, email: nil, address: nil, pay_type: nil, shipped_at: nil>", stdout.shift
    assert_equal "nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Order id: nil, name: nil, email: nil, address: nil, pay_type: nil, shipped_at: nil>", stdout.shift
    assert_equal "nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "2", stdout.shift
    assert_equal "=> nil", stdout.shift
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
    assert_match /^=> #<Proc:.*>$/, stdout.shift
    assert_match /^=> (nil|#<Proc:.*>)$/, stdout.shift
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
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> false", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "-- create_table(:orders, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "-- create_table(:users, {:force=>:true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> Encrypter", stdout.shift
    assert_match /^=> #<Proc:0x00000000@.*\/encrypt.rb:34>$/, stdout.shift
    assert_equal "=> #<Order id: nil, user_id: nil, name: nil, address: nil, email: nil>", stdout.shift
    assert_equal "=> \"Dave Thomas\"", stdout.shift
    assert_equal "=> \"123 The Street\"", stdout.shift
    assert_equal "=> \"dave@pragprog.com\"", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "Dave Thomas", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> #<Order id: 1, user_id: nil, name: \"Dave Thomas\", address: \"123 The Street\", email: \"dave@pragprog.com\">", stdout.shift
    assert_equal "Dave Thomas", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "     id = 1", stdout.shift
    assert_equal "user_id = ", stdout.shift
    assert_equal "   name = Dbwf Tipnbt", stdout.shift
    assert_equal "address = 123 The Street", stdout.shift
    assert_equal "  email = ebwf@qsbhqsph.dpn", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> false", stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "-- create_table(:payments, {:force=>true})", stdout.shift
    assert_equal " FROM sqlite_master", stdout.shift
    assert_equal " WHERE type = 'table' AND NOT name = 'sqlite_sequence'", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<OrderObserver:.*>$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<AuditObserver:.*>$/, stdout.shift
    assert_equal "Order 2 created", stdout.shift
    assert_equal "[Audit] Order 2 created", stdout.shift
    assert_equal "=> #<Order id: 2, user_id: nil, name: nil, address: nil, email: nil>", stdout.shift
    assert_equal "[Audit] Payment 1 created", stdout.shift
    assert_equal "=> #<Payment id: 1>", stdout.shift
    assert_equal "?> >> ", stdout.shift
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
    assert_equal "=> nil", stdout.shift
    assert_match /^#<BigDecimal:.*>/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> [#<LineItem quantity: 1>, #<LineItem quantity: 2>, #<LineItem quantity: 1>]", stdout.shift
    assert_equal "{\"quantity*unit_price\"=>\"29.95\", \"quantity\"=>1}", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "                                      quantity*unit_price as total_price \" +", stdout.shift
    assert_equal "=> [#<LineItem quantity: 1>, #<LineItem quantity: 2>, #<LineItem quantity: 1>]", stdout.shift
    assert_equal "{\"quantity\"=>1, \"total_price\"=>\"29.95\"}", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "\"29.95\"", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 0.07", stdout.shift
    assert_equal "\"\"", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "2.54", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 500", stdout.shift
    assert_equal "true", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "?> >> ", stdout.shift
    assert_equal "                 id = 3", stdout.shift
    assert_equal "quantity*unit_price = 29.95", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "                 id = 4", stdout.shift
    assert_equal "quantity*unit_price = 59.9", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "                 id = 5", stdout.shift
    assert_equal "quantity*unit_price = 44.95", stdout.shift
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
    assert_match /^\sfrom .*\/transactions.rb:82$/, stdout.shift
    assert_match /^\sfrom .*\/transactions.rb:80$/, stdout.shift
    stdout.shift if stdout.first == "\tfrom :0"
    assert_equal "     id = 1", stdout.shift
    assert_equal " number = 12345", stdout.shift
    assert_equal "balance = 100", stdout.shift
    assert_equal " ", stdout.shift
    assert_equal "     id = 2", stdout.shift
    assert_equal " number = 54321", stdout.shift
    assert_equal "balance = 200", stdout.shift
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
    assert stdout.empty?
  end

  section 26, "Active Resources" do
    assert_select '.stdout', /Failed with 302/
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

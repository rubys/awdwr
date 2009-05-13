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

    # for efficiency, collect the stdout children, and make a single pass
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

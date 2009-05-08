require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'

class DepotTest < ActiveSupport::TestCase
  # just enough infrastructure to get 'assert_select' to work
  require 'action_controller'
  require 'action_controller/assertions/selector_assertions'
  include ActionController::Assertions::SelectorAssertions

  # read and pre-process makedepot.html (only needs to be done once)
  def setup
    return if defined? @@sections

    # read makedepot output; remove front matter and footer
    output = open('makedepot.html').read
    output.sub! /.*<body>\s+/m, ''
    output.sub! /\s+<\/body>.*/m, ''

    # split into sections
    @@sections = output.split(/<a class="toc" name="(.*?)">/)

    # convert to a Hash
    @@sections = Hash[*@@sections.unshift('head')]

    # reattach anchors
    @@sections.each do |key,value|
      next if key == 'head'
      @@sections[key] = "<a class='toc' name='#{key}'>#{value}"
    end

    # report version
    @@version = output.match(/rails -v<\/pre>\s+.*?>(.*)<\/pre>/).captures.first
    @@version += ' (git)' if output =~ /ln -s.*vendor.rails/
    STDERR.puts @@version
  end

  # select and parse an individual section
  def section name
    raise "Section #{name} not found" unless @@sections.has_key? name
    @selected = HTML::Document.new(@@sections[name]).root.children
  end

  test "Iteration A1: Get Something Running" do
    section 'a1'
    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=Pragmatic Version Control]'
    assert_select 'a[href=http://127.0.0.1:3000/products/1]', 'redirected'
    assert_select '.stdout', /"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL/
    assert_select '.stdout', /7 tests, 10 assertions, 0 failures, 0 errors/
  end

  test "Iteration A2: Add a Missing Column" do
    section 'a2'
    assert_select '.stdout', 
      /add_column\(:products, :price, :decimal, \{.*:precision=&gt;8.*\}\)/
    assert_select '.stdout', /"price" decimal\(8,2\) DEFAULT 0/
    assert_select 'th', 'Price'
    assert_select 'input#product_price[value=0.0]'
  end

  test "Iteration A3: Validate!" do
    section 'a3'
    assert_select 'h2', '3 errors prohibited this product from being saved'
    assert_select 'li', "Image url can't be blank"
    assert_select 'li', 'Price is not a number'
    assert_select '.fieldWithErrors input[id=product_price]'
  end

  test "Iteration A4: Prettier Listings" do
    section 'a4'
    assert_select '.list-line-even'
  end

  test "Iteration B1: Create the Catalog Listing" do
    section 'b1'
    assert_select 'p', 'Find me in app/views/store/index.html.erb'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '28.5'
  end

  test "Iteration B2: Add a Page Layout" do
    section 'b2'
    assert_select '#banner', /Pragmatic Bookshelf/
  end

  test "Iteration B3: Use a Helper to Format the Price" do
    section 'b3'
    assert_select 'span.price', '$28.50'
  end

  test "Iteration B4: Linking to the Cart" do
    section 'b4'
    assert_select 'input[type=submit][value=Add to Cart]'
  end

  test "Sessions" do
    section '8.1'
    assert_select '.stdout', /CREATE TABLE "sessions"/
  end

  test "Iteration C1: Creating a Cart" do
    section 'c1'
    assert_select '.stdout', /Missing template store\/add_to_cart/
    assert_select 'h2', 'Your Pragmatic Cart'
    assert_select 'li', 'Pragmatic Project Automation'
  end

  test "Iteration C2: A Smarter Cart" do
    section 'c2'
    assert_select '.stdout', /NoMethodError/
    assert_select '.stdout', /in StoreController#add_to_cart/
    assert_select 'li', '2 &times; Pragmatic Project Automation'
    assert_select 'pre', "Couldn't find Product with ID=wibble"
  end

  test "Iteration C3: Handling Errors" do
    section 'c3'
    assert_select 'a[href=http://127.0.0.1:3000/store]', 'redirected'
    assert_select '.hilight', 'Attempt to access invalid product wibble'
    assert_select '#notice', 'Invalid product'
  end

  test "Iteration C4: Finishing the Cart" do
    section 'c4'
    assert_select '#notice', 'Your cart is currently empty'
    assert_select '.total-cell', '$88.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  test "Iteration D1: Moving the Cart" do
    section 'd1'
    assert_select '.cart-title', 'Your Cart'
    assert_select '.total-cell', '$88.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  test "Iteration D5: Degrading If Javascript Is Disabled" do
    section 'd5'
    assert_select '#cart[style=display: none]'
    assert_select '.total-cell', '$28.50'
  end

  test "Iteration E1: Capturing an Order" do
    section 'e1'
    assert_select 'input[type=submit][value=Place Order]'
    assert_select 'p', /No action responded to save_order./
    assert_select 'h2', '5 errors prohibited this order from being saved'
    assert_select '#notice', 'Thank you for your order'
  end

  test "Iteration F1: Adding Users" do
    section 'f1'
    assert_select 'legend', 'Enter User Details'
    assert_select 'p[style=color: green]', 'User dave was successfully created.'
  end

  test "Iteration F2: Logging in" do
    section 'f2'
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
  end

  test "Iteration F3: Limiting Access" do
    section 'f3'
    assert_select 'a[href=http://127.0.0.1:3000/admin/login]', 'redirected'
    assert_select 'h1', 'Listing products'
  end

  test "Iteration F4: A Sidebar, More Administration" do
    section 'f4'
    assert_select '.stdout', /NoMethodError in/
    assert_select '.stdout', /Admin#index/
    assert_select '#main h1', 'Listing users'
    assert_select '.stdout', /=&gt; #&lt;Product id: nil/
  end

  test "Generating the XML Feed" do
    section '12.1'
    assert_select '.stdout', /No route matches &amp;quot;\/info\/who_bought\//
    assert_select '.stdout', /&lt;email&gt;customer@pragprog.com&lt;\/email&gt;/
    assert_select '.stdout', /title = Pragmatic Project Automation/
    assert_select '.stdout', /total_price = 28.5/
    assert_select '.stdout', /&lt;id type="integer"&gt;3&lt;\/id&gt;/
    assert_select '.stdout', /&lt;td&gt;Pragmatic Version Control&lt;\/td&gt;/
    assert_select '.stdout', /, "title": "Pragmatic Version Control"/
  end

  test "13.2 Unit Testing of Models" do
    section '13.2'
    assert_select '.stdout', /SQLite3::SQLException: no such table: users/
    assert_select '.stdout', '1 tests, 1 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '4 tests, 4 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '9 tests, 27 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '2 tests, 5 assertions, 0 failures, 0 errors'
  end

  test "13.3 Functional Testing of Controllers" do
    section '13.3'
    assert_select '.stdout', '5 tests, 8 assertions, 0 failures, 0 errors'
  end

  test "13.4 Integration Testing of Applications" do
    section '13.4'
    assert_select '.stdout', '1 tests, 17 assertions, 0 failures, 0 errors'
    assert_select '.stdout', '2 tests, 49 assertions, 0 failures, 0 errors'
  end

  test "13.5 Performance Testing" do
    section '13.5'
    assert_select '.stderr', 'Using the standard Ruby profiler.'
    assert_select '.stderr', /Math.sin/
  end

  test "14 Rails In Depth" do
    section '14'
    assert_select '.stdout', 'Current version: 20080601000007'
  end

  test "11.9 I18N" do
    section '11.9'
    assert_select '#notice', 'es translation not available'
    assert_select 'option[value=es]'
    assert_select '.price', '28,50&nbsp;$US'
    assert_select 'h1', 'Su Cat&aacute;logo de Pragmatic'
    assert_select 'input[type=submit][value=A&ntilde;adir al Carrito]'
    assert_select 'h2', '5 errores han impedido que este pedido se guarde'
    assert_select '#notice', 'Gracias por su pedido'
  end

  test "25 ActiveResource" do
    section '25'
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

  test "16 Migration" do
    section '16'
    assert_select '.stderr', /near "auto_increment": syntax error/
    assert_select '.stderr', 'uninitialized constant TestDiscounts::Sku'

    # for efficiency, collect the stdout children, and make a single pass
    stdout = css_select('.stdout').map {|tag| tag.children.join}
    %w(
      CreateDiscounts
      AddStatusToUser
      AddEmailToOrders
      AddPlacedAtToOrders
      AddColumnsToOrders
      RenameEmailColumn
      ChangeOrderTypeToString
      CreateOrderHistories
      RenameOrderHistories
      CreateOrderHistories2
      AddCustomerNameIndexToOrders
      CreateAuthorBook
      CreateTableTickets
      LoadUserData
      ChangePriceToInteger
      TotalPriceToUnit
      AddForeignKey
    ).each do |name|
      search = "==  #{name}: migrated"
      assert !stdout.grep(Regexp.new(search)).empty?, search
    end
  end
end

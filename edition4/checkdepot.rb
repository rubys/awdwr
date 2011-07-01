require 'rubygems'
require 'gorp/test'

class DepotTest < Gorp::TestCase

  input 'makedepot'
  output 'checkdepot'

  section 2, 'Instant Gratification' do
    ticket 4147,
      :title =>  "link_to generates incorrect hrefs",
      :match => /say\/hello\/say\/goodbye/

    assert_select 'h1', 'Hello from Rails!'
    assert_select "p", 'Find me in app/views/say/hello.html.erb'
    assert_select "a[href=http://localhost:#{$PORT}/say/goodbye]"
    assert_select "a[href=http://localhost:#{$PORT}/say/hello]"
    if RUBY_VERSION =~ /^1.8/
      assert_select 'p', /^It is now \w+ \w+ \d\d \d\d:\d\d:\d\d [+-]\d+ \d+/
    else
      assert_select 'p', /^It is now \d+-\d\d-\d\d \d\d:\d\d:\d\d [+-]\d+/
    end
  end

  section 6.1, 'Iteration A1: Creating the Products Maintenance Application' do
    ticket 3562,
      :list => :ruby,
      :title =>  "regression in respond_to?",
      :match => /I18n::UnknownFileType/
    assert_select '.stderr', :minimum => 0 do |errors|
      errors.each do |err|
        assert_match /\d+ tests, \d+ assertions, 0 failures, 0 errors/, err.to_s
      end
    end

    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=Web Design for Developers]'
    assert_select "a[href=http://localhost:#{$PORT}/products/1]", 'redirected'
    assert_select 'pre', /(1|0) tests, (1|0) assertions, 0 failures, 0 errors/,
      '(1|0) tests, (1|0) assertions, 0 failures, 0 errors'
    assert_select 'pre', /7 tests, 10 assertions, 0 failures, 0 errors/,
      '7 tests, 10 assertions, 0 failures, 0 errors'
  end

  section 6.2, "Iteration A2: Prettier Listings" do
    ticket 3570,
      :title =>  "Intermittent reloading issue: view",
      :match => /\.list_line_even/
    assert_select '.list_line_even'
  end

  section 6.3, "Playtime" do
    # assert_select '.stdout', /CreateProducts: reverted/
    # assert_select '.stdout', /CreateProducts: migrated/
    assert_select '.stdout', /user.email/
    assert_select '.stdout', /Initialized empty Git repository/
    assert_select '.stdout', /(Created initial |root-)commit.*Depot Scaffold/
  end

  section 7.1, "Iteration B1: Validate!" do
    assert_select 'h2', /4 errors\s+prohibited this product from being saved/
    assert_select 'li', "Image url can't be blank"
    assert_select 'li', 'Price is not a number'
    assert_select '.field_with_errors input[id=product_price]'
  end

  section 7.2, 'Iteration B2: Unit Testing' do
    ticket 3555,
      :list => :ruby,
      :title =>  "segvs since r28570",
      :match => /active_support\/dependencies.rb:\d+: \[BUG\] Segmentation fault/
    assert_select 'pre', /(1|0) tests, (1|0) assertions, 0 failures, 0 errors/,
      '(1|0) tests, (1|0) assertions, 0 failures, 0 errors'
    assert_select 'pre', /7 tests, 10 assertions, 0 failures, 0 errors/,
      '7 tests, 10 assertions, 0 failures, 0 errors'
    assert_select 'pre', /5 tests, 23 assertions, 0 failures, 0 errors/,
      '5 tests, 23 assertions, 0 failures, 0 errors'
  end

  section 8.1, "Iteration C1: Create the Catalog Listing" do
    assert_select 'p', 'Find me in app/views/store/index.html.erb'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '49.5'
  end

  section 8.2, "Iteration C2: Add a Page Layout" do
    assert_select '#banner', /Pragmatic Bookshelf/
  end

  section 8.3, "Iteration C3: Use a Helper to Format the Price" do
    assert_select 'span.price', '$49.50'
  end

  section 8.4, "Iteration C4: Functional Testing" do
    assert_select 'pre', /5 tests, 23 assertions, 0 failures, 0 errors/
    assert_select 'pre', /8 tests, 11 assertions, 0 failures, 0 errors/
    assert_select 'pre', /8 tests, 15 assertions, 0 failures, 0 errors/
  end

  section 9.3, "Iteration D3: Adding a button" do
    assert_select 'input[type=submit][value=Add to Cart]'
    assert_select "a[href=http://localhost:#{$PORT}/carts/1]", 'redirected'
    assert_select '#notice', 'Line item was successfully created.'
    assert_select 'li', 'Programming Ruby 1.9'
  end

  section 9.4, "Playtime" do
    assert_select 'pre', /\d tests, 2\d assertions, 0 failures, 0 errors/,
      '\d tests, 2\d assertions, 0 failures, 0 errors'
    assert_select 'pre', /22 tests, 35 assertions, 0 failures, 0 errors/,
      '22 tests, 35 assertions, 0 failures, 0 errors'
  end

  section 10.1, "Iteration E1: Creating A Smarter Cart" do
    assert_select 'li', /3 (.|&#?\w+;) Programming Ruby 1.9/u
    assert_select 'pre', /Couldn't find Cart with ID=wibble/i
  end

  section 10.2, "Iteration E2: Handling Errors" do
    assert_select "a[href=http://localhost:#{$PORT}/]", 'redirected'
    assert_select '.hilight', 'Attempt to access invalid cart wibble'
    assert_select '#notice', 'Invalid cart'
  end

  section 10.3, "Iteration E3: Finishing the Cart" do
    assert_select '#notice', 'Your cart is currently empty'
    assert_select '.total_cell', '$135.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 10.4, "Playtime" do
    assert_select 'pre', /\d tests, 2\d assertions, 0 failures, 0 errors/,
      '7 tests, 25 assertions, 0 failures, 0 errors'
    assert_select 'pre', /23 tests, 37 assertions, 0 failures, 0 errors/,
      '23 tests, 37 assertions, 0 failures, 0 errors'
    assert_select '.stdout', /AddPriceToLineItem: migrated/
  end

  section 11.1, "Iteration F1: Moving the Cart" do
    assert_select '.cart_title', 'Your Cart'
    assert_select '.total_cell', '$135.40'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 11.4, "Iteration F4: Hide an Empty Cart" do
    assert_select '#cart[style=display: none]'
    assert_select '.total_cell', '$184.90'
  end

  section 11.5, "Testing AJAX changes" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_select 'pre', /\d tests, 2\d assertions, 0 failures, 0 errors/,
      '\d tests, 2\d assertions, 0 failures, 0 errors'
    assert_select 'code', "undefined method `line_items' for nil:NilClass"
    assert_select 'pre', /2\d tests, 4\d assertions, 0 failures, 0 errors/,
      '2\d tests, 4\d assertions, 0 failures, 0 errors'
  end

  section 12.1, "Iteration G1: Capturing an Order" do
    assert_select 'input[type=submit][value=Place Order]'
    assert_select 'h2', /5 errors\s+prohibited this order from being saved/
    assert_select '#notice', 'Thank you for your order.'
  end

  section 12.2, "Iteration G2: Atom Feeds" do
    # raw xml
    assert_select '.stdout', /&lt;email&gt;customer@example.com&lt;\/email&gt;/,
      'Missing <email>customer@example.com</email>'
    assert_select '.stdout', /&lt;id type="integer"&gt;1&lt;\/id&gt;/,
      'Missing <id type="integer">1</id>'

    # html
    assert_select '.stdout', /&lt;a href="mailto:customer@example.com"&gt;/,
      'Missing <a href="mailto:customer@example.com">'

    # atom
    assert_select '.stdout', /&lt;summary type="xhtml"&gt;/,
      'Missing <summary type="xhtml">'
    assert_select '.stdout', /&lt;td&gt;Programming Ruby 1.9&lt;\/td&gt;/,
      'Missing <td>Programming Ruby 1.9</td>'

    # json
    assert_select '.stdout', /, ?"title": ?"Programming Ruby 1.9"/,
      'Missing "title": "Programming Ruby 1.9"'

    # custom xml
    assert_select '.stdout', /&lt;order_list for_product=.*&gt;/,
      'Missing <order_list for_product=.*>'
  end

  section 12.3, "Iteration G3: Pagination" do
    next unless File.exist? 'public/images'
    assert_select 'td', 'Customer 100'
    assert_select "a[href=http://localhost:#{$PORT}/orders?page=4]"
  end

  section 12.4, "Playtime" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_select 'pre', 
      /\d tests, [23]\d assertions, 0 failures, 0 errors/,
      '\d tests, [23]\d assertions, 0 failures, 0 errors'
    assert_select 'pre', 
      /3\d tests, [45]\d assertions, 0 failures, 0 errors/,
      '3\d tests, [45]\d assertions, 0 failures, 0 errors'
  end

  section 12.7, "Iteration J2: Email Notifications" do
    assert_select 'pre', /2 tests, \d+ assertions, 0 failures, 0 errors/
  end

  section 12.8, "Iteration J3: Integration Tests" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    ticket 4213,
      :title =>  "undefined method `named_routes' in integration test",
      :match => /NoMethodError: undefined method `named_routes' for nil:NilClass/
    assert_select 'pre', /3 tests, \d+ assertions, 0 failures, 0 errors/
  end

  section 13.1, "Iteration H1: Adding Users" do
    assert_select 'legend', 'Enter User Details'
    # assert_select 'td', 'User dave was successfully created.'
    assert_select 'h1', 'Listing users'
    assert_select 'td', 'dave'
  end

  section 13.2, "Iteration H2: Authenticating Users" do
  end

  section 13.3, "Iteration H3: Limiting Access" do
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
    assert_select "a[href=http://localhost:#{$PORT}/login]", 'redirected'
    assert_select 'h1', 'Listing products'
  end

  section 13.4, "Iteration H4: Adding a Sidebar" do
  end

  section 13.5, "Playtime" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_select 'pre',
      /1?\d tests, [23]\d assertions, 0 failures, 0 errors/,
      '1?\d tests, [23]\d assertions, 0 failures, 0 errors'
    assert_select 'pre', 
      /46 tests, [78]\d assertions, 0 failures, 0 errors/
      '46 tests, [78]\d assertions, 0 failures, 0 errors'

    assert_select '.stdout', /login"&gt;redirected/
    assert_select '.stdout', /customer@example.com/
  end

  section 15.1, "Task I1: i18n for the store front" do
    assert_select '#notice', 'es translation not available'
    assert_select '.price', /49,50(.|&#?\w+;)\$US/u
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_select 'input[type=submit][value$=dir al Carrito]'
  end

  section 15.2, "Task I2: i18n for the cart" do
    assert_select 'td', /1(.|&#?\w+;)/u
    assert_select 'td', 'Web Design for Developers'
  end

  section 15.3, "Task I3: i18n for the order page" do
    # ticket 5971,
    #   :title =>  "labels don't treat I18n name_html as html_safe",
    #   :match => /Direcci&amp;oacute;n/
    # ticket 5971,
    #   :title =>  "labels don't treat I18n name_html as html_safe",
    #   :match => /&lt;span class=&quot;translation_missing&quot;&gt;/

    assert_select 'input[type=submit][value$=Comprar]'
    assert_select '#error_explanation',
      /5 errores han impedido que este pedido se guarde/
    assert_select '#notice', 'Gracias por su pedido'
  end

  section 15.4, "Task I4: Add a locale switcher" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_select 'option[value=es]'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_select 'pre', 
      /1?\d tests, [23]\d assertions, 0 failures, 0 errors/,
      '1?\d tests, [23]\d assertions, 0 failures, 0 errors'
    assert_select 'pre', 
      /46 tests, [78]\d assertions, 0 failures, 0 errors/,
      '46 tests, [78]\d assertions, 0 failures, 0 errors'
    assert_select 'pre', 
      /3 tests, \d+ assertions, 0 failures, 0 errors/,
      '3 tests, \d+ assertions, 0 failures, 0 errors'
  end

  section 16, "Deployment" do
    assert_select '.stderr', /depot_production already exists/
    assert_select '.stdout', /assume_migrated_upto_version/
    assert_select '.stdout', '[done] capified!'
    assert_select '.stdout', /depot\/log\/production.log/
  end

  section 18, "Finding Your Way Around" do
    assert_select '.stdout', 'Current version: 20110211000009'
  end

  section 20.1, "Testing Routing" do
    assert_select 'pre', 
      /1\d tests, 4\d assertions, 0 failures, 0 errors/,
      '1\d tests, 4\d assertions, 0 failures, 0 errors'
  end

  section 21.1, "Views" do
    assert_select '.stdout', /&lt;price currency="USD"&gt;49.5&lt;\/price&gt;/
    assert_select '.stdout', /"1 minute"/
    assert_select '.stdout', /"half a minute"/
    assert_select '.stdout', /"CAN\$235"/
    assert_select '.stdout', /"66\.667%"/
    assert_select '.stdout', /"66\.7%"/
    assert_select '.stdout', /"212-555-1212"/
    assert_select '.stdout', /"\(212\) 555 1212"/
    assert_select '.stdout', /"12,345,678"/
    assert_select '.stdout', /"12_345_678"/
    assert_select '.stdout', /"16.67"/
  end

  section '22', 'Caching' do
    assert_select '.stdout', /304 Not Modified/
    assert_select '.stdout', /Etag:/i
    assert_select '.stdout', /Cache-Control: public/i

    # not exactly a good test of the function in question...
    # assert_select "p", 'There are a total of 4 articles.'
  end

  section 24.3, "Active Resources" do
    # assert_select '.stdout', /ActiveResource::Redirection: Failed.* 302/
    assert_select '.stdout', '42.95'
    assert_select '.stdout', '=&gt; true'
    assert_select '.price', '$37.95'
    assert_select '.stdout', '=&gt; "Dave Thomas"'
    assert_select '.stdout', /NoMethodError: undefined method `line_items'/
    if File.exist? "#{$WORK}/depot/public/images"
      assert_select '.stdout', /&lt;id type="integer"&gt;\d+&lt;\/id&gt;/
    else
      assert_select '.body', /[{,]"id":\d+[,}]/
    end
    assert_select '.stdout', /"product_id"=&gt;3/
    assert_select '.stdout', /=&gt; 39.6/
  end

  section 25.1, 'rack' do
    assert_select 'p', '43.75'
    assert_select 'h2', 'Programming Ruby 1.9'
  end

  section 25.2, 'rake' do
    assert_select '.stderr', /^mkdir -p .*db\/backup$/
    assert_select '.stderr', 
      /^sqlite3 .*?db\/production\.db \.dump &gt; .*\/production.backup$/
  end

  section 26.1, 'Active Merchant' do
    assert_select '.stdout', 'Is 4111111111111111 valid?  false'
  end

  section 26.2, 'Asset Packager' do
    next unless File.exist? 'public/images'
    assert_select '.stdout', 'config/asset_packages.yml example file created!'
    assert_select '.stdout', '  - depot'
    assert_select '.stdout', 
      /Created .*\/public\/javascripts\/base_packaged\.js/
  end

  section 26.3, 'HAML' do
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '$49.50'
  end

  section 26.4, 'JQuery' do
    next unless File.exist? 'public/images'
    assert_select '.logger', /force\s+public\/javascripts\/rails\.js/
    assert_select '.stdout', /No RJS statement/
    assert_select '.stdout', /4\d tests, 7\d assertions, 0 failures, 0 errors/
  end

  section 100, "Performance Testing" do
    assert_select '.stderr', 'Using the standard Ruby profiler.'
    assert_select '.stderr', /Math.sin/
  end

  section 106.4, "Rails on the Inside" do
    stdout = collect_stdout
    assert_match /"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL/, stdout.shift
    assert_match /schema_migrations/, stdout.shift
    assert_match /unique_schema_migrations/, stdout.shift
    assert_equal 'version = 20110211000001', stdout.shift
    assert_equal "class Product < ActiveRecord::Base", stdout.shift
    assert_equal "end", stdout.shift

    stdout.shift if stdout.first =~ /Loading development environment/
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_equal ">> Product.column_names", stdout.shift
    assert_equal "=> [\"id\", \"title\", \"description\", \"image_url\", \"price\", \"created_at\", \"updated_at\"]", stdout.shift
    assert_equal ">> ", stdout.shift

    stdout.shift if stdout.first =~ /Loading development environment/
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_equal ">> Product.columns_hash[\"price\"]", stdout.shift
    assert_match /ActiveRecord::ConnectionAdapters::SQLiteColumn/, stdout.shift
    assert_equal ">> ", stdout.shift
    # p=Product.find(1); puts p.title; p.title+= " Using Git"

    stdout.shift if stdout.first =~ /Loading development environment/
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_equal ">> p=Product.first", stdout.shift
    assert_match /^=> #<Product id: 2, title: "Web Design for Developers"/, stdout.shift
    assert_equal ">> puts p.title", stdout.shift
    assert_equal "Web Design for Developers", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal '>> p.title+= " Using Rails"', stdout.shift
    assert_equal '=> "Web Design for Developers Using Rails"', stdout.shift
    assert_equal '>> ', stdout.shift
    # sqlite3> select * from products limit 1
    assert_equal "         id = 2", stdout.shift
    assert_equal "      title = Web Design for Developers", stdout.shift
    assert_equal "description = <p>", stdout.shift
    stdout.shift while !stdout.first.include?("</p>")
    assert_match /<\/p>/, stdout.shift
    assert_equal "  image_url = /images/wd4d.jpg", stdout.shift
    assert_equal "      price = 42.95", stdout.shift
    assert_match /^ created_at = \d\d\d\d-\d\d-\d\d/, stdout.shift
    assert_match /^ updated_at = \d\d\d\d-\d\d-\d\d/, stdout.shift

    stdout.shift if stdout.first =~ /Loading development environment/
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_equal ">> Product.first.price_before_type_cast", stdout.shift
    assert_equal "=> \"42.95\"", stdout.shift
    assert_equal ">> ", stdout.shift

    stdout.shift if stdout.first =~ /Loading development environment/
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_equal ">> Product.first.updated_at_before_type_cast", stdout.shift
    assert_match /^=> "\d+-\d+-\d+ \d+:\d+:\d+(\.\d+)?"$/, stdout.shift
    assert_equal ">> ", stdout.shift
  end

  section 117, "Migration" do
    assert_select '.stderr', /near "auto_increment": syntax error/
    assert_select '.stderr', 'uninitialized constant TestDiscounts::Sku'

    stdout = css_select('.stdout').map {|tag| tag.children.join}
    stdout = stdout.select {|line| line =~ /^== / and line !~ /ing ===/}
    assert_match /CreateDiscounts: migrated/, stdout.shift
    assert_match /AddStatusToUser: migrated/, stdout.shift
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
    assert_match /AddForeignKey: migrated/, stdout.shift
    assert stdout.empty?
  end

  section 118, 'Active Record: The Basics' do
    stdout = collect_stdout
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    assert_match /^=> \[#<LineItem id: \d, product_id: 2.*\]$/, stdout.shift
    assert_match /^=> \[#<Order name: "Dave Thomas",.*\]$/, stdout.shift
    assert_equal "=> #<Order name: \"Dave Thomas\", pay_type: \"check\">", stdout.shift
    assert_equal "{\"name\"=>\"Dave Thomas\", \"pay_type\"=>\"check\"}", stdout.shift
    assert_match /^=> (nil|\{"name")/, stdout.shift
    assert_equal "[\"name\", \"pay_type\"]", stdout.shift
    assert_match /^=> (nil|\["name")/, stdout.shift
    assert_equal "false", stdout.shift
    assert_match /^=> (nil|false)/, stdout.shift
    assert_match /^#<ActiveRecord::Relation/, stdout.shift
    assert_match /^=> (nil|#<ActiveRecord::Relation)/, stdout.shift
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
    assert_match /^=> \d/, stdout.shift
    assert_match /^=> \d/, stdout.shift
    assert_match /^=> #<Product id: 4, title: "Programming Ruby"/, stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: 4/, stdout.shift
    assert_match /^=> \[#<LineItem id: \d, product_id: 4/, stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: 4/, stdout.shift
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
    assert_match /^=> \[#<LineItem id: \d, product_id: 5/, stdout.shift
    assert_equal "1", stdout.shift
    assert_match /^=> (nil|1)/, stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_match /^=> (nil|9)/, stdout.shift
    assert_equal "=> 9", stdout.shift
    assert_equal "9", stdout.shift
    assert_match /^=> (nil|9)/, stdout.shift
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    assert_match /^=> #<Name:0x\w+ @.*?last="Eisenhower"/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_match /^=> #<Customer id: 1/, stdout.shift
    assert_equal "Dwight", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Dwight D Eisenhower", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> #<Name:0x\w+ @.*?last="Truman"/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert stdout.empty?
  end

  section 119, 'Active Record: Relationships Between Tables' do
    stdout = collect_stdout
    stdout.reject! {|line| line =~ /' -> `vendor\/plugins\//}
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    assert_match /^=> Product\(.*\)$/, stdout.shift
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
    assert_match /^=> #<LineItem id: \d, product_id: 1, order_id: nil, quantity: nil, unit_price: nil>/, stdout.shift
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
    assert_match /^=> #<LineItem id: \d, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>/, stdout.shift
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
    assert_match /^=> #<LineItem id: \d, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>/, stdout.shift
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
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_match /^=> #<Logger:.*>$/, stdout.shift
    assert_equal "-- create_table(:people, {:force=>true})", stdout.shift
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
    assert_match /^=> (nil|#<Manager)/, stdout.shift
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "-- create_table(:employees, {:force=>true})", stdout.shift
    assert_match /^   -> \d+\.\d+s$/, stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_match /^=> Employee\(.*\)$/, stdout.shift
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
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_match /^=> Parent\(.*\)/, stdout.shift
    assert_match /^=> Child\(.*\)/, stdout.shift
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    assert_match /^=> Product\(.*\)$/, stdout.shift
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
    assert_match /^=> #<LineItem id: \d, product_id: 2, order_id: nil, quantity: nil, unit_price: nil>/, stdout.shift
    assert_equal "In memory size = 0", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "Refreshed size = 1", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert stdout.empty?
  end

  section 120, 'Active Record: Object Life Cycle' do
    stdout = collect_stdout
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
    assert_match /^=> \[.*\]$/, stdout.shift
    assert_equal "=> true", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> [\"PP\"]", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> []", stdout.shift
    assert_equal "=> nil", stdout.shift
    assert_equal "=> 1", stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: 27/, stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: nil/, stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: nil/, stdout.shift
    assert_match /^=> #<LineItem id: \d, product_id: 27/, stdout.shift
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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
    stdout.shift if stdout.first == "Switch to inspect mode."
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

  section 121, "Action Controller: Routing and URLs" do
    assert_select '.stdout', /^ \s*
      edit_article_comment \s GET \s+
      \/articles\/:article_id\/comments\/:id\/edit (\(.:format\))? \s+
      ( \{:controller=&gt;"comments", \s :action=&gt;"edit"\} |
      \{:action=&gt;"edit", \s :controller=&gt;"comments"\} ) $
    /x
    assert_select '.stdout', /5 tests, 29 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /1 tests, 1 assertions, 0 failures, 0 errors/
  end

  section 121.2, 'Routing Requests' do
    stdout = collect_stdout.grep(/^=>/).map {|line| sort_hash(line)}
    assert_equal '=> true', stdout.shift
    stdout.shift if stdout.first == '=> nil'
    assert_match /^=> (nil|\[.*?\])/, stdout.shift
    assert_match /^=> (nil|\[.*?\])/, stdout.shift
    assert_match /^=> #<Action\w+::Routing::RouteSet:.*>/, stdout.shift
    assert_match /^=> #<Action\w+::Integration::Session:.*>/, stdout.shift
    assert_equal '=> nil', stdout.shift
    assert_equal '=> {:action=>"index", :controller=>"store"}', stdout.shift
    assert_equal '=> {:action=>"add_to_cart", :controller=>"store", :id=>"1"}', stdout.shift
    assert_equal '=> {:action=>"add_to_cart", :controller=>"store", :format=>"xml", :id=>"1"}', stdout.shift
    assert_equal '=> "/store"', stdout.shift
    assert_equal '=> "/store/index/123"', stdout.shift
    assert_equal '=> {:action=>"show", :controller=>"coupon", :id=>"1"}', stdout.shift
    assert_equal '=> []', stdout.shift
    assert_equal '=> {:action=>"show", :controller=>"coupon", :id=>"1"}', stdout.shift
    assert_equal '=> "http://www.example.com/store/display/123"', stdout.shift
    assert_equal '=> false', stdout.shift
    assert_equal '=> true', stdout.shift
    stdout.shift if stdout.first == '=> nil'
    assert_equal '=> ["article", "blog"]', stdout.shift
    assert_match /^=> #<Action\w+::Routing::RouteSet:.*>/, stdout.shift
    assert_match /^=> #<Action\w+::Integration::Session:.*>/, stdout.shift
    assert_match /^=> #<Rack::Mount::RouteSet.*>/, stdout.shift
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

  section 123.3, 'Helpers for Formatting, Linking, and Pagination' do
    assert_select '.stdout', /^==  CreateUsers: migrated/
    assert_select '.stdout', '=&gt; 763'
    assert_select "a[href=http://localhost:#{$PORT}/pager/user_list?page=27]", '27'
  end

  section 123.5, 'Forms That Wrap Model Objects' do
    assert_select "input[name='product[price]'][value=0.0]"
    assert_select 'option[selected=selected]', 'United States'
    assert_select 'input[id=details_sku]'
  end

  section 123.6, 'Custom Form Builders' do
    assert_select "textarea[id=product_description]"
  end

  section 123.7, 'Working with Nonmodel Fields' do
    assert_select "input[id=arg1]"
  end

  section 123.8, 'Uploading Files to Rails Applications' do
    assert_select "input[id=picture_uploaded_picture][type=file]"
  end

  section 123.9, 'Layouts and Components' do
    assert_select "hr"
  end

  section 123.11, 'Adding New Templating Systems' do
    next if ActiveSupport::VERSION::STRING == '2.2.2'
    assert_select "em", 'real'
    assert_select ".body", /(over|almost) \d+ years/u
    assert_select ".body", /request\.path =(>|&gt;) \/test\/example1/u
    assert_select ".body", /a \+ b =(>|&gt;) 3/u
  end

  section 125.1, "Sending E-mail" do
    assert_select 'pre', /Thank you for your recent order/
    assert_select 'pre', /1 x Programming Ruby, 2nd Edition/
    assert_select '.body', 'Thank you...'
    assert_select '.stdout', /2 tests, 4 assertions, 0 failures, 0 errors/
    assert_select '.stdout', /1 tests, 5 assertions, 0 failures, 0 errors/
  end
end

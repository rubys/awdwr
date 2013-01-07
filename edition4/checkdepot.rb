require 'rubygems'
require 'gorp/test'

$rails_version = `#{Gorp.which_rails($rails)} -v 2>#{DEV_NULL}`.split(' ').last

class DepotTest < Gorp::TestCase

  input 'makedepot'
  output 'checkdepot'

  turn = File.read("#{$WORK}/Gemfile.lock").scan(/turn \((.*?)\)/).flatten.first
  if turn.to_s > '0.8.2'
    def assert_test_summary(selector, hash)
      hash[:pass] = hash[:tests]
      hash[:pass] -= hash[:fail] if hash[:fail]
      hash.default = 0
      test="pass: #{hash[:pass]}, fail: #{hash[:fail]}, error: #{hash[:error]}"
      assert_select selector, Regexp.new(test.gsub(' ', '\s+')), test
      test="total: #{hash[:tests]} tests with #{hash[:assertions]} assertions"
      assert_select selector, Regexp.new(test.gsub(' ', '\s+')), test
    end
  else
    def assert_test_summary(selector, hash)
      hash.default = 0
      test = "#{hash[:tests]} tests, #{hash[:assertions]} assertions, " +
        "#{hash[:fail]} failures, #{hash[:error]} errors"
      assert_select selector, Regexp.new(test), test
    end
  end

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
    ticket 7372,
      :list => :rails,
      :title =>  "Rack HEAD CookieStore security warnings",
      :match => /SECURITY WARNING: No secret option provided to Rack::Session::Cookie\./
    assert_select '.stderr', :minimum => 0 do |errors|
      errors.each do |err|
        assert_match /\d+ tests, \d+ assertions, 0 failures, 0 errors/, err.to_s
      end
    end

    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=CoffeeScript]'
    assert_select "a[href=http://localhost:#{$PORT}/products/1]", 'redirected'
    assert_test_summary 'pre', :tests => '[01]', :assertions => '[01]'
    assert_test_summary 'pre', :tests => 7, :assertions => '1[03]'
  end

  section 6.2, "Iteration A2: Prettier Listings" do
    assert_select '.list_line_even'
  end

  section 6.3, "Playtime" do
    # assert_select '.stdout', /CreateProducts: reverted/
    # assert_select '.stdout', /CreateProducts: migrated/
    assert_select '.stdout', /user.email/
    assert_select '.stdout', /Initialized empty Git repository/
    assert_select '.stdout', /(Created initial |root-)commit.*Depot Scaffold/
  end

  section 7.1, "Iteration B1: Validation and Unit Testing" do
    assert_select 'h2', /4 errors\s+prohibited this product from being saved/
    assert_select 'li', "Image url can't be blank"
    assert_select 'li', 'Price is not a number'
    assert_select '.field_with_errors input[id=product_price]'
    assert_test_summary 'pre', :tests => '[01]', :assertions => '[01]'
    assert_test_summary 'pre', :tests => 7, :assertions => '1[03]'
  end

  section 7.2, 'Iteration B2: Unit Testing' do
    assert_test_summary 'pre', :tests => 5, :assertions => 23
  end

  section 8.1, "Iteration C1: Create the Catalog Listing" do
    assert_select 'p', 'Find me in app/views/store/index.html.erb'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '36.0'
  end

  section 8.2, "Iteration C2: Add a Page Layout" do
    assert_select '#banner', /Pragmatic Bookshelf/
  end

  section 8.3, "Iteration C3: Use a Helper to Format the Price" do
    assert_select 'span.price', '$36.00'
  end

  section 8.4, "Iteration C4: Functional Testing" do
    assert_select 'pre', :tests => 5, :assertions => 23,
      :failures => 0, :errors => 0
    assert_select 'pre', :tests => 8, :assertions => 11,
      :failures => 0, :errors => 0
    assert_select 'pre', :tests => 8, :assertions => 15,
      :failures => 0, :errors => 0
  end

  section 9.2, "Connection Products to Carts" do
    assert_select 'pre', :tests => 22, :assertions => 35,
      :failures => 0, :errors => 0
  end

  section 9.3, "Iteration D3: Adding a button" do
    assert_select 'input[type=submit][value=Add to Cart]'
    assert_select "a[href=http://localhost:#{$PORT}/carts/1]", 'redirected'
    assert_select '#notice', 'Line item was successfully created.'
    assert_select 'li', 'Programming Ruby 1.9'
  end

  section 9.4, "Playtime" do
    assert_select 'pre', :tests => 5, :assertions => 23,
      :failures => 0, :errors => 0
    assert_select 'pre', :tests => 22, :assertions => 35,
      :failures => 0, :errors => 0
  end

  section 10.1, "Iteration E1: Creating A Smarter Cart" do
    assert_select 'li', /3 (.|&#?\w+;) Programming Ruby 1.9/u
    if $rails_version =~ /^3\./
      assert_select 'pre', /Couldn't find Cart with ID=wibble/i
    else
      assert_select 'h2', /Couldn't find Cart with ID=wibble/i
    end
  end

  section 10.2, "Iteration E2: Handling Errors" do
    assert_select "a[href=http://localhost:#{$PORT}/]", 'redirected'
    assert_select '.hilight', 'Attempt to access invalid cart wibble'
    assert_select '#notice', 'Invalid cart'
  end

  section 10.3, "Iteration E3: Finishing the Cart" do
    assert_select '#notice', 'Your cart is currently empty'
    assert_select '.total_cell', '$121.95'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 10.4, "Playtime" do
    assert_test_summary 'pre', :tests => '\d', :assertions => '2\d'
    assert_test_summary 'pre', :tests => 23, :assertions => '[34]7'
    assert_select '.stdout', /AddPriceToLineItem: migrated/
  end

  section 11.1, "Iteration F1: Moving the Cart" do
    assert_select 'h2', 'Your Cart'
    assert_select '.total_cell', '$121.95'
    assert_select 'input[type=submit][value=Empty cart]'
  end

  section 11.4, "Iteration F4: Hide an Empty Cart" do
    assert_select '#cart[style=display: none]'
    assert_select '.total_cell', '$171.90'
  end

  section 11.6, "Testing AJAX changes" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_test_summary 'pre', :tests => '[78]', :assertions => '2\d'
    assert_select 'code', "undefined method `line_items' for nil:NilClass"
    assert_test_summary 'pre', :tests => '2\d', :assertions => '[45]\d'
  end

  section 12.1, "Iteration G1: Capturing an Order" do
    assert_select 'input[type=submit][value=Place Order]'
    assert_select 'h2', /4 errors\s+prohibited this order from being saved/
    assert_select '#notice', 'Thank you for your order.'
  end

  section 12.2, "Iteration G2: Atom Feeds" do
    ticket 7910,
      :title =>  "Actions defined using resource get bypass the controller",
      :match => /undefined method `title&amp;#39; for nil:NilClass/

    # atom
    assert_select '.stdout', /&lt;summary type="xhtml"&gt;/,
      'Missing <summary type="xhtml">'
    assert_select '.stdout', /&lt;td&gt;CoffeeScript&lt;\/td&gt;/,
      'Missing <td>CoffeeScript</td>'

    # caching
    assert_select '.stdout', /304 Not Modified/
    assert_select '.stdout', /Etag:/i
  end

  section 12.4, "Playtime" do
    ticket 7910,
      :title =>  "Actions defined using resource get bypass the controller",
      :match => /undefined method `title&amp;#39; for nil:NilClass/

    # raw xml
    assert_select '.stdout', /&lt;email&gt;customer@example.com&lt;\/email&gt;/,
      'Missing <email>customer@example.com</email>'
    assert_select '.stdout', /&lt;id type="integer"&gt;1&lt;\/id&gt;/,
      'Missing <id type="integer">2</id>'

    # html
    assert_select '.stdout', /&lt;a href="mailto:customer@example.com"&gt;/,
      'Missing <a href="mailto:customer@example.com">'

    # json
    assert_select '.stdout', /[{,] ?"title": ?"CoffeeScript"[,}]/,
      'Missing "title": "CoffeeScript"'

    # custom xml
    assert_select '.stdout', /&lt;order_list for_product=.*&gt;/,
      'Missing <order_list for_product=.*>'

    # test clean
    assert_test_summary 'pre', :tests => '[79]', :assertions => '[23]\d'
    assert_test_summary 'pre', :tests => '3\d', :assertions => '[456]\d'
  end

  section 13.1, "Iteration H1: Email Notifications" do
    assert_test_summary 'pre', :tests => 2, :assertions => '(8|10)'
  end

  section 13.2, "Iteration H2: Integration Tests" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    ticket 4213,
      :title =>  "undefined method `named_routes' in integration test",
      :match => /NoMethodError: undefined method `named_routes' for nil:NilClass/
    assert_test_summary 'pre', :tests => 3, :assertions => '\d+'
  end

  section 14.1, "Iteration I1: Adding Users" do
    unless $rails_version =~ /^3\.[012]/
      ticket 6614, :match => /user, confirm: /,
        :title =>  "Remove `:confirm` in favor of " +
          "`:data => { :confirm => 'Text' }` option"
    end
    assert_select 'legend', 'Enter User Details'
    # assert_select 'td', 'User dave was successfully created.'
    assert_select 'h1', 'Listing users'
    assert_select 'td', 'dave'
  end

  section 14.2, "Iteration I2: Authenticating Users" do
    assert_select 'h1', 'Welcome'
    assert_test_summary 'pre', :tests => 47, :assertions => '[789]\d'
  end

  section 14.3, "Iteration I3: Limiting Access" do
    assert_test_summary 'pre', :tests => 47, :assertions => '[789]\d'
  end

  section 14.4, "Iteration I4: Adding a Sidebar" do
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
    assert_select "a[href=http://localhost:#{$PORT}/login]", 'redirected'
    assert_select 'h1', 'Listing products'
  end

  section 14.5, "Playtime" do
    ticket 7910,
      :title =>  "Actions defined using resource get bypass the controller",
      :match => /undefined method `title&amp;#39; for nil:NilClass/

    assert_test_summary 'pre', :tests => '4[68]', :assertions => '[789]\d'

    assert_select '.stdout', /login"&gt;redirected/
    assert_select '.stdout', /customer@example.com/
  end

  section 15.1, "Task J1: i18n for the store front" do
    unless $rails_version =~ /^3\./
      assert_select 'td', /store_path/
      assert_select 'td', /\(:locale\)\(\.:format\)/
      assert_select 'td', /store#index/
    end
    assert_select '#notice', 'es translation not available'
  end

  section 15.2, "Task J2: i18n for the cart" do
    assert_select '.price', /49,95(.|&#?\w+;)\$US/u
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_select 'input[type=submit][value$=dir al Carrito]'
    assert_select 'td', /1(.|&#?\w+;)/u
    assert_select 'td', 'CoffeeScript'
  end

  section 15.3, "Task J3: i18n for the order page" do
    # ticket 5971,
    #   :title =>  "labels don't treat I18n name_html as html_safe",
    #   :match => /Direcci&amp;oacute;n/
    # ticket 5971,
    #   :title =>  "labels don't treat I18n name_html as html_safe",
    #   :match => /&lt;span class=&quot;translation_missing&quot;&gt;/

    assert_select 'input[type=submit][value$=Comprar]'
    assert_select '#error_explanation',
      /4 errores han impedido que este pedido se guarde/
    assert_select '#notice', 'Gracias por su pedido'
  end

  section 15.4, "Task J4: Add a locale switcher" do
    ticket 4786,
      :title =>  "render with a partial in rjs fails ",
      :match => /Template::Error: Missing partial.* with.* :formats=&gt;\[:js\]/

    assert_select 'option[value=es]'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_test_summary 'pre', :tests => '1?\d', :assertions => '[23]\d'
    assert_test_summary 'pre', :tests => 48, :assertions => '[789]\d'
    assert_test_summary 'pre', :tests => 3, :assertions => '\d+'
  end

  section 16, "Deployment" do
    assert_select '.stderr', /depot_production('; database| already) exists/
    assert_select '.stdout', /initialize_schema_migrations_table/
    assert_select '.stdout', '[done] capified!'
    assert_select '.stdout', /depot\/log\/production.log/
    assert_select '.stderr', :text => /:\d+:in `.*'$/, :count => 0
  end

  section 18, "Finding Your Way Around" do
    assert_select '.stdout', /Current version: \d{8}000009/
  end

  if $rails_version =~ /^3\./
    section 20.1, "Testing Routing" do
      assert_test_summary 'pre', :tests => '1\d', :assertions => '4\d'
    end
  end

  section 21.1, "Views" do
    assert_select '.stdout', /&lt;price currency="USD"&gt;49.95&lt;\/price&gt;/
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

  if $rails_version =~ /^3\./
    section 24.3, "Active Resources" do
      # assert_select '.stdout', /ActiveResource::Redirection: Failed.* 302/
      assert_select '.stdout', '36.0'
      assert_select '.stdout', '=&gt; true'
      assert_select '.price', '$31.00'
      assert_select 'p', /31\.0/
      assert_select '.stdout', '=&gt; "Dave Thomas"'
      assert_select '.stdout', /NoMethodError: undefined method `line_items'/
      if File.exist? "#{$WORK}/depot/public/images"
        assert_select '.stdout', /&lt;id type="integer"&gt;\d+&lt;\/id&gt;/
      else
        assert_select '.body', /[{,]"id":\d+[,}]/
      end
      assert_select '.stdout', /"product_id"=&gt;2/
      assert_select '.stdout', /=&gt; 28.8/
    end
  end

  section 25.1, 'rack' do
    assert_select 'p', '34.95'
    assert_select 'h2', 'Programming Ruby 1.9'
  end

  section 25.2, 'rake' do
    assert_select '.stderr', /^mkdir -p .*db\/backup$/
    assert_select '.stderr', 
      /^sqlite3 .*?db\/production\.db \.dump &gt; .*\/production.backup$/
  end

  section 26.1, 'Active Merchant' do
    ticket 477,
      :list => 'activemerchant',
      :title =>  "prepping for Rails 4.0",
      :match => /cannot load such file -- active_support\/core_ext\/object\/conversions/
    assert_select '.stdout', 'Is 4111111111111111 valid?  false'
  end

  if File.exist? 'public/images'
    section '26.1.2', 'Asset Packager' do
      assert_select '.stdout', 'config/asset_packages.yml example file created!'
      assert_select '.stdout', '  - depot'
      assert_select '.stdout', 
        /Created .*\/public\/javascripts\/base_packaged\.js/
    end
  end

  section 26.2, 'HAML' do
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', /\$3[16].00/
  end

  if File.exist? 'public/images'
    section '26.1.4', 'JQuery' do
      assert_select '.logger', /force\s+public\/javascripts\/rails\.js/
      assert_select '.stdout', /No RJS statement/
      assert_select '.stdout', /4\d tests, 7\d assertions, 0 failures, 0 errors/
    end
  end

  section 26.3, "Iteration G3: Pagination" do
    assert_select 'td', 'Customer 100'
    assert_select "a[href=http://localhost:#{$PORT}/en/orders?page=4]"
  end
end

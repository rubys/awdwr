require 'bundler/setup'

begin
  require 'minitest'
rescue LoadError
end

require 'gorp/test'

$rails_version = `#{Gorp.which_rails($rails)} -v 2>#{DEV_NULL}`.split(' ').last

class DepotTest < Gorp::TestCase

  self.test_order ||= :sorted

  input 'makedepot'
  output 'checkdepot'

  turn = (File.read("#{$WORK}/Gemfile.lock") rescue '').
    scan(/turn \((.*?)\)/).flatten.first 

  if turn.to_s > '0.8.2'
    def assert_test_summary(hash)
      hash[:pass] = hash[:tests]
      hash[:pass] -= hash[:fail] if hash[:fail]
      hash.default = 0
      test="pass: #{hash[:pass]}, fail: #{hash[:fail]}, error: #{hash[:error]}"
      assert_select 'pre', Regexp.new(test.gsub(' ', '\s+')), test
      test="total: #{hash[:tests]} tests with #{hash[:assertions]} assertions"
      assert_select 'pre', Regexp.new(test.gsub(' ', '\s+')), test
    end
  else
    def assert_test_summary(hash)
      hash.default = 0
      test = "#{hash[:tests]} (tests|runs), " +
        "#{hash[:assertions]} assertions, " +
        "#{hash[:fail]} failures, #{hash[:error]} errors"
      assert_select 'pre', Regexp.new(test), test
    end
  end

  section 2, 'Instant Gratification' do
    ticket 4147,
      :title =>  "link_to generates incorrect hrefs",
      :match => /say\/hello\/say\/goodbye/

    assert_select 'h1', 'Hello from Rails!'
    assert_select "p", 'Find me in app/views/say/hello.html.erb'
    assert_select "a[href='http://localhost:#{$PORT}/say/goodbye']"
    assert_select "a[href='http://localhost:#{$PORT}/say/hello']"
    if RUBY_VERSION =~ /^1.8/
      assert_select 'p', /^It is now \w+ \w+ \d\d \d\d:\d\d:\d\d [+-]\d+ \d+/
    else
      assert_select 'p', /^It is now \d+-\d\d-\d\d \d\d:\d\d:\d\d [+-]\d+/
    end

    assert_select 'h2', /undefined method `know' for Time:Class/
    assert_select 'h2', 'No route matches [GET] "/say/hullo"'
  end

  section 6.1, 'Iteration A1: Creating the Products Maintenance Application' do
    ticket 628,
      list:  'turbolinks',
      title: 'Turbolinks: why is v3.0 not out yet?',
      match: /DEPRECATION WARNING: alias_method_chain is deprecated./

    assert_select '.stderr', :minimum => 0 do |errors|
      next if Gorp::Config[:ignore_deprecations]
      errors.each do |err|
        assert_match /\d+ (test|run)s, \d+ assertions, 0 failures, 0 errors/,
          err.to_s
      end
    end

    assert_select 'th', 'Image url'
    assert_select 'input#product_title[value=CoffeeScript]'
    assert_select "a[href='http://localhost:#{$PORT}/products/1']", 'redirected'
    if $rails_version =~ /^3/
      assert_test_summary :tests => '[01]', :assertions => '[01]'
      assert_test_summary :tests => 7, :assertions => '1[03]'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 7, :assertions => 13
    else
      assert_test_summary :tests => 7, :assertions => 12
    end
  end

  section 6.2, "Iteration A2: Prettier Listings" do
    unless $rails_version =~ /^4.2/
#     ticket 321,
#       list:  'sprockets-rails',
#       title: 'Adding new images requires a server restart in development',
#       match: /Workaround for sprockets-rails issue 321/
    end

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
    ticket 23590,
      title: "most validations fail",
      match: /Product was successfully created\./

    assert_select 'h2', /4 errors\s+prohibited this product from being saved/
    assert_select 'li', "Image url can't be blank"
    assert_select 'li', 'Price is not a number'
    assert_select '.field_with_errors input[id=product_price]'
    if $rails_version =~ /^3/
      assert_test_summary :tests => '[01]', :assertions => '[01]'
      assert_test_summary :tests => 7, :assertions => '1[03]'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 7, :assertions => 13
    else
      assert_test_summary :tests => 7, :assertions => 12
    end
  end

  section 7.2, 'Iteration B2: Unit Testing' do
    assert_test_summary :tests => 5, :assertions => 23
  end

  section 8.1, "Iteration C1: Create the Catalog Listing" do
    assert_select 'p', 'Find me in app/views/store/index.html.erb'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'span.price', '45.0'
  end

  section 8.2, "Iteration C2: Add a Page Layout" do
    assert_select '#banner img[alt="The Pragmatic Bookshelf"]'
  end

  section 8.3, "Iteration C3: Use a Helper to Format the Price" do
    assert_select 'span.price', '$45.00'
  end

  section 8.4, "Iteration C4: Functional Testing" do
    if $rails_version =~ /^3/
      assert_test_summary :tests => 5, :assertions => 23
      assert_test_summary :tests => 8, :assertions => 11
      assert_test_summary :tests => 8, :assertions => 15
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 13, :assertions => 37
    else
      assert_test_summary :tests => 13, :assertions => 36
      assert_test_summary :tests => 8, :assertions => 17
    end
  end

  section 9.2, "Connection Products to Carts" do
    ticket 23314,
      list:  'rails',
      title: 'generate scaffold with no fields generates a broken controller test',
      match: /ArgumentError: When assigning attributes, you must pass a hash as an argument./
    ticket 23384,
      list:  'rails',
      title: 'generate scaffold with only ref fields generates a broken controller test',
      match: /"LineItem.count" didn't change by 1./

    if $rails_version =~ /^3/
      assert_test_summary :tests => 22, :assertions => 35
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 23, :assertions => 47
    else
      assert_test_summary :tests => 23, :assertions => 44
    end
  end

  section 9.3, "Iteration D3: Adding a button" do
    assert_select 'input[type=submit][value="Add to Cart"]'
    assert_select "a[href='http://localhost:#{$PORT}/carts/1']", 'redirected'
    assert_select '#notice', 'Line item was successfully created.'

    assert_select 'li', /^Seven Mobile Apps in Seven Weeks$/
  end

  section 9.4, "Playtime" do
    if $rails_version =~ /^3\./
      assert_test_summary :tests => '[57]', :assertions => '2\d'
      assert_test_summary :tests => 7, :assertions => 10
    elsif $rails_version =~ /^4\./
      assert_test_summary :tests => 7, :assertions => 13
    else
      assert_test_summary :tests => 7, :assertions => 12
    end
  end

  section 10.1, "Iteration E1: Creating A Smarter Cart" do
    assert_select 'li', /Rails, Angular, Postgres, and Bootstrap/u
    assert_select '#main li', :count => 4, :html => /1 .+ Seven Mobile Apps in Seven Weeks/
    assert_select '.stdout', /^=+ (\d+)? *CombineItemsInCart: reverting =+$/
    assert_select '.stdout', /^ +down +\d+ +Combine items in cart$/
    if $rails_version =~ /^3\./
      assert_select 'pre', /Couldn't find Cart with ID=wibble/i
    else
      assert_select 'h2', /Couldn't find Cart with '?id'?=wibble/i
    end
  end

  section 10.2, "Iteration E2: Handling Errors" do
    assert_select "a[href='http://localhost:#{$PORT}/']", 'redirected'
    assert_select '.hilight', 'Attempt to access invalid cart wibble'
    assert_select '#notice', 'Invalid cart'
    unless $rails_version =~ /^3\./
      assert_select '.hilight', /Unpermitted parameters?: cart_id/
      assert_select '.stdout', /^\s*0$/
    end
  end

  section 10.3, "Iteration E3: Finishing the Cart" do
    assert_select '#notice', 'Your cart is currently empty'
    assert_select '.total_cell', '$116.00'
    assert_select 'input[type=submit][value="Empty cart"]'
  end

  section 10.4, "Playtime" do
#   ticket 23386,
#     :title =>  "can't access session in ActionDispatch::IntegrationTest",
#     :match => /undefined method `session' for nil:NilClass/

    if $rails_version =~ /^3/
      assert_test_summary :tests => '\d', :assertions => '2\d'
      assert_test_summary :tests => 23, :assertions => '[34]7'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 2, :assertions => 5
      assert_test_summary :tests => 30, :assertions => 75
    else
      assert_test_summary :tests => 2, :assertions => 5
      assert_test_summary :tests => 30, :assertions => 72
    end
    assert_select '.stdout', /AddPriceToLineItem: migrated/
  end

  section 11.1, "Iteration F1: Moving the Cart" do
    assert_select 'h2', 'Your Cart'
    assert_select '.total_cell', '$116.00'
    assert_select 'input[type=submit][value="Empty cart"]'
  end

  section 11.4, "Iteration F4: Hide an Empty Cart" do
    assert_select '#cart[style="display: none"]'
    assert_select '.total_cell', '$142.00'
  end

  section 11.6, "Testing AJAX changes" do
    ticket 167,
      :list => 'jquery-rails',
      :title =>  "SelectorAssertions moved in Rails 4.2",
      :match => /NoMethodError: undefined method `assert_select_jquery' for #&lt;LineItemsControllerTest:/

    assert_select 'h2, code', "undefined method `line_items' for nil:NilClass"

    if $rails_version =~ /^3/
      assert_test_summary :tests => '[78]', :assertions => '2\d'
      assert_test_summary :tests => '2\d', :assertions => '[45]\d'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 32, :assertions => 80
    else
      assert_test_summary :tests => 32, :assertions => 77
    end
  end

  section 12.1, "Iteration G1: Capturing an Order" do
    assert_select 'input[type=submit][value="Place Order"]'
    assert_select 'h2', /4 errors\s+prohibited this order from being saved/
    assert_select '#notice', 'Thank you for your order.'
  end

  section 12.2, "Iteration G2: Atom Feeds" do
    ticket 7910,
      :title =>  "Actions defined using resource get bypass the controller",
      :match => /undefined method `title&amp;#39; for nil:NilClass/

    # atom
    assert_select '.stdout', /(<|&lt;)summary type="xhtml"(>|&gt;)/,
      'Missing <summary type="xhtml">'
    assert_select '.stdout', /(<|&lt;)td(>|&gt;)Rails, Angular, Postgres, and Bootstrap(<|&lt;)\/td(>|&gt;)/,
      'Missing <td>Rails, Angular, Postgres, and Bootstrap</td>'

    # caching
    assert_select '.stdout', /304 Not Modified/
    assert_select '.stdout', /Etag:/i
  end

  unless $PUB
  section 12.3, 'Iteration G3: Downloading an eBook' do
    ticket 23483,
      :title =>  "ActionController::Live locks database",
      :match => /SQLite3::BusyException/
  end
  end

  section 12.4, "Playtime" do
    next if Gorp::Config[:skip_xml_serialization]
    ticket 23503,
      :list => 'rails',
      :title =>  "ActionController::Live causes requests to hang",
      :match => />curl.*<\/pre>\s*<p class="note">/

    # raw xml
    assert_select '.stdout', /(<|&lt;)email(>|&gt;)customer@example.com(<|&lt;)\/email(>|&gt;)/,
      'Missing <email>customer@example.com</email>'
    assert_select '.stdout', /(<|&lt;)id type="integer"(>|&gt;)1(<|&lt;)\/id(>|&gt;)/,
      'Missing <id type="integer">2</id>'

    # html
    assert_select '.stdout', /(<|&lt;)a href="mailto:customer@example.com"(>|&gt;)/,
      'Missing <a href="mailto:customer@example.com">'

    # json
    assert_select '.stdout', /[{,] ?"title": ?"Rails, Angular, Postgres, and Bootstrap"[,}]/,
      'Missing "title": "CoffeeScript"'

    # custom xml
    assert_select '.stdout', /(<|&lt;)order_list for_product=.*(>|&gt;)/,
      'Missing <order_list for_product=.*>'

    # test clean
    if $rails_version =~ /^3/
      assert_test_summary :tests => '[79]', :assertions => '[23]\d'
      assert_test_summary :tests => '3\d', :assertions => '[456]\d'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 40, :assertions => 96
    else
      assert_test_summary :tests => 40, :assertions => 92
    end
  end

  section 13.1, "Iteration H1: Email Notifications" do
    if $rails_version =~ /^3/
      assert_test_summary :tests => 2, :assertions => '(8|10)'
    elsif $rails_version =~ /^3/
      assert_test_summary :tests => 2, :assertions => 10
    else
      assert_test_summary :tests => 2, :assertions => 10
    end
  end

  section 13.2, "Iteration H2: Integration Tests" do
    ticket 16272,
      :title =>  "assert_template w/ open_session in an integration test",
      :match => /expecting &lt;"index"&gt; but rendering with &lt;\[\]&gt;/

    if $rails_version =~ /^3/
      assert_test_summary :tests => 3, :assertions => '\d+'
    else
      assert_test_summary :tests => 3, :assertions => 47
    end
  end

  section 14.1, "Iteration I1: Adding Users" do
    ticket 23989,
      :title =>  "Delivering mail causes tests to fail",
      :match => /SQLite3::BusyException: database is locked/

    assert_select 'legend', 'Enter User Details'
    if $rails_version =~ /^[34]/
      assert_select 'h1', /Listing Users/i
    else
      assert_select 'h1', 'Users'
    end
    assert_select 'td', 'dave'
    unless $rails_version =~ /^3/
      assert_select 'p', 'User dave was successfully created.'
      if $rails_version =~ /^4/
        assert_test_summary :tests => 52, :assertions => 166
      else
        assert_test_summary :tests => 52, :assertions => 161
      end
    end
  end

  section 14.2, "Iteration I2: Authenticating Users" do
    ticket 167,
      :list => 'jquery-rails',
      :title =>  "SelectorAssertions moved in Rails 4.2",
      :match => /NoMethodError: undefined method `assert_select_jquery' for #&lt;LineItemsControllerTest:/

    assert_select 'h1', 'Welcome'
    if $rails_version =~ /^3/
      assert_test_summary :tests => 47, :assertions => '[789]\d'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 57, :assertions => 172
    else
      assert_test_summary :tests => 57, :assertions => 167
    end
  end

  section 14.3, "Iteration I3: Limiting Access" do
    ticket 167,
      :list => 'jquery-rails',
      :title =>  "SelectorAssertions moved in Rails 4.2",
      :match => /NoMethodError: undefined method `assert_select_jquery' for #&lt;LineItemsControllerTest:/

    if $rails_version =~ /^3/
      assert_test_summary :tests => 47, :assertions => '[789]\d'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 57, :assertions => 172
    else
      assert_test_summary :tests => 57, :assertions => 167
    end
  end

  section 14.4, "Iteration I4: Adding a Sidebar" do
    assert_select 'legend', 'Please Log In'
    assert_select 'input[type=submit][value=Login]'
    assert_select 'h1', 'Welcome'
    assert_select "a[href='http://localhost:#{$PORT}/login']", 'redirected'
    assert_select 'h1', 'Listing products'
  end

  section 14.5, "Playtime" do
    ticket 167,
      :list => 'jquery-rails',
      :title =>  "SelectorAssertions moved in Rails 4.2",
      :match => /NoMethodError: undefined method `assert_select_jquery' for #&lt;LineItemsControllerTest:/

    assert_test_summary :tests => '4[68]', :assertions => '[789]\d'

    assert_select '.stdout', /login"(>|&gt;)redirected/
    assert_select '.stdout', /customer@example.com/
  end

  section 15.1, "Task J1: i18n for the store front" do
    ticket 16679,
      :title => "Missing partial routes/_route",
      :match => %r{Missing partial routes/_route}

    unless $rails_version =~ /^3\./
      assert_select 'td', /store_index_path/
      assert_select 'td', /\(:locale\)\(\.:format\)/
      assert_select 'td', /store#index/
    end
    assert_select '#notice', 'es translation not available'
  end

  section 15.2, "Task J2: i18n for the cart" do
    ticket 275,
      :list => 'i18n',
      :title => "Can't set locale to something other than the default",
      :match =>  /"es" is not a valid locale/

    assert_select '.price', /45,00(.|&#?\w+;)\$US/u
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    assert_select 'input[type=submit][value$="dir al Carrito"]'
    assert_select 'td', /1(.|&#?\w+;)/u
    assert_select 'td', 'Rails, Angular, Postgres, and Bootstrap'
  end

  section 15.3, "Task J3: i18n for the order page" do
    ticket 275,
      :list => 'i18n',
      :title => "Can't set locale to something other than the default",
      :match =>  /"es" is not a valid locale/

    assert_select 'input[type=submit][value$=Comprar]'
    assert_select '#error_explanation',
      /4 errores han impedido que este pedido se guarde/
    assert_select '#notice', 'Gracias por su pedido'
  end

  section 15.4, "Task J4: Add a locale switcher" do
    ticket 167,
      :list => 'jquery-rails',
      :title =>  "SelectorAssertions moved in Rails 4.2",
      :match => /NoMethodError: undefined method `assert_select_jquery' for #&lt;LineItemsControllerTest:/


    assert_select 'option[value=es]'
    assert_select 'h1', 'Your Pragmatic Catalog'
    assert_select 'h1', /Su Cat(.|&#?\w+;)logo de Pragmatic/u
    if $rails_version =~ /^3/
      assert_test_summary :tests => '1?\d', :assertions => '[23]\d'
      assert_test_summary :tests => 48, :assertions => '[789]\d'
      assert_test_summary :tests => 3, :assertions => '\d+'
    elsif $rails_version =~ /^4/
      assert_test_summary :tests => 58, :assertions => 174
    else
      assert_test_summary :tests => 58, :assertions => 168
    end
  end

  section 16, "Deployment" do
    ticket 8837,
      :title =>  'Bring back "database already exists" messages when running rake tasks',
      :match => /Mysql2::Error.*database exists/

    assert_select '.stderr', count: 0
    assert_select '.stdout', /initialize_schema_migrations_table/
    assert_select '.stdout', '[done] capified!'
    assert_select '.stdout', /depot\/log\/production.log/
    # assert_select '.stderr', :text => /:\d+:in `.*'$/, :count => 0
  end

  section 18, "Finding Your Way Around" do
    assert_select '.stdout', /Current version: \d{8}000009/
  end

  if $rails_version =~ /^3\./
    section 20.1, "Testing Routing" do
      assert_test_summary :tests => '1\d', :assertions => '4\d'
    end
  end

  section 21.1, "Views" do
#   ticket 10984,
#     :title =>  "Live streaming doesn't work with basic authentication or builder",
#     :match => /<pre class="stdin">curl.*<\/pre>\s+<pre class="stdin">/

    assert_select '.stdout', /(<|&lt;)price currency="USD"(>|&gt;)26.0(<|&lt;)\/price(>|&gt;)/
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
      assert_select '.stdout', /=&gt; (28\.8|#&lt;BigDecimal:\w+,'0\.288E2')/
    end
  end

  section 25.1, 'rack' do
    assert_select 'p', '26.0'
    assert_select 'h2', /^Seven Mobile Apps in Seven Weeks$/
  end

  section 25.2, 'rake' do
    assert_select '.stderr', /^mkdir -p .*db\/backup$/
    assert_select '.stderr', 
      /^sqlite3 .*?db\/production\.db \.dump (>|&gt;) .*\/production.backup$/
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
    assert_select 'span.price', /\$45.00/
  end

  if File.exist? 'public/images'
    section '26.1.4', 'JQuery' do
      assert_select '.logger', /force\s+public\/javascripts\/rails\.js/
      assert_select '.stdout', /No RJS statement/
      assert_select '.stdout', /4\d tests, 7\d assertions, 0 failures, 0 errors/
    end
  end

  section 26.3, "Iteration G3: Pagination" do
    next
    next if Gorp::Config[:skip_pagination]

    ticket 774,
      :list => 'kaminari',
      :title =>  "non sanitized request parameter",
      :match => /Generating a URL from non sanitized request parameters is insecure!/
    assert_select 'td', 'Customer 100'
    assert_select "a[href='http://localhost:#{$PORT}/en/orders?page=4']"
  end
end

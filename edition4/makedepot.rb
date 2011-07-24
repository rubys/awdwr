require 'rubygems'
require 'gorp'

begin
  require './pub_gorp'
rescue LoadError
  def publish_code_snapshot *args
  end
end

include Gorp::Commands

$title = 'Agile Web Development with Rails, Edition 4'
$autorestart = 'depot'
$output = 'makedepot'
$checker = 'checkdepot'

omit 100..199

section 2, 'Instant Gratification' do
  overview <<-EOF
    We start with a simple "hello world!" demo application
    and in the process verify that everything is installed correctly.
  EOF

  desc 'Create the application'
  rails 'demo1', :work

  desc 'See what files were created'
  cmd 'ls -p'

  desc 'Create a simple controller'
  generate 'controller Say hello goodbye'
  edit 'app/controllers/say_controller.rb' do
    dcl 'hello', :highlight
  end

  ruby 'script/server'

  desc 'Attempt to fetch the file - note that it is missing'
  get '/say/hello'

  desc 'Replace file with a simple hello world'
  edit 'app/views/say/hello.html.erb' do
    self.all = <<-EOF.unindent(6)
      <h1>Hello from Rails!</h1>
    EOF
  end

  desc 'This time it works!'
  get '/say/hello'
  publish_code_snapshot :work, :demo1

  desc 'Add a simple expression'
  edit 'app/views/say/hello.html.erb' do
    clear_highlights
    msub /<\/h1>\n()/, <<-EOF.unindent(6), :highlight
      <p>
        It is now <%= Time.now %>
      </p>
    EOF
  end
  get '/say/hello'
  publish_code_snapshot :work, :demo2

  desc 'Evaluate the expression in the controller.'
  edit 'app/controllers/say_controller.rb' do
    clear_highlights
    msub /def hello\n()\s+end/, <<-EOF.unindent(2), :highlight
      @time = Time.now
    EOF
  end

  desc 'Reference the result in the view.'
  edit 'app/views/say/hello.html.erb' do
    clear_highlights
    msub /( *<p>.*<\/p>\n)/m, <<-EOF.unindent(6)
      <p>
        <!-- START_HIGHLIGHT -->
        It is now <%= @time %>
        <!-- END_HIGHLIGHT -->
      </p>
    EOF
  end
  get '/say/hello'
  publish_code_snapshot :work, :demo3

  desc 'Replace the goodbye template'
  edit 'app/views/say/goodbye.html.erb' do
    self.all = <<-EOF.unindent(6)
      <h1>Goodbye!</h1>
      <p>
        It was nice having you here.
      </p>
    EOF
  end
  get '/say/goodbye'
  publish_code_snapshot :work, :demo4

  desc 'Add a link from the hello page to the goodbye page'
  edit 'app/views/say/hello.html.erb' do
    clear_highlights
    msub /<\/p>\n()/, <<-EOF.unindent(6), :highlight
      <p>
        Time to say
        <%= link_to "Goodbye", say_goodbye_path %>!
      </p>
    EOF
  end
  get '/say/hello'

  desc 'Add a link back to the hello page'
  edit 'app/views/say/goodbye.html.erb' do
    msub /<\/p>\n()/, <<-EOF.unindent(6), :highlight
      <p>
        Say <%= link_to "Hello", say_hello_path %> again.
      </p>
    EOF
  end
  get '/say/goodbye'
  publish_code_snapshot :work, :demo5
end

section 6.1, 'Iteration A1: Creating the Products Maintenance Application' do
  overview <<-EOF
    This section mostly covers database configuration options for those
    users that insist on using MySQL.  SQLite3 users will skip most of it.
  EOF

  desc 'Create the application.'
  ENV.delete('BUNDLE_GEMFILE')
  rails 'depot', :a

  desc 'Look at the files created.'
  cmd 'ls -p'

  desc 'Database configuration options (generally not required for sqlite3)'
  cmd 'cat config/database.yml'

  overview <<-EOF
    Generate scaffolding for a real model, modify a template, and do
    our first bit of data entry.
  EOF

  desc 'Generating our first model and associated scaffolding'
  generate :scaffold, :Product,
    'title:string description:text image_url:string price:decimal'

  desc 'Break lines for formatting reasons'
  edit 'app/controllers/products_controller.rb' do
    dcl 'create' do
      msub /,( ):?notice/, "\n          "
      msub /,( ):?location/, "\n          "
      msub /,( ):?status:? ?=?>? :un/, "\n          "
    end
    dcl 'update' do
      msub /,( ):?notice/, "\n          "
      msub /,( ):?status:? ?=?>? :un/, "\n          "
    end
  end

  edit 'app/views/products/index.html.erb' do
    msub /,( ):?method/, "\n            "
  end

  restart_server

  desc 'Add precision and scale to the price'
  edit Dir['db/migrate/*create_products.rb'].first do
    up = (include?('self.up') ? 'self.up' : 'change')
    dcl up, :mark=>'up' do
      edit 'price', :highlight do
        if RUBY_VERSION =~ /^1\.8/
          self << ', :precision => 8, :scale => 2'
        else
          self << ', precision: 8, scale: 2'
        end
      end
    end
  end

  desc 'Apply the migration'
  cmd 'rake db:migrate'

  desc 'Get an (empty) list of products'
  get '/products'

  desc 'Show (and modify) one of the templates produced'
  edit 'app/views/products/_form.html.erb' do
    msub /<%= pluralize.*%>( )/, "\n      "
    edit 'text_area :description', :highlight do
      if RUBY_VERSION =~ /^1\.8/
        msub /:description() %>/, ', :rows => 6'
      else
        msub /:description() %>/, ', rows: 6'
      end
    end
  end

  desc 'Create a product'
  post '/products/new',
    'product[title]' => 'Web Design for Developers',
    'product[description]' => <<-EOF.unindent(6),
      <p>
        <em>Web Design for Developers</em>
        will show you how to make your
        web-based application look
        professionally designed. We'll help
        you learn how to pick the right
        colors and fonts, avoid costly
        interface and accessibility mistakes
        -- your application will really come
        alive.  We'll also walk you through
        some common Photoshop and CSS
        techniques and work through a web site
        redesign, taking a new design from
        concept all the way to implementation.
      </p>
    EOF
    'product[price]' => '42.95',
    'product[image_url]' => 
      (File.exist?('public/images') ? '/images/wd4d.jpg' : 'wd4d.jpg')

  desc 'Verify that the product has been added'
  get '/products'

  desc "And, just to verify that we haven't broken anything"
  cmd 'rake test'
  publish_code_snapshot :a
end

section 6.2, 'Iteration A2: Making Prettier Listings' do
  overview <<-EOF
    Show the relationship between various artifacts: seed data,
    stylesheets, html, and images.
  EOF

  desc 'Load some "seed" data'
  edit "db/seeds.rb", 'vcc' do |data|
    data.all = read('products/seeds.rb')
    data.gsub! '/images/', '' unless File.exist? 'public/images'
    data.gsub! /:(\w+) =>/, '\1:' unless RUBY_VERSION =~ /^1\.8/
  end
  cmd 'rake db:seed'

  desc 'Link to the stylesheet in the layout'
  edit 'app/views/layouts/application.html.erb' do |data|
    data.clear_highlights
    data.edit '<body>', :highlight
    data.msub /<body()>/, " class='<%= controller.controller_name %>'"
  end

  desc 'Copy some images and a stylesheet'
  if File.exist? 'public/images'
    cmd "cp -v #{$DATA}/images/* public/images/"
    cmd "cp -v #{$DATA}/depot.css public/stylesheets"
    DEPOT_CSS = "public/stylesheets/depot.css"
  else
    cmd "cp -v #{$DATA}/assets/* app/assets/images/"
    cmd "cp -v #{$DATA}/products.css.scss app/assets/stylesheets"
    DEPOT_CSS =  "app/assets/stylesheets/application.css.scss"
  end

  desc 'Replace the scaffold generated view with some custom HTML'
  edit 'app/views/products/index.html.erb' do
    self.all = read('products/index.html.erb')
    if DEPOT_CSS =~ /scss/
      sub!(/<div.*?>\n(.*?)<\/div>\n/m) { $1.gsub /^  /,'' }
    end
    gsub! /:(\w+) =>/, '\1:' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'See the finished result'
  get '/products'
end

section 6.3, 'Playtime' do
  overview <<-EOF
    Configuration management using Git.
  EOF

  # desc 'Roll back a migration.'
  # cmd 'rake db:rollback'

  # desc 'Reapply migration.'
  # cmd 'rake db:migrate'

  desc 'Configure Git.'
  cmd 'git repo-config --get-regexp user.*'

  desc 'Look at the .gitignore that Rails helpfully provided...'
  cmd 'cat .gitignore'
  
  desc 'Initialize repository.'
  cmd 'git init'

  desc 'Add all the files.'
  cmd 'git add .'

  desc 'Initial commit.'
  cmd 'git commit -m "Depot Scaffold"'
end

section 7.1, 'Iteration B1: Validate!' do
  overview <<-EOF
    Augment the model with a few vailidity checks.
  EOF

  desc 'Various validations: required, numeric, positive, and unique'
  edit 'app/models/product.rb' do |data|
    data.msub /class Product.*\n()/, <<-'EOF'.unindent(6)
      #START:validation
      #START:val1
        validates :title, :description, :image_url, :presence => true
      #END:val1
      #START:val2
        validates :price, :numericality => {:greater_than_or_equal_to => 0.01}
      #END:val2
      # #START:val3
        validates :title, :uniqueness => true
      #END:val3
      #START:val4
        validates :image_url, :allow_blank => true, :format => {
          :with    => %r{\.(gif|jpg|png)$}i,
          :message => 'must be a URL for GIF, JPG or PNG image.'
        }
      #END:val4
      #END:validation
    EOF
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Demonstrate failures.'
  post '/products/new',
    'product[price]' => '0.0'

  desc 'Demonstrate more failures.'
  post '/products/new',
    'product[title]' => 'Pragmatic Unit Testing',
    'product[description]' => <<-EOF.unindent(6),
      A true masterwork.  Comparable to Kafka at
      his funniest, or Marx during his slapstick
      period.  Move over, Tolstoy, there's a new
      funster in town.
    EOF
    'product[image_url]' => 
      (File.exist?('public/images') ? '/images/utj.jpg' : 'utj.jpg'),
    'product[price]' => 'wibble'

  edit 'app/models/product.rb' do |data|
    data.sub! /\s:allow_blank.*,/, ''
    data.sub! /0.00/,  '0.01'
  end

  publish_code_snapshot :b
end

section 7.2, 'Iteration B2: Unit Testing' do
  overview <<-EOF
    Introduce the importance of unit testing.
  EOF

  desc 'Look at what files are generated'
  cmd 'ls test/unit'

  desc 'Add a fixture.'
  edit "test/fixtures/products.yml" do
    msub /.*\n()/m, "\n" + <<-EOF.unindent(6), :mark => 'ruby'
      ruby: 
        title:       Programming Ruby 1.9
        description: 
          Ruby is the fastest growing and most exciting dynamic
          language out there.  If you need to get working programs
          delivered fast, you should add Ruby to your toolbox.
        price:       49.50
        image_url:   ruby.png 
    EOF
  end

  desc 'Now run the tests... and watch them fail :-('
  cmd 'rake test'

  desc 'Solution is simple, provide valid data.'
  edit 'test/functional/products_controller_test.rb', 'valid' do |data|
    data.msub /()require/, "#START:valid\n"
    data.msub /class.*\n()/, <<-EOF.unindent(6)
      #END:valid
    EOF

    edit /^\s+setup do.*end/m, :mark => 'valid' do
      msub /^()\s+end/, <<-EOF.unindent(4), :highlight
        @update = {
          :title       => 'Lorem Ipsum',
          :description => 'Wibbles are fun!',
          :image_url   => 'lorem.jpg',
          :price       => 19.95
        }
      EOF
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
    
    %w(update create).each do |test|
      data.dcl "should #{test} product", :mark => 'valid' do
        edit 'attributes', :highlight do
          sub! /@product.attributes/, "@update"
        end
        self.all <<= "\n  # ...\n"
      end
    end

    data.msub /(\nend)/, "\n#START:valid\nend\n#END:valid"
  end

  desc 'Tests now pass again :-)'
  cmd 'rake test'

  desc 'Add some unit tests for new function.'
  edit "test/unit/product_test.rb" do |data|
    data.all = read('test/product_test.rb')
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Tests pass!'
  cmd 'rake test:units'
end

section 7.3, 'Playtime' do
  overview <<-EOF
    Save our work 
  EOF

  desc 'Show what files we changed.'
  cmd 'git status'

  desc 'Commit changes using -a shortcut'
  cmd "git commit -a -m 'Validation!'"

  publish_code_snapshot :c

  edit 'app/models/product.rb' do
    msub /()#END:validation/,
      "  validates :title, :length => {:minimum => 10}\n"
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
end

section 8.1, 'Iteration C1: Create the Catalog Listing' do
  overview <<-EOF
    Show the model, view, and controller working together.
  EOF

  desc 'Create a second controller with a single index action'
  generate 'controller Store index'

  unless File.exist? 'public/images'
    cmd "cp -v #{$DATA}/store.css.scss app/assets/stylesheets"
  end

  desc "Route the 'root' of the site to the store"
  edit 'config/routes.rb', 'root' do |data|
    data.msub /^()/, "# START:root\n"
    data.msub /\n()  #/, "  # ...\n# END:root\n"

    data.msub /()\s+#.+root of your site/, "\n# START:root"
    data.msub /root :to.*\n()/, <<-EOF.unindent(4)
      # START_HIGHLIGHT
      root :to => 'store#index', :as => 'store'
      # END_HIGHLIGHT

      # ...
      # END:root
    EOF
    data.edit 'store#index' do
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end

    data.edit /^end/, :mark=>'root'
  end

  desc 'Delete public/index.html, as instructed.'
  cmd 'rm public/index.html'

  desc 'Demonstrate that everything is wired together'
  get '/'

  desc 'In the controller, get a list of products from the model'
  edit 'app/controllers/store_controller.rb' do |data|
    data.msub /def index.*\n()/, <<-EOF.unindent(2), :highlight
      @products = Product.order(:title)
    EOF
  end

  desc 'In the view, display a list of products'
  edit 'app/views/store/index.html.erb' do |data|
    data.all = read('store/index.html.erb')
  end

  desc 'Show our first (ugly) catalog page'
  get '/'
  publish_code_snapshot :d
end

section 8.2, 'Iteration C2: Add a Page Layout' do
  overview <<-EOF
    Demonstrate layouts.
  EOF

# desc 'Look at the layouts that we have so far'
# cmd 'ls app/views/layouts/*.html.erb'
#
# desc 'Remove the current layouts'
# cmd 'rm app/views/layouts/*.html.erb'
#
# desc 'Make sure they never come back'
# edit 'config/initializers/no_layout.rb' do |data|
#   data.all = <<-EOF.unindent(6)
#     Depot::Application.configure do
#       config.generators.erb={:layout=>false}
#     end
#   EOF
# end

  desc 'Modify the application layout'
  edit 'app/views/layouts/application.html.erb' do
    self.all = read('store/layout.html.erb')
    gsub! ':defaults', '"application"' unless File.exist? 'public/images'
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Modify the stylesheet'
  if DEPOT_CSS =~ /scss/
    cmd "mv app/assets/stylesheets/application.css #{DEPOT_CSS}"
    edit DEPOT_CSS do
      self << "\n\n" + <<-EOF.unindent(8)
        /* Global styles */

        #banner {
          background: #9c9;
          padding-top: 10px;
          padding-bottom: 10px;
          border-bottom: 2px solid;
          font: small-caps 40px/40px "Times New Roman", serif;
          color: #282;
          text-align: center;

          img {
            float: left;
          }
        }

        #notice {
          color: #000;
          border: 2px solid red;
          padding: 1em;
          margin-bottom: 2em;
          background-color: #f0f0f0;
          font: bold smaller sans-serif;
        }

        #columns {
          background: #141;
        }

        #main {
          margin-left: 17em;
          padding-top: 4ex;
          padding-left: 2em;
          background: white;
        }

        #side {
          float: left;
          padding-top: 1em;
          padding-left: 1em;
          padding-bottom: 1em;
          width: 16em;
          background: #141;

          a {
            color: #bfb;
            font-size: small;
          }
        }
      EOF
    end
  else
    edit DEPOT_CSS, 'mainlayout' do
      msub /().*An entry in the store catalog/, <<-EOF.unindent(8) + "\n"
        /* START:mainlayout */
        /* Styles for main page */

        #banner {
          background: #9c9;
          padding-top: 10px;
          padding-bottom: 10px;
          border-bottom: 2px solid;
          font: small-caps 40px/40px "Times New Roman", serif;
          color: #282;
          text-align: center;
        }

        #banner img {
          float: left;
        }

        #columns {
          background: #141;
        }

        #main {
          margin-left: 17em;
          padding-top: 4ex;
          padding-left: 2em;
          background: white;
        }

        #side {
          float: left;
          padding-top: 1em;
          padding-left: 1em;
          padding-bottom: 1em;
          width: 16em;
          background: #141;
        }

        #side a {
          color: #bfb;
          font-size: small;
        }
        /* END:mainlayout */
      EOF
    end
  end

  desc 'Show the results.'
  get '/'
end

section 8.3, 'Iteration C3: Use a Helper to Format the Price' do
  overview <<-EOF
    Demonstrate helpers.
  EOF

  desc 'Format the price using a built-in helper.'
  edit 'app/views/store/index.html.erb' do
    edit 'product.price', :mark => 'currency' do
      msub /<%= (product.price) %>/, "number_to_currency(product.price)"
    end
  end

  desc 'Show the results.'
  get '/'
end

section 8.4, 'Iteration C4: Functional Testing' do
  overview <<-EOF
    Demonstrate use of assert_select to test views.
  EOF

  desc 'Verify that the tests still pass.'
  cmd 'rake test'

  desc 'Add tests for layout, product display, and formatting, using ' +
    'counts, string comparisons, and regular expressions.'
  edit 'test/functional/store_controller_test.rb' do
    clear_highlights
    dcl 'should get index' do
      msub /^()\s+end/, <<-'EOF'.unindent(4), :highlight
        assert_select '#columns #side a', :minimum => 4
        assert_select '#main .entry', 3
        assert_select 'h3', 'Programming Ruby 1.9'
        assert_select '.price', /\$[,\d]+\.\d\d/
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Show that the tests pass.'
  cmd 'rake test:functionals'
  publish_code_snapshot :e
end

section 8.5, 'Playtime' do
  cmd 'git tag iteration-b'
  cmd 'git commit -a -m "Prettier listings"'
  cmd 'git tag iteration-c'
end

section 9.1, 'Iteration D1: Finding a Cart' do
  overview <<-EOF
    Create a cart.  Put it in a session.  Find it.
  EOF

  desc 'Create a cart.'
  generate 'scaffold Cart'
  cmd 'rake db:migrate'

  desc "Implement current_cart, which creates a new cart if it" +
    " can't find one."
  edit 'app/controllers/application_controller.rb' do |data|
    data.msub /()^end/, "\n" + <<-EOF.unindent(4), :highlight
      private

        def current_cart 
          Cart.find(session[:cart_id])
        rescue ActiveRecord::RecordNotFound
          cart = Cart.create
          session[:cart_id] = cart.id
          cart
        end
    EOF

    issue 'Replace with signed cookies?'
    next

    data.msub /()^end/, "\n" + <<-EOF.unindent(4), :highlight
      private

        def current_cart 
          unless cart = Cart.find_by_id(cookies.signed[:cart_id])
            cart = Cart.create
            cookies.permanent.signed[:cart_id] = cart.id
          end

          cart
        end
    EOF
  end
end

section 9.2, 'Iteration D2: Connecting Products to Carts' do
  overview <<-EOF
    Create line item which connects products to carts'
  EOF

  desc 'Create the model object.'
  generate 'scaffold LineItem product_id:integer cart_id:integer'
  cmd 'rake db:migrate'

  desc 'Cart has many line items.'
  edit 'app/models/cart.rb' do |data|
    data.msub /class Cart.*\n()/, <<-EOF.unindent(4), :highlight
      has_many :line_items, :dependent => :destroy
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Product has many line items.'
  edit 'app/models/product.rb', 'has_many' do
    clear_highlights
    edit 'class Product', :mark => 'has_many'
    edit /^()end\n/, :mark => 'has_many'
    msub /class Product.*\n()/, <<-EOF.unindent(4)
      #START_HIGHLIGHT
      has_many :line_items
      #END_HIGHLIGHT

      #START_HIGHLIGHT
      before_destroy :ensure_not_referenced_by_any_line_item
      #END_HIGHLIGHT

      #...

      #END:has_many
    EOF

    msub /^()end/, "\n" + <<-EOF.unindent(4)
      #START_HIGHLIGHT
      private
      #END_HIGHLIGHT

        #START_HIGHLIGHT
        # ensure that there are no line items referencing this product
        def ensure_not_referenced_by_any_line_item
          if line_items.empty?
            return true
          else
            errors.add(:base, 'Line Items present')
            return false
          end
        end
        #END_HIGHLIGHT
    EOF
  end

  desc 'Line item belongs to both Cart and Product ' +
       '(But slightly more to the Cart).  Also provide convenient access ' +
       "to the total price of the line item"
  edit 'app/models/line_item.rb' do |data|
    data.msub /class LineItem.*\n()/, <<-EOF.unindent(4), :highlight
      belongs_to :product
      belongs_to :cart
    EOF
  end
end

section 9.3, 'Iteration D3: Adding a button' do
  overview <<-EOF
    Now we connect the model objects we created to the controller and the view.
  EOF

  desc 'Add the button, connecting it to the Line Item Controller, passing ' +
       'the product id.'
  edit 'app/views/store/index.html.erb' do |data|
    data.msub /number_to_currency.*\n()/, <<-EOF, :highlight
      <%= button_to 'Add to Cart', line_items_path(:product_id => product) %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add a bit of style to make it show all on one line'
  if DEPOT_CSS =~ /scss/
    edit 'app/assets/stylesheets/store.css.scss', 'inline' do
      edit /^ +.price_line \{.*?\n()    \}\n/m, :mark => 'inline'
      msub /^ +.price_line \{.*?\n()    \}\n/m, "\n" + <<-EOF.unindent(2)
        form, div {
          display: inline;
        }
      EOF
    end
  else
    edit DEPOT_CSS, 'inline' do |data|
      data << "\n" + <<-EOF.unindent(8)
        /* START:inline */
        #store .entry form, #store .entry form div {
          display: inline;
        }
        /* END:inline */
      EOF
    end
  end

  desc 'Update the LineItem.new call to use current_cart and the ' +
       'product id. Additionally change the logic so that redirection upon ' +
       'success goes to the cart instead of the line item.'
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    data.dcl 'create', :mark do
      edit 'LineItem.new', :highlight do
        msub /^()/, <<-EOF.unindent(6)
          @cart = current_cart
          product = Product.find(params[:product_id])
        EOF
        msub /(LineItem.new\(.*\))/,
          "@cart.line_items.build(:product => product)"
        gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
      end
      msub /,( ):?notice/, "\n          "
      msub /,( ):?status/, "\n          "
      msub /,( ):?status/, "\n          "
    end

    data.edit 'redirect_to', :highlight
    data.msub /redirect_to[\(\s]@line_item()/, '.cart'
  end

  desc "Try it once, and see that the output isn't very useful yet."
  post '/', 'product_id' => 3

  desc 'Update the template that shows the Cart.'
  edit 'app/views/carts/show.html.erb' do |data|
    data[/(.*)/m,1] = <<-EOF.unindent(6)
      <h2>Your Pragmatic Cart</h2>
      <ul>    
        <% @cart.line_items.each do |item| %>
          <li><%= item.product.title %></li>
        <% end %>
      </ul>
    EOF
  end

  desc "Try it once again, and see that the products in the cart."
  post '/', 'product_id' => 3
  publish_code_snapshot :f
end

section 9.4, 'Playtime' do
  overview <<-EOF
    Once again, get the tests working, and add tests for the smarter cart.
  EOF

  desc 'See that the tests fail.'
  cmd 'rake test'

  desc 'Update parameters passed as well as expected target of redirect'
  edit 'test/functional/line_items_controller_test.rb', 'create' do |data|
    data.dcl 'should create', :mark => 'create' do
      edit 'post :create', :highlight do
        if self =~ /:line_item =>/
          msub /(:line_item =>.*)/, ':product_id => products(:ruby).id'
        else
          msub /(line_item:.*)/, 'product_id: products(:ruby).id'
        end
      end
      edit 'line_item_path', :highlight do
        msub /(line_item_path.*)/, 'cart_path(assigns(:line_item).cart)'
      end
    end
  end

  cmd 'rake test'
end

section 10.1, 'Iteration E1: Creating a Smarter Cart' do
  overview <<-EOF
    Change the cart to track the quantity of each product.
  EOF

  desc "Add a quantity column to the line_item table in the database."
  generate 'migration add_quantity_to_line_items quantity:integer'

  desc "Modify the migration to add a default value for the new column"
  edit Dir['db/migrate/*add_quantity_to_line_items.rb'].first do |data|
    data[/\n().*add_column/,1] = "# START_HIGHLIGHT\n"
    data[/add_column.*\n()/,1] = "# END_HIGHLIGHT\n"

    data[/add_column.* :quantity,.*()/,1] = ', :default => 1'
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Apply the migration"
  cmd 'rake db:migrate'

  desc 'Create a method to add a product to the cart by either incrementing ' +
       'the quantity of an existing line item, or creating a new line item.'
  edit 'app/models/cart.rb', 'add_product' do
    msub /^()end/, "\n" + <<-'EOF'.unindent(4), :mark => 'add_product'
      def add_product(product_id)
        current_item = line_items.find_by_product_id(product_id)
        if current_item
          current_item.quantity += 1
        else
          current_item = line_items.build(:product_id => product_id)
        end
        current_item
      end
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Replace the call to LineItem.new with a call to the new method.'
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    data.clear_highlights
    data.dcl 'create' do |create|
      create.edit 'line_items.build', :highlight do |linew|
        linew.msub /@line_item = (.*)/, '@cart.add_product(product.id)'
      end
    end
  end

  desc 'Update the view to show both columns.'
  edit 'app/views/carts/show.html.erb' do |data|
    data[/<li>(.*?)<\/li>/,1] =
      '<%= item.quantity %> &times; <%= item.product.title %>'

    data[/\n().*quantity/,1] = "<!-- START_HIGHLIGHT -->\n"
    data[/quantity.*\n()/,1] = "<!-- END_HIGHLIGHT -->\n"
  end

  desc "Look at the cart, and see that's not exactly what we intended"
  get '/carts/1'

  desc 'Generate a migration to combine/separate items in carts.'
  generate 'migration combine_items_in_cart'

  desc 'Fill in the self.up method'
  edit Dir['db/migrate/*combine_items_in_cart.rb'].first, 'up' do
    selfup = include?('self.up')
    self.all = read('cart/combine_items_in_cart.rb')
    gsub! 'self.', '' unless selfup
    gsub! /:(\w+)=>/, '\1: \2' unless RUBY_VERSION =~ /^1\.8/ # add a space
  end

  desc 'Combine entries'
  cmd 'rake db:migrate'

  desc "Verify that the entries have been combined."
  get '/carts/1'

  desc 'Fill in the self.down method'
  edit Dir['db/migrate/*combine_items_in_cart.rb'].first, 'down'

  desc 'Separate out individual items.'
  cmd 'rake db:rollback'

  desc 'Every item should (once again) only have a quantity of one.'
  get '/carts/1'

  desc 'Recombine the item data.'
  cmd 'rake db:migrate'

  desc 'Add a few products to the order.'
  post '/', {'product_id' => 2}, {:snapget => false}
  post '/', {'product_id' => 3}, {:snapget => false}
  publish_code_snapshot :g

  desc 'Try something malicious.'
  get '/carts/wibble'
end

section 10.2, 'Iteration E2: Handling Errors' do
  overview <<-EOF
    Log errors and show them on the screen.
  EOF

  desc 'Rescue error: log, flash, and redirect.'
  edit 'app/controllers/carts_controller.rb', 'show' do |data|
    data[/()  # GET .carts.1/,1]= "# START:show\n"
    data[/# GET .carts.1.*?\n  end\n()/m,1]= "# END:show\n"

    dcl 'show' do
      self.all = <<-'EOF'.unindent(6)
        def show
          # START_HIGHLIGHT
          begin
          # END_HIGHLIGHT
            @cart = Cart.find(params[:id])
          # START_HIGHLIGHT
          rescue ActiveRecord::RecordNotFound
            logger.error "Attempt to access invalid cart #{params[:id]}"
            redirect_to store_url, :notice => 'Invalid cart'
          else
          # END_HIGHLIGHT
            respond_to do |format|
              format.html # show.html.erb
              format.json { render :json => @cart }
            end
          # START_HIGHLIGHT
          end
          # END_HIGHLIGHT
        end
      EOF
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc 'Reproduce the error.'
  get '/carts/wibble'

  desc 'Inspect the log.'
  cmd 'tail -25 log/development.log', :highlight => ['Attempt to access']
end

section 10.3, 'Iteration E3: Finishing the Cart' do
  overview <<-EOF
    Add empty cart button, remove flash for line item create, add totals to
    view.
  EOF

  desc 'Add button to the view.'
  edit 'app/views/carts/show.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/.*()/m,1] = "\n" + <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <%= button_to 'Empty cart', @cart, :method => :delete,
          :confirm => 'Are you sure?' %>
      <!-- END_HIGHLIGHT -->
    EOF
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Clear session and add flash notice when cart is destroyed.'
  edit 'app/controllers/carts_controller.rb', 'destroy' do
    dcl 'destroy', :mark => 'destroy' do
      edit 'Cart.find', :highlight do
        msub /@cart = (.*)/, 'current_cart'
      end

      msub /@cart.destroy\n()/,<<-EOF.unindent(4), :highlight
        session[:cart_id] = nil
      EOF

      edit 'carts_url', :highlight do
        sub! 'carts_url', 
          "store_url,\n        :notice => 'Your cart is currently empty'"
      end
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc 'Try it out.'
  post '/carts/1', '_method'=>'delete'
  publish_code_snapshot :h

  desc 'Remove scaffolding generated flash notice for line item create.'
  edit 'app/controllers/line_items_controller.rb', 'create' do
    dcl 'create' do
      clear_highlights
      msub /(,\s+:?notice.*?)\)?\s\}/, ''
      edit 'redirect_to', :highlight
    end
  end

  desc 'Update the view to add totals.'
  edit 'app/views/carts/show.html.erb' do |data|
    data[/(.*)/m,1] = read('cart/show.html.erb')
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add a method to compute the total price of a single line item.'
  edit 'app/models/line_item.rb', 'total_price' do
    msub /()^end/, "\n" + <<-EOF.unindent(4), :mark => 'total_price'
      def total_price
        product.price * quantity
      end
    EOF
  end

  desc 'Add a method to compute the total price of the items in the cart.'
  edit 'app/models/cart.rb', 'total_price' do |data|
    data[/()^end/,1] = "\n" + <<-EOF.unindent(4)
      #START:total_price
      def total_price
        line_items.to_a.sum { |item| item.total_price }
      end
      #END:total_price
    EOF
  end

  desc 'Add some style.'
  edit DEPOT_CSS, 'cartmain' do |data|
    if DEPOT_CSS =~ /scss/
      data << "\n" + <<-EOF.unindent(8)
        /* START:cartmain */
        /* Styles for the cart in the main page */

        #store {
          .cart_title {
            font: 120% bold;
          }

          .item_price, .total_line {
            text-align: right;
          }

          .total_line .total_cell {
            font-weight: bold;
            border-top: 1px solid #595;
          }
        }
        /* END:cartmain */
      EOF
    else
      data << "\n" + <<-EOF.unindent(8)
        /* START:cartmain */
        /* Styles for the cart in the main page */

        #store .cart_title {
          font: 120% bold;
        }

        #store .item_price, #store .total_line {
          text-align: right;
        }

        #store .total_line .total_cell {
          font-weight: bold;
          border-top: 1px solid #595;
        }
        /* END:cartmain */
      EOF
    end
  end

  desc 'Add a product to the cart, and see the total.'
  post '/', {'product_id' => 2}

  desc "Add a few more products, and watch the totals climb!"
  post '/', {'product_id' => 2}, {:snapget => false}
  post '/', {'product_id' => 3}, {:snapget => false}
end

section 10.4, 'Playtime' do
  overview <<-EOF
    Once again, get the tests working, and add tests for the smarter cart.
  EOF

  desc 'See that the tests fail.'
  cmd 'rake test'

  desc 'Substitute names of products and carts for numbers'
  edit 'test/fixtures/line_items.yml' do |data|
    data.gsub! 'product_id: 1', 'product: ruby'
    data.gsub! '_id: 1', ': one'
    data.gsub! '_id: 2', ': two'

    data.msub /one:\n(.*?)\n\n/m, '\1', :highlight
    data.msub /two:\n(.*?)\n\Z/m, '\1', :highlight
  end

  desc 'Update expected target of redirect: Cart#destroy.'
  edit 'test/functional/carts_controller_test.rb', 'destroy' do |data|
    data.dcl 'should destroy', :mark => 'destroy' do |destroy|
      msub /().*delete :destroy/, "      session[:cart_id] = @cart.id\n", 
        :highlight
      destroy.edit 'carts_path', :highlight do
        msub /(carts)/, 'store'
      end
    end
  end

  desc 'Test both unique and duplicate products.'
  edit "test/unit/cart_test.rb" do |data|
    data.all = read('test/cart_test.rb')
  end
  ruby '-I test test/unit/cart_test.rb'

  publish_code_snapshot :i

  desc 'Refactor.'
  edit "test/unit/cart_test.rb" do |data|
    data.all = read('test/cart_test1.rb')
  end
  ruby '-I test test/unit/cart_test.rb'

  desc 'Verify that the tests pass.'
  cmd 'rake test'

  desc "Add a test ensuring that non-empty carts can't be deleted."
  edit 'test/functional/products_controller_test.rb', 'destroy' do
    clear_highlights
    gsub! "\n\n  # ...\n", "\n" 
    dcl 'should destroy product', :mark => 'destroy' do
      destroy_product_two = dup
      sub!('@product', 'products(:ruby)')
      sub! 'should destroy product', "can't delete product in cart"
      sub! '-1', '0'
      self << "\n" + destroy_product_two
    end
  end

  desc 'Now the tests should pass.'
  cmd 'rake test'

  desc 'Add price to line item'
  generate 'migration add_price_to_line_item price:decimal'
  edit Dir['db/migrate/*add_price_to_line_item.rb'].first do
    up = (include?('self.up') ? 'self.up' : 'change')
    dcl up do
      msub /add_column.*\n()/, <<-EOF.unindent(4)
        LineItem.all.each do |li|
          li.price = li.product.price
        end
      EOF
    end
  end
  rake 'db:migrate'
  edit 'app/models/cart.rb' do
    dcl 'add_product' do
      msub /line_items[.]build.*\n()/, <<-EOF.unindent(2)
        current_item.price = current_item.product.price
      EOF
    end
  end

  cmd 'git commit -a -m "Adding a Cart"'
  cmd 'git tag iteration-d'
end

section 11.1, 'Iteration F1: Moving the Cart' do
  overview <<-EOF
    Refactor the cart view into partials, and reference the result from
    the layout.
  EOF

  desc 'Create a "partial" view, for just one line item'
  edit 'app/views/line_items/_line_item.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/()/,1] = <<-EOF.unindent(6)
      <tr>
        <td><%= line_item.quantity %>&times;</td>
        <td><%= line_item.product.title %></td>
        <td class="item_price"><%= number_to_currency(line_item.total_price) %></td>
      </tr>
    EOF
  end

  desc 'Replace that portion of the view with a callout to the partial'
  edit 'app/views/carts/show.html.erb' do |data|
    data.msub /^(  <% @cart.line_items.each do .* end %>\n)/m, 
      "  <%= render(@cart.line_items) %>\n", :highlight
  end

  desc 'Make a copy as a partial for the cart controller'
  cmd 'cp app/views/carts/show.html.erb app/views/carts/_cart.html.erb'

  desc 'Modify the copy to reference the (sub)partial and take input from @cart'
  edit 'app/views/carts/_cart.html.erb' do
    clear_highlights
    while include? '@cart'
      edit '@cart', :highlight
      sub! '@cart', 'cart'
    end
    sub! /,\n<!-- END_HIGHLIGHT -->/, ",\n# END_HIGHLIGHT"
    sub! /#START_HIGHLIGHT\n<%=/, "<!-- START_HIGHLIGHT -->\n<%="
  end

  desc 'Insert a call in the controller to find the cart'
  edit 'app/controllers/store_controller.rb', 'index' do |data|
    data.clear_highlights
    data.dcl 'index', :mark => 'index'
    data.msub /@products = .*\n()/, "    @cart = current_cart\n",
      :highlight
  end

  desc 'Reference the partial from the layout.'
  edit 'app/views/layouts/application.html.erb' do
    clear_highlights
    msub /<div id="side">\n()/, <<-'EOF' + "\n", :highlight
      <div id="cart">
        <%= render @cart %>
      </div>
    EOF
    gsub! /(<!-- <label id="[.\w]+"\/> -->)/, ''
  end

  desc 'Add a small bit of style.'
  edit DEPOT_CSS, 'cartside' do |data|
    if DEPOT_CSS =~ /scss/
      data << "\n" + <<-EOF.unindent(8)
        /* START:cartside */
        /* Styles for the cart in the sidebar */
        
        #cart {
          font-size: smaller;
          color:     white;

          table {
            border-top:    1px dotted #595;
            border-bottom: 1px dotted #595;
            margin-bottom: 10px;
          }
        }
        /* END:cartside */
      EOF
    else
      data << "\n" + <<-EOF.unindent(6)
        /* START:cartside */
        /* Styles for the cart in the sidebar */
        
        #cart, #cart table {
          font-size: smaller;
          color:     white;
        }

        #cart table {
          border-top:    1px dotted #595;
          border-bottom: 1px dotted #595;
          margin-bottom: 10px;
        }
        /* END:cartside */
      EOF
    end
  end

  publish_code_snapshot :j

  desc 'Keep things DRY'
  edit 'app/views/carts/show.html.erb' do
    self.all = "<%= render @cart %>\n"
    edit 'render', :highlight
  end

  desc 'Change the redirect to be back to the store.'
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    data[/(@line_item.cart)/,1] = "store_url"
  end

  desc 'Purchase another product.'
  post '/', 'product_id' => 3

  publish_code_snapshot :k
end

section 11.2, 'Iteration F2: Creating an AJAX-Based Cart' do
  edit 'app/views/store/index.html.erb' do |data|
    data.clear_all_marks
    data.edit '<%= button_to', :highlight
    data.msub /<%= button_to.*() %>/, ",\n        :remote => true"
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/controllers/line_items_controller.rb', 'create' do
    clear_highlights
    msub /format.html.*store_url.*\n()/, "        format.js\n", :highlight
  end
  if File.exist? 'public/images'
    edit 'app/views/line_items/create.js.rjs' do |data|
      data.all =  <<-EOF.unindent(8)
        page.replace_html('cart', render(@cart))
      EOF
    end
  else
    edit 'app/views/line_items/create.js.erb' do |data|
      data.all =  <<-EOF.unindent(8)
        $('#cart').html("<%=j render @cart %>");
      EOF
    end
  end
  publish_code_snapshot :l
end

section 11.3, 'Iteration F3: Highlighting Changes' do
  edit 'app/controllers/line_items_controller.rb', 'create' do
    clear_highlights
    dcl 'create' do
      msub /format.js()\n/, '   { @current_item = @line_item }'
      edit 'format.js', :highlight
    end
  end

  edit 'app/views/line_items/_line_item.html.erb' do |data|
    data[/(<tr>\n)/,1] = <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <% if line_item == @current_item %>
      <tr id="current_item">
      <% else %>
      <tr>
      <% end %>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  if File.exist? 'app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.rjs' do |data|
      msub /.*()/m, "\n" + <<-EOF.unindent(8), :highlight
        page[:current_item].visual_effect :highlight,
                                          :startcolor => "#88ff88",
                                          :endcolor => "#114411"
      EOF
    end
  else
    edit 'app/views/line_items/create.js.erb' do |data|
      msub /.*()/m, "\n" + <<-EOF.unindent(8), :highlight
        $('#current_item').css({'background-color':'#88ff88'}).
          animate({'background-color':'#114411'}, 1000);
      EOF
    end
    desc 'Now pull in the jquery-ui libraries'
    edit 'app/assets/javascripts/application.js' do
      msub /()\/\/= require jquery_ujs/, <<-EOF.unindent(8)
        //#START_HIGHLIGHT
        //= require jquery-ui
        //#END_HIGHLIGHT
      EOF
    end
  end
  publish_code_snapshot :m
end

section 11.4, 'Iteration F4: Hide an Empty Cart' do
  if File.exist? 'app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.rjs' do
      msub /().*visual_effect/, <<-EOF.unindent(8) + "\n", :highlight
        page[:cart].visual_effect :blind_down if @cart.total_items == 1
      EOF
    end
  else
    edit 'app/views/line_items/create.js.erb' do
      clear_highlights
      msub /().*render/, <<-EOF.unindent(8) + "\n", :highlight
        if ($('#cart tr').length == 1) { $('#cart').show('blind', 1000); }
      EOF
    end
  end
  edit 'app/models/cart.rb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/()^end/,1] = "\n" + <<-EOF.unindent(4)
      #START:total_items
      def total_items
        line_items.sum(:quantity)
      end
      #END:total_items
    EOF
  end

  cmd 'ls -p app'
  cmd 'ls -p app/helpers'

  edit 'app/views/layouts/application.html.erb', 'hidden_div' do |data|
    data.msub /<div id="cart">.*?(<\/div>)/m, '<% end %>' +
      "\n    <!-- END:hidden_div -->"
    data.msub /(<div id="cart">)/,
      "<!-- START:hidden_div -->\n      " +
      "<%= hidden_div_if(@cart.line_items.empty?, :id => 'cart') do %>"
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  edit 'app/helpers/application_helper.rb' do |data|
    data.msub /()^end/, <<-EOF.unindent(4)
      def hidden_div_if(condition, attributes = {}, &block)
        if condition
          attributes["style"] = "display: none"
        end
        content_tag("div", attributes, &block)
      end
    EOF
  end

  edit 'app/controllers/carts_controller.rb', 'destroy' do
    clear_highlights
    dcl 'destroy' do
      sub! /,\s+:?notice:?\s?=?>? 'Your cart is currently empty'/, ''
      edit 'format.html', :highlight
    end
  end

  publish_code_snapshot :n

  post '/carts/2', '_method'=>'delete'
  post '/', 'product_id' => 3
  desc 'Run tests... oops.'
  cmd 'rake test'
end

section 11.5, 'Iteration F5: Testing AJAX changes' do
  desc 'Verify that yes, indeed, the product index is broken.'
  get '/products'

  desc 'Conditionally display the cart.'
  edit "app/views/layouts/application.html.erb", 'hidden_div' do |data|
    data.edit /^ +<%= hidden_div_if.*? end %>\s*\n/m do
      gsub!(/^/, '  ')
      msub /\A()/,   "      <% if @cart %>\n", :highlight
      msub /\n()\Z/, "      <% end %>\n",     :highlight
    end
  end

  desc 'Update the redirect test.'
  edit 'test/functional/line_items_controller_test.rb', 'create' do
    clear_highlights
    edit "assert_redirected_to", :highlight do
      msub /assert_redirected_to (cart_path.*)/, 'store_path'
    end
  end

  desc 'Add an AJAX test.'
  edit 'test/functional/line_items_controller_test.rb', 'ajax' do
    msub /()\nend/, "\n\n" + <<-EOF.unindent(4) + "\n"
      #START:ajax
      #START_HIGHLIGHT
      test "should create line_item via ajax" do
      #END_HIGHLIGHT
        assert_difference('LineItem.count') do
          #START_HIGHLIGHT
          xhr :post, :create, :product_id => products(:ruby).id
          #END_HIGHLIGHT
        end 
    
        #START_HIGHLIGHT
        assert_response :success
        assert_select_rjs :replace_html, 'cart' do
          assert_select 'tr#current_item td', /Programming Ruby 1.9/
        end
        #END_HIGHLIGHT
      end
      #END:ajax
    EOF
    unless File.exist? 'public/images'
      gsub! "_rjs :replace_html, 'cart'", "_jquery :html, '#cart'"
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc 'Run the tests again.'
  cmd 'rake test'

  desc 'Save our progress'
  cmd 'git commit -a -m "AJAX"'
  cmd 'git tag iteration-g'
end

section 12.1, 'Iteration G1: Capturing an Order' do
  generate :scaffold, :Order,
    'name:string address:text email:string pay_type:string'

  edit Dir['db/migrate/*_create_orders.rb'].first, 'up' do |data|
    up = (include?('self.up') ? 'self.up' : 'change')
    dcl up, :mark=>'up' do
      edit 'pay_type', :highlight do
        self << ', :limit => 10'
      end
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  generate 'migration add_order_id_to_line_item order_id:integer'
  cmd 'rake db:migrate'
  cmd 'sqlite3 db/development.sqlite3 .schema'
  edit 'app/models/order.rb', 'has_many' do |data|
    data[/()class Order/,1] = "#START:has_many\n"
    data[/class Order.*\n()/,1] = <<-EOF.unindent(4)
      #END:has_many
      #START:has_many
      #START_HIGHLIGHT
      has_many :line_items, :dependent => :destroy
      #END_HIGHLIGHT
      # ...
      #END:has_many
    EOF
    data[/()^end/,1] = "#START:has_many\n"
    data[/^end()/,1] = "\n#END:has_many"
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/models/line_item.rb', 'belongs_to' do
    clear_all_marks
    msub /class LineItem.*\n()/, <<-EOF.unindent(6), :highlight
        belongs_to :order
    EOF
  end
  edit 'app/views/carts/_cart.html.erb' do
    clear_highlights
    msub /().*Empty cart.*\n.*>/, <<-'EOF'.unindent(6), :highlight
      <%= button_to "Checkout", new_order_path, :method => :get %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/controllers/orders_controller.rb', 'checkout' do
    dcl 'new', :mark => 'checkout'
    msub /\n()\s+@order = Order.new\n/, <<-EOF.unindent(2) + "\n", :highlight
      @cart = current_cart
      if @cart.line_items.empty?
        redirect_to store_url, :notice => "Your cart is empty"
        return
      end
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/views/orders/new.html.erb' do
    self.all = read('orders/new.html.erb')
  end
  edit 'app/views/orders/_form.html.erb' do
    msub /<%= pluralize.*%>( )/, "\n      "
    edit 'text_field :name', :highlight do
      msub /() %>/, ', :size => 40'
    end
    edit 'text_area :address', :highlight do
      msub /() %>/, ', :rows => 3, :cols => 40'
    end
    edit 'text_field :email', :highlight do
      msub /(text)_field/, 'email'
      msub /() %>/, ', :size => 40'
    end
    edit 'text_field :pay_type', :highlight # while it still is on one line
    edit 'text_field :pay_type' do
      msub /(text_field)/, 'select'
      msub /() %>/, ", Order::PAYMENT_TYPES,\n" + (' ' * 18) +
        ":prompt => 'Select a payment method'"
    end
    edit 'submit', :highlight do
      msub /() %>/, " 'Place Order'"
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/models/order.rb', 'select' do |data|
    data[/()class Order.*/,1] = "#START:select\n"
    data[/#END:has_many.*()/,1] = "\n" + <<-EOF.unindent(4)
      #START_HIGHLIGHT
      PAYMENT_TYPES = [ "Check", "Credit card", "Purchase order" ]
      #END_HIGHLIGHT
      #END:select
    EOF
    edit /^end()/, :mark => 'select'
  end
  edit DEPOT_CSS, 'form' do |data|
    if DEPOT_CSS =~ /scss/
      data << "\n" + <<-EOF.unindent(8)
        /* START:form */
        /* Styles for order form */

        .depot_form {
          fieldset {
            background: #efe;
          }

          legend {
            color: #dfd;
            background: #141;
            font-family: sans-serif;
            padding: 0.2em 1em;
          }

          label {
            width: 5em;
            float: left;
            text-align: right;
            padding-top: 0.2em;
            margin-right: 0.1em;
            display: block;
          }

          select, textarea, input {
            margin-left: 0.5em;
          }

          .submit {
            margin-left: 4em;
          }

          div {
            margin: 0.5em 0;
          }
        }
        /* END:form */
      EOF
    else
      data << "\n" + <<-EOF.unindent(8)
        /* START:form */
        /* Styles for order form */

        .depot_form fieldset {
          background: #efe;
        }

        .depot_form legend {
          color: #dfd;
          background: #141;
          font-family: sans-serif;
          padding: 0.2em 1em;
        }

        .depot_form label {
          width: 5em;
          float: left;
          text-align: right;
          padding-top: 0.2em;
          margin-right: 0.1em;
          display: block;
        }

        .depot_form select, .depot_form textarea, .depot_form input {
          margin-left: 0.5em;
        }

        .depot_form .submit {
          margin-left: 4em;
        }

        .depot_form div {
          margin: 0.5em 0;
        }
        /* END:form */
      EOF
    end
  end
  edit 'app/models/order.rb', 'validate' do |data|
    msub /#END:select\n()/, <<-EOF.unindent(4), :mark => 'validate'
      # ...
      #START_HIGHLIGHT
      validates :name, :address, :email, :pay_type, :presence => true
      validates :pay_type, :inclusion => PAYMENT_TYPES
      #END_HIGHLIGHT
    EOF
    edit 'class Order', :mark => 'validate'
    edit /^end/, :mark => 'validate'
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/controllers/orders_controller.rb', 'create' do |data|
    data[/().*def create/,1] = "#START:create\n"
    data[/def create.*?\n  end\n()/m,1] = "#END:create\n"
    data[/@order = Order.new\(.*\)\n()/,1] = <<-EOF.unindent(2)
      #START_HIGHLIGHT
      @order.add_line_items_from_cart(current_cart)
      #END_HIGHLIGHT
    EOF
    data[/if @order.save\n()/,1] = <<-EOF.indent(2)
      #START_HIGHLIGHT
      Cart.destroy(session[:cart_id])
      session[:cart_id] = nil
    EOF
    data[/Order was successfully created.*\n()/,1] = <<-EOF
      #END_HIGHLIGHT
    EOF
    data[/redirect_to[\(\s](@order), :?notice/,1] = 'store_url'
    data.msub /('Order was successfully created.')/,
      "\n          'Thank you for your order.'"
    data.msub /,( ):?location/, "\n          "
    data.msub /,( ):?status:?\s=?>?\s?:un/, "\n          "
  end
  edit 'app/models/order.rb' do |data|
    data[/#END:has_many\n()#START:has_many/,1] = <<-EOF.unindent(4)
      #START:add_line_items_from_cart
      # ...
      #START_HIGHLIGHT
      def add_line_items_from_cart(cart)
        cart.line_items.each do |item|
          item.cart_id = nil
          line_items << item
        end
      end
      #END_HIGHLIGHT
      #END:add_line_items_from_cart
    EOF
    edit 'class Order', :mark => 'add_line_items_from_cart'
    edit /^end/, :mark => 'add_line_items_from_cart'
  end
  post '/orders/new', 'order[name]' => ''
  db "select * from orders"
  db "select * from line_items"
  post '/orders/new',
    'order[name]' => 'Dave Thomas',
    'order[address]' => '123 Main St',
    'order[email]' => 'customer@example.com',
    'order[pay_type]' => 'Check'
  db "select * from orders"
  db "select * from line_items"
  if File.exist? 'app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.rjs' do
      clear_highlights
      msub /()/, <<-EOF.unindent(8) + "\n"
        #START_HIGHLIGHT
        page.select("#notice").each { |notice| notice.hide }
        #END_HIGHLIGHT
      EOF
    end
  else
    edit 'app/views/line_items/create.js.erb' do
      clear_highlights
      msub /()/, <<-EOF.unindent(8) + "\n", :highlight
        $("#notice").hide();
      EOF
    end
  end
end

section 12.2, 'Iteration G2: Atom Feeds' do
  overview <<-EOF
    Demonstrate various respond_to/format options, as well as "through"
    relations and basic authentication.
  EOF

  desc 'Define a "who_bought" member action'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.msub /^()end/, "\n" + <<-EOF.unindent(4)
      #START:who_bought
      def who_bought
        @product = Product.find(params[:id])
        respond_to do |format|
          format.xml { render :xml => @product }
        end
      end
      #END:who_bought
    EOF
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add to the routes'
  edit 'config/routes.rb', 'root' do |data|
    data.clear_highlights
    data.edit 'resources :products', :highlight do |products|
      products.all = <<-EOF.unindent(6)
        resources :products do
          get :who_bought, :on => :member
        end
      EOF
    end
    edit ':who_bought' do
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc 'Try again... success... but not much there'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.xml'

  desc 'Add "orders" to the Product class'
  edit 'app/models/product.rb', 'relationships' do
    clear_all_marks
    msub /^( +#\.\.\.\n)/, ''
    edit /class.*has_many.*?\n/m, :mark=>'relationships' do
      self.all += "  #...\n"
    end
    edit /^end/, :mark=>'relationships'
    msub /has_many :line_items\n()/, <<-EOF.unindent(4), :highlight
      has_many :orders, :through => :line_items
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Define an Atom view (using the Atom builder)'
  edit 'app/views/products/who_bought.atom.builder' do |data|
    data.all = <<-'EOF'.unindent(6)
      atom_feed do |feed|
        feed.title "Who bought #{@product.title}"

        latest_order = @product.orders.sort_by(&:updated_at).last
        feed.updated( latest_order && latest_order.updated_at )
      
        @product.orders.each do |order|
          feed.entry(order) do |entry|
            entry.title "Order #{order.id}"
            entry.summary :type => 'xhtml' do |xhtml|
              xhtml.p "Shipped to #{order.address}"

              xhtml.table do
                xhtml.tr do
                  xhtml.th 'Product'
                  xhtml.th 'Quantity'
                  xhtml.th 'Total Price'
                end
                order.line_items.each do |item|
                  xhtml.tr do
                    xhtml.td item.product.title
                    xhtml.td item.quantity
                    xhtml.td number_to_currency item.total_price
                  end
                end
                xhtml.tr do
                  xhtml.th 'total', :colspan => 2
                  xhtml.th number_to_currency \
                    order.line_items.map(&:total_price).sum
                end
              end

              xhtml.p "Paid by #{order.pay_type}"
            end
            entry.author do |author|
              entry.name order.name
              entry.email order.email
            end
          end
        end
      end
    EOF
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add the atom format to the controller'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.clear_highlights
    data.dcl('who_bought') do
      msub /respond_to.*\n()/, <<-EOF.unindent(2), :highlight
        format.atom
      EOF
    end
  end

  desc 'Fetch the Atom feed'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.atom'
  publish_code_snapshot :o

  desc 'Include "orders" in the response'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.dcl('who_bought') do |wb|
      wb.edit 'format.xml', :highlight do |xml|
        xml.msub /@product() \}/, '.to_xml(:include => :orders)'
        xml.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
      end
    end
  end

  desc 'Fetch the xml, see that the orders are included'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.xml'

  desc 'Define an HTML view'
  edit 'app/views/products/who_bought.html.erb' do |data|
    data[/(.*)/m,1] = <<-EOF.unindent(6)
      <h3>People Who Bought <%= @product.title %></h3>

      <ul>
        <% for order in @product.orders %>
          <li>
            <%= mail_to order.email, order.name %>
          </li>
        <% end %>
      </ul>
    EOF
  end

  desc 'Add the html format to the controller'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.clear_highlights
    data.dcl('who_bought') do |wb|
      wb.msub /respond_to.*\n()/, <<-EOF.unindent(2), :highlight
        format.html
      EOF
    end
  end

  desc 'See the (raw) HTML'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought'

  desc 'Anything that XML can do, JSON can too...'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.dcl('who_bought') do |wb|
      xml = wb[/\n(\s+format.xml \{.*?\}\n)/m,1]
      wb.msub /respond_to.*?\n()\s+end/m, xml.gsub('xml','json')
    end
  end

  desc 'Fetch the data in JSON format'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.json'

  desc 'Customize the xml'
  edit 'app/views/products/who_bought.xml.builder' do |data|
    data.all = <<-EOF.unindent(6)
      xml.order_list(:for_product => @product.title) do
        for o in @product.orders
          xml.order do
            xml.name(o.name)
            xml.email(o.email)
          end
        end
      end
    EOF
  end

  desc 'Change the rendering to use templates'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.clear_highlights
    data.dcl('who_bought') do |wb|
      wb.edit 'format.xml', :highlight
      wb.msub /format.xml( \{ render .*)/, ''
    end
  end

  desc 'Fetch the (much streamlined) XML'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.xml'

  # cmd 'rake doc:app'
  # cmd 'rake stats'
  issue 'Consider reducing the number of edits to products_controller'
end

section 12.3, 'Iteration G3: Pagination' do
  unless File.exist? 'public/images'
    desc 'Not supported with Rails 3.1'
    next
  end

  desc 'Add in the will_paginate gem'
  edit 'Gemfile' do
    msub /extra.*\n(?:#.*\n)*()/,  "\ngem 'will_paginate', '>= 3.0.pre'\n",
      :highlight
  end
  unless $bundle
    edit 'config/application.rb' do
      msub /require 'rails\/all'\n()/,  "require 'will_paginate'\n",
      :highlight
    end
  end
  restart_server
  
  cmd 'bundle show'

  desc 'Load in a few orders'
  edit 'script/load_orders.rb' do
    self.all = <<-'EOF'.unindent(6)
      Order.transaction do
        (1..100).each do |i|
          Order.create(:name => "Customer #{i}", :address => "#{i} Main Street",
            :email => "customer-#{i}@example.com", :pay_type => "Check")
        end
      end
    EOF
  end

  runner 'script/load_orders.rb'

  desc 'Modify the controller to do pagination'
  edit 'app/controllers/orders_controller.rb', 'index' do
    dcl 'index', :mark do
      # msub /^()/, "require 'will_paginate'\n", :highlight
      edit 'Order.all', :highlight
      msub /Order\.(all)/, 
        "paginate :page=>params[:page], :order=>'created_at desc',\n" + 
        '      :per_page => 10'
    end
  end

  desc 'Add some navigational aids'
  edit 'app/views/orders/index.html.erb' do
    self << <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <p><%= will_paginate @orders %></p>
      <!-- END_HIGHLIGHT -->
    EOF
    msub /,( ):method/, "\n              "
  end

  desc 'Show the orders'
  get '/orders'
end

section 12.4, 'Playtime' do
  cmd 'rake test'

  edit 'test/functional/orders_controller_test.rb', 'new' do |data|
    data.dcl 'should get new', :mark => 'new' do |getnew|
      empty = getnew.dup
      empty.edit 'assert_response' do |assert|
        assert.msub /assert_(response :success)/, 'redirected_to store_path'
        assert << "\n    assert_equal flash[:notice], 'Your cart is empty'"
      end
      empty.sub! 'should get new', 'requires item in cart'
      empty.dcl 'requires item in cart', :highlight
    
      getnew.msub /do\n()/, <<-EOF.unindent(4) + "\n", :highlight
        cart = Cart.create
        session[:cart_id] = cart.id
        LineItem.create(:cart => cart, :product => products(:ruby))
      EOF

      getnew.msub /()\A/, empty + "\n"
      getnew.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  edit 'test/functional/orders_controller_test.rb', 'valid' do |data|
    data.msub /()require/, "#START:valid\n"
    data.msub /class.*\n()/, <<-EOF.unindent(4)
      # ...
      #END:valid
    EOF

    data.dcl 'should create order', :mark => 'valid' do
      edit /.*(order_path.*)/, :highlight do
        msub /(order_path.*)/, 'store_path'
      end
      self.all <<= "  # ...\n"
    end

    data.msub /(\nend)/, "\n#START:valid\nend\n#END:valid"
  end

  desc 'Update the test data in the fixture'
  edit 'test/fixtures/orders.yml' do
    edit "name: MyString", :highlight do
      sub! /MyString/, 'Dave Thomas'
    end
    edit "email: MyString", :highlight do
      sub! /MyString/, 'dave@example.org' 
    end
    edit 'pay_type: MyString', :highlight do
      sub! /MyString/, 'Check'
    end
  end

  desc 'move a line item from a cart to an order'
  edit 'test/fixtures/line_items.yml' do
    clear_all_marks
    msub /(cart): one/, 'order'
    edit 'order:', :highlight
  end

  cmd 'rake test'

  cmd 'git commit -a -m "Orders"'
  cmd 'git tag iteration-h'
end

section 12.7, 'Iteration J2: Email Notifications' do
  generate 'mailer Notifier order_received order_shipped'
  edit 'app/mailers/notifier.rb' do
    edit 'from', :highlight do
      msub /from:?\s*=?>?\s*(.*)/, "'Sam Ruby <depot@example.com>'"
    end
  end
  publish_code_snapshot :p

  edit 'app/mailers/notifier.rb' do
    %w(order_received order_shipped).each do |notice|
      dcl notice, :mark => notice
      msub /def #{notice}(.*)/, '(order)'
      msub /(.*@greeting.*\n)/, ''
      msub /def #{notice}.*\n()/, <<-EOF.unindent(4)
        @order = order
      EOF
      if notice == 'order_received'
        msub /("to@example.org")/, 
          "order.email, :subject => 'Pragmatic Store Order Confirmation'"
      else
        msub /("to@example.org")/, 
          "order.email, :subject => 'Pragmatic Store Order Shipped'"
      end
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Tailor the confirm receipt email'
  edit 'app/views/notifier/order_received.text.erb' do |data|
    data.all = <<-EOF.unindent(6)
      Dear <%= @order.name %>

      Thank you for your recent order from The Pragmatic Store.

      You ordered the following items:

      <%= render @order.line_items %>

      We'll send you a separate e-mail when your order ships.
    EOF
  end

  desc 'Text partial for the line items'
  edit 'app/views/line_items/_line_item.text.erb' do |data|
    data.all = <<-EOF.unindent(6)
      <%= sprintf("%2d x %s",
                  line_item.quantity,
                  truncate(line_item.product.title, :length => 50)) %>
    EOF
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'HTML partial for the line items'
  edit 'app/views/line_items/_line_item.html.erb' do
    clear_all_marks
  end

  desc 'Tailor the confirm shipped email'
  edit 'app/views/notifier/order_shipped.html.erb' do |data|
    data.all = <<-EOF.unindent(6)
      <h3>Pragmatic Order Shipped</h3>
      <p>
        This is just to let you know that we've shipped your recent order:
      </p>

      <table>
        <tr><th colspan="2">Qty</th><th>Description</th></tr>
      <%= render @order.line_items %>
      </table>
    EOF
  end

# desc 'Partial for the line items (html)'
# edit 'app/views/line_items/_line_item.html.erb' do |data|
#   data.all = <<-EOF.unindent(6)
#     <tr>
#       <td><%= line_item.quantity %></td>
#       <td>&times;</td>
#       <td><%= line_item.product.title %></td>
#     </tr>
#   EOF
# end

  desc 'Update the test case'
  issue "Not helpful: 'Hi, find me in app'" 
  edit 'test/functional/notifier_test.rb' do
    2.times do
      msub /Notifier.order_\w+()$/, '(orders(:one))'
      msub /do()\s+mail =/, "\n#START_HIGHLIGHT"
      msub /mail.body.encoded()\s+end/, "\n#END_HIGHLIGHT"
    end
    gsub! 'Order received', 'Pragmatic Store Order Confirmation'
    gsub! 'Order shipped', 'Pragmatic Store Order Shipped'
    gsub! 'to@example.org', 'dave@example.org'
    gsub! 'from@example.com', 'depot@example.com'
    msub /assert_match (".*?), mail/, '/1 x Programming Ruby 1.9/'
    msub /assert_match ".*?,( )mail/, "\n      "
    msub /assert_match (".*?),\s+mail/, 
      '/<td>1&times;<\/td>\s*<td>Programming Ruby 1.9<\/td>/'
  end

  rake 'db:test:load'
  ruby '-I test test/functional/notifier_test.rb'
end

section 12.8, 'Iteration J3: Integration Tests' do
  edit 'app/controllers/orders_controller.rb', 'create' do
    clear_highlights
    dcl 'create' do
      msub /\n()\s+format/, <<-EOF, :highlight
        Notifier.order_received(@order).deliver
      EOF
    end
  end

  generate 'integration_test user_stories'
  edit "test/integration/user_stories_test.rb" do |data|
    data[/(.*)/m,1] = read('test/user_stories_test.rb')
    unless RUBY_VERSION =~ /^1\.8/
      data.gsub! /\s{3}:/, ':'
      data.gsub! /:(\w+) (\s*)=>/, '\1:\2'
      data.sub! 'order: {', '   order: {'
    end
  end

  rake 'test:integration'
  edit "test/integration/dsl_user_stories_test.rb" do |data|
    data[/(.*)/m,1] = read('test/dsl_user_stories_test.rb')
  end
  rake 'test:integration'

  cmd 'git commit -a -m "Admin"'
  cmd 'git tag iteration-j'
  publish_code_snapshot :q
end

section 13.1, 'Iteration H1: Adding Users' do
  if File.exist? 'public/images'
    generate 'scaffold User name:string hashed_password:string salt:string'
  else
    generate 'scaffold User name:string password_digest:string'
  end
  cmd 'rake db:migrate'
  edit "app/models/user.rb" do
    if File.exist? 'public/images'
      self.all = read('users/user.rb')
    else
      self.all = <<-EOF.unindent(8)
        class User < ActiveRecord::Base
          validates :name, :presence => true, :uniqueness => true
          has_secure_password
        end
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  %w(create update).each do |action|
    edit 'app/controllers/users_controller.rb', action do
      dcl action, :mark do
        edit /.*'.*'.*/, :highlight do
          gsub!("'",'"').sub!('User ', 'User #{@user.name} ')
        end
        msub /redirect_to\(?\s?(@user, ):?notice/, "users_url,\n" + (' ' * 10)
        msub /,( ):?status/, "\n" + (' ' * 10)
        msub /,( ):?status/, "\n" + (' ' * 10) if action == 'create'
      end
    end
  end
  edit 'app/controllers/users_controller.rb', 'index' do
    dcl 'index', :mark do
      edit '.all', :highlight
      msub /\.(all)/, 'order(:name)'
    end
  end
  edit 'app/views/users/index.html.erb' do
    msub /<\/h1>\n()/, <<-EOF.unindent(4), :highlight
      <% if notice %>
        <p id="notice"><%= notice %></p>
      <% end %>
    EOF
    if File.exist? 'public/images'
      msub /(.*<th>Hashed password.*\n)/, ''
      msub /(.*<th>Salt.*\n)/, ''
      msub /(.*user.hashed_password.*\n)/, ''
      msub /(.*user.salt.*\n)/, ''
    else
      msub /(.*<th>Password digest.*\n)/, ''
      msub /(.*user.password_digest.*\n)/, ''
    end
    msub /,() :?method:?\s?=?>? :del/, "\n" + (' ' * 6)
  end
  edit "app/views/users/_form.html.erb" do
    self.all = read('users/new.html.erb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  get '/users'
  post '/users/new',
    'user[name]' => 'dave',
    'user[password]' => 'secret',
    'user[password_confirmation]' => 'secret'
  db 'select * from users'
end

section 13.2, 'Iteration H2: Authenticating Users' do
  generate 'controller Sessions new create destroy'
  generate 'controller Admin index'

  edit "app/controllers/sessions_controller.rb" do |data|
    data.dcl 'create', :mark => 'login' do |create|
      create.msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        user = User.find_by_name(params[:name])
        if user and user.authenticate(params[:password])
          session[:user_id] = user.id
          redirect_to admin_url
        else
          redirect_to login_url, :alert => "Invalid user/password combination"
        end
      EOF
      if File.exist? 'public/images'
        msub /user = (.*)/, 
          'User.authenticate(params[:name], params[:password])'
        msub /user (and .*)/, ''
      end
    end
    data.dcl 'destroy', :mark => 'logout' do |destroy|
      destroy.msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        session[:user_id] = nil
        redirect_to store_url, :notice => "Logged out"
      EOF
    end
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  edit "app/views/sessions/new.html.erb" do |data|
    data[/(.*)/m,1] = read('users/login.html.erb')
  end

  edit "app/views/admin/index.html.erb" do |data|
    data.all = read('users/index.html.erb')
  end

  edit "app/controllers/admin_controller.rb" do |data|
    data.dcl 'index' do |index|
      index.msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        @total_orders = Order.count
      EOF
    end
  end

  edit 'config/routes.rb', 'root' do |data|
    data.clear_highlights
    edit 'admin/index', :highlight do
      msub /(get.*)/, "get 'admin' => 'admin#index'"
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end

    edit 'sessions/new', :highlight do
      self.all = <<-EOF.unindent(6)
        controller :sessions do
          get  'login' => :new
          post 'login' => :create
          delete 'logout' => :destroy
        end
      EOF
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end

    sub! /.*sessions\/create.*\n\n/, ''
    sub! /.*sessions\/destroy.*\n\n/, ''
  end

  post '/login',
    'name' => 'dave',
    'password' => 'secret'
end

section 13.3, 'Iteration H3: Limiting Access' do
  edit "app/controllers/application_controller.rb", 'auth' do
    clear_highlights
    edit /class.*\n/, :mark => 'auth' do
      msub /\n()\Z/, <<-EOF.unindent(6), :highlight
        before_filter :authorize
      EOF
    end

    edit /^end\n/, :mark => 'auth' do
      msub /()^end/, "\n    # ...\n"
      msub /()^end/, "\n" + <<-EOF.unindent(6), :highlight
        protected

          def authorize
            unless User.find_by_id(session[:user_id])
              redirect_to login_url, :notice => "Please log in"
            end
          end
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  %w(sessions store).each do |controller|
    edit "app/controllers/#{controller}_controller.rb", 'setup' do |data|
      data.edit /class.*\n/, :mark => 'setup' do |top|
        top.msub /class.*\n()/, <<-EOF.unindent(8), :highlight
          skip_before_filter :authorize
        EOF
      end
    end
  end

  auth = {
    'carts'      => [:create, :update, :destroy],
    'line_items' => :create,
    'orders'     => [:new, :create],
    'products'   => nil,
    'users'      => nil
  }

  %w(carts line_items orders products users).each do |controller|
    if auth[controller]
      edit "app/controllers/#{controller}_controller.rb", 'setup' do |data|
        data.edit /class.*\n/, :mark => 'setup' do |top|
          top.msub /class.*\n()/, <<-EOF.unindent(8) + "\n", :highlight
            skip_before_filter :authorize, :only => #{auth[controller].inspect}
          EOF
          top.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
        end
      end
    end
  end

  edit "app/views/layouts/application.html.erb" do |data|
    data.clear_highlights
    data.msub /<div id="side">.*?() *<\/div>/m, "\n" + <<-EOF, :highlight
      <% if session[:user_id] %>
        <br />
        <%= link_to 'Orders',   orders_path   %><br />
        <%= link_to 'Products', products_path %><br />
        <%= link_to 'Users',    users_path    %><br />
        <br />
        <%= button_to 'Logout', logout_path, :method => :delete   %>
      <% end %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  publish_code_snapshot :r

  post '/admin', 'submit' => 'Logout'
  get '/'
  get '/products'
  post '/login',
    'name' => 'dave',
    'password' => 'secret'
  get '/products'
  get '/users'
end

section 13.4, 'Iteration H4: Adding a Sidebar' do

  edit "app/models/user.rb" do |data|
    msub /^()end/, "\n" + <<-EOF.unindent(4)
      #START:after_destroy
      after_destroy :ensure_an_admin_remains

      private
        def ensure_an_admin_remains
          if User.count.zero?
            raise "Can't delete last user"
          end
        end     
      #END:after_destroy
    EOF
  end

  edit "app/controllers/users_controller.rb" do |data|
    data[/()  def destroy/,1] = "  #START:delete_user\n"
    data[/def destroy\n.*?  end\n()/m,1] = "  #END:delete_user\n"
    data[/(.*user.destroy.*\n)/,1] = <<-'EOF'.unindent(2)
      #START_HIGHLIGHT
      begin
        @user.destroy
        flash[:notice] = "User #{@user.name} deleted"
      rescue Exception => e
        flash[:notice] = e.message
      end
      #END_HIGHLIGHT
    EOF
  end
end

section 13.5, 'Playtime' do
  desc 'See that requiring a login causes most tests to fail (good!)'
  cmd 'rake test'

  desc 'Cause all tests to do an implicit login'
  edit 'test/test_helper.rb', 'more' do |data|
    data.edit 'class ActiveSupport::TestCase', :mark => 'more'
    data.edit /\n +# Add more.*\nend\n/, :mark => 'more' do |more|
      more.msub /\A()/, <<-EOF.unindent(6)
        # ...
      EOF
      more.msub /^()end/, <<-EOF.unindent(6)
        def login_as(user)
          session[:user_id] = users(user).id
        end

        def logout
          session.delete :user_id
        end

        def setup
          login_as :one if defined? session
        end
      EOF
    end
  end

  desc 'First, lets fix the sessions controller test'
  edit "test/functional/sessions_controller_test.rb" do |data|
    dcl 'should get create' do
      self.all = <<-EOF.unindent(6)
        #START_HIGHLIGHT
        test "should login" do
          dave = users(:one)
          post :create, :name => dave.name, :password => 'secret'
          assert_redirected_to admin_url
          assert_equal dave.id, session[:user_id]
        end
        #END_HIGHLIGHT

        #START_HIGHLIGHT
        test "should fail login" do
          dave = users(:one)
          post :create, :name => dave.name, :password => 'wrong'
          assert_redirected_to login_url
        end
        #END_HIGHLIGHT
      EOF
    end
    dcl 'should get destroy' do
      self.all = <<-EOF.unindent(6)
        #START_HIGHLIGHT
        test "should logout" do
          delete :destroy
          assert_redirected_to store_url
        end
        #END_HIGHLIGHT
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  edit "test/fixtures/users.yml" do |data|
    if File.exist? 'public/images'
      data.msub /(#.*)/, '<% SALT = "NaCl" unless defined?(SALT) %>'
      data.edit /one:.*?\n\n/m do |one|
        one.msub  /name: (.*)/, 'dave'
        one.msub  /salt: (.*)/, '<%= SALT %>'
        one.msub  /hashed_password: (.*)/, 
          "<%= User.encrypt_password('secret', SALT) %>"
      end
    else
      data.edit /one:.*?\n\n/m do |one|
        one.msub  /name: (.*)/, 'dave'
        one.msub  /password_digest: (.*)/, 
          "<%= BCrypt::Password.create('secret') %>"
      end
    end
  end

  ruby '-I test test/functional/sessions_controller_test.rb'

  edit 'test/functional/users_controller_test.rb', 'update' do |data|
    msub /\A()/, "#START:update\n"
    msub /^  end\n()/, "#END:update\n"
    edit /^end/, :mark => 'update'

    data.msub /setup do\n()/, <<-EOF.unindent(2) + "\n"
      #START_HIGHLIGHT
      @input_attributes = {
        :name                  => "sam",
        :password              => "private",
        :password_confirmation => "private"
      }
      #END_HIGHLIGHT
    EOF

    %w(update create).each do |test|
      data.dcl "should #{test} user", :mark => 'update' do
        msub /\A()/, "  #...\n"
        edit 'attributes', :highlight
        sub! '@user.attributes', '@input_attributes'
        edit 'user_path', :highlight
        msub /(user_path.*)/, 'users_path'
      end
    end

    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  cmd 'rake test'

  desc 'Try requesting the xml... see auth failure.'
  cmd 'curl --silent http://localhost:3000/products/3/who_bought.xml'

  issue 'Is this the best way to detect request format?'
  desc 'Enable basic auth'
  edit 'app/controllers/application_controller.rb', 'auth' do |data|
    data.clear_highlights
    data.dcl 'authorize', :mark => 'auth' do |auth|
      auth.gsub! /^      /, '        '
      auth.msub /def authorize\n()/, <<-EOF.unindent(2), :highlight
        if request.format == Mime::HTML 
      EOF
      auth.msub /\n()    end/, <<-EOF.unindent(2), :highlight
        else
          authenticate_or_request_with_http_basic do |username, password|
            user = User.find_by_name(username)
            user && user.authenticate(password)
          end
        end
      EOF
      if File.exist? 'public/images'
        msub /user = (.*\n.*)/, 'User.authenticate(username, password)'
      end
    end
  end

  desc 'Try requesting the xml... see auth succeed.'
  cmd 'curl --silent --user dave:secret http://localhost:3000/products/3/who_bought.xml'
end

section 14.1, 'Playtime' do
  cmd 'rake test'

  cmd 'git commit -a -m "formats"'
  cmd 'git tag iteration-i'
end

section 15.1, 'Task I1: Selecting the locale' do
  
  desc 'Define the default and available languages.'
  edit "config/initializers/i18n.rb" do |data|
    data.all = read('i18n/initializer.rb')
  end
  restart_server

  desc 'Scope selected routes based on locale.  Important: move to bottom!'
  edit 'config/routes.rb' do |data|
    # remove comments, blank lines
    data.gsub! /^\s*#.*\n/, ''
    data.gsub! /\n\s*\n/, "\n"

    # scope selected resources
    nonadmin = data.slice! /^\s*resources.*?root.*?\n/m
    nonadmin.extend Gorp::StringEditingFunctions
    nonadmin.gsub! /.*get "store\/index.*\n/, ''
    nonadmin.gsub! /^/, '  '
    nonadmin.msub /()\s*resource/, "  scope '(:locale)' do\n", :highlight
    nonadmin.msub /root.*\n()/, "  end\n", :highlight

    # append to end
    data.msub /^()end/, nonadmin
  end

  desc "Default locale parameter, and set locale based on locale parameter."
  edit "app/controllers/application_controller.rb", 'i18n' do |data|
    data.clear_all_marks

    data.dcl 'ApplicationController', :mark => 'i18n'

    data.msub /^class.*\n()/, <<-EOF.unindent(4)
      #START_HIGHLIGHT
      before_filter :set_i18n_locale_from_params
      #END_HIGHLIGHT
      # ...
      #END:i18n
    EOF

    data.edit 'protected', :mark => 'i18n'

    data.msub /^()end\n/, "\n" + <<-'EOF'.unindent(2)
      #START:i18n
      #START_HIGHLIGHT
      def set_i18n_locale_from_params
        if params[:locale]
          if I18n.available_locales.include?(params[:locale].to_sym)
            I18n.locale = params[:locale]
          else
            flash.now[:notice] = 
              "#{params[:locale]} translation not available"
            logger.error flash.now[:notice]
          end
        end
      end

      def default_url_options
        { :locale => I18n.locale }
      end
      #END_HIGHLIGHT
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Verify that the routes work."
  get '/en'
  get '/es'

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/layouts/application.html.erb' do |data|
    clear_highlights
    data.gsub! '"Pragmatic Bookshelf"', "t('.title')"
    data.gsub! 'Home', "<%= t('.home') %>"
    data.gsub! 'Questions', "<%= t('.questions') %>"
    data.gsub! 'News', "<%= t('.news') %>"
    data.gsub! 'Contact', "<%= t('.contact') %>"
    data.gsub! /(.*t\('\..*'\))/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(t\('\..*'\).*)/, "\\1\n<!-- END_HIGHLIGHT -->"
  end

  desc 'Replace translatable text with calls out to translation functions.'
  cmd "cp -r #{$DATA}/i18n/*.yml config/locales"

  desc 'Define some translations for the layout.'
  edit('config/locales/en.yml', 'layout') {}
  edit('config/locales/es.yml', 'layout') {} 

  desc 'Format the currency.'
  edit('config/locales/es.yml', 'currency') {} 

  desc 'Server needs to be restarted when introducting a new language'
  restart_server

  desc 'See results'
  get '/es'

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/store/index.html.erb' do
    clear_highlights
    edit 'Your Pragmatic Catalog' do
      gsub! 'Your Pragmatic Catalog', "<%= t('.title_html') %>"
      gsub! /(t\('\..*'\).*)/, "\\1\n<!-- END_HIGHLIGHT -->"
    end
    edit 'Add to Cart' do
      gsub! "'Add to Cart'", "t('.add_html')"
      gsub! /(t\('\..*'\).*)/, "\\1\n# END_HIGHLIGHT"
    end
    gsub! /(.*t\('\..*'\))/, "<!-- START_HIGHLIGHT -->\n\\1"
  end

  desc 'Define some translations for the main page.'
  edit('config/locales/en.yml', 'main') {}
  edit('config/locales/es.yml', 'main') {} 

  desc 'See results'
  get '/es'
end

section 15.2, 'Task I2: translating the store front' do
  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/carts/_cart.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! 'Your Cart', "<%= t('.title') %>"
    data.gsub! '"Checkout"', "t('.checkout')"
    data.gsub! /(t\('\..*'\).*)/, "\\1\n<!-- END_HIGHLIGHT -->"
    data.gsub! "'Empty cart'", "t('.empty')"
    data.gsub! /(.*t\('\..*'\))/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(t\('\.empty'\).*)/, "\\1\n# END_HIGHLIGHT"
  end

  desc 'Define some translations for the cart.'
  edit('config/locales/en.yml', 'cart') {}
  edit('config/locales/es.yml', 'cart') {} 
  
  desc 'Add to Cart'
  post '/es', 'product_id' => 2
end

section 15.3, 'Task I3: Translating Checkout' do
  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/orders/new.html.erb' do
    edit 'Please Enter Your Details', :highlight
    gsub! 'Please Enter Your Details', "<%= t('.legend') %>"
  end

  edit 'app/views/orders/_form.html.erb' do
    clear_highlights
    edit "'Place Order'", :highlight do
      gsub! "'Place Order'", "t('.submit')"
    end
    edit "'Select a payment method'" do
      gsub! "'Select a payment method'", "t('.pay_prompt_html')"
      msub /()$/, "\n<!-- END_HIGHLIGHT -->"
      msub /^()/, "#START_HIGHLIGHT\n"
    end
    edit ':address', :highlight do
      msub /() %>/, ", t('.address_html')"
    end
  end

  desc 'Define some translations for the new order.'
  edit('config/locales/en.yml', 'checkout') {}
  edit('config/locales/es.yml', 'checkout') {} 

  publish_code_snapshot :s
  
  desc 'Add to cart'
  post '/es', 'product_id' => 2

  desc 'Show mixed validation errors'
  post '/es/orders/new', 'submit' => 'Realizar Pedido'

  desc 'Translate the errors to human names.'
  edit('config/locales/es.yml', 'errors') {} 

  edit 'app/views/orders/_form.html.erb' do
    edit '<%= msg %>', :mark => :raw
    msub /<%=() msg %>/, ' raw'

    msub /\A()/, "<!-- START:explanation -->\n"
    msub /<h2>(.*)<\/h2>/m,  ''
    edit '<h2>', :highlight
    msub /(<h2><\/h2>)/, 
      "<h2><%= t('errors.template.header', :count=>@order.errors.size,\n" +
      "        :model=>t('activerecord.models.order')) %>.</h2>\n" +
      "      <p><%= t('errors.template.body') %></p>"
    msub /^  <% end %>\n()/, <<-EOF.unindent(6)
      <!-- ... -->
      <!-- END:explanation -->
    EOF
    gsub! /:(\w+)=>/, '\1: \2' unless RUBY_VERSION =~ /^1\.8/ # add a space
  end

  desc 'Translate the model names to human names.'
  edit 'config/locales/es.yml', 'model' do
    msub /activerecord:\n#END:errors\n()#END:model/, <<-EOF.unindent(2)
      models:
        order:       "pedido"
      attributes:
        order:
          address:   "Direcci&oacute;n"
          name:      "Nombre"
          email:     "E-mail"
          pay_type:  "Forma de pago"
    EOF
  end

  desc 'Show validation errors'
  post '/es/orders/new', 'submit' => 'Realizar Pedido'

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/controllers/orders_controller.rb', 'create' do |data|
    data.clear_highlights
    data.dcl 'create', :mark => 'create' do |create|
      create.edit  "'Thank you for your order.'", :highlight
      create.gsub! "'Thank you for your order.'", "I18n.t('.thanks')"
    end
  end

  desc 'Define some translations for the flash.'
  edit('config/locales/en.yml', 'flash') {}
  edit('config/locales/es.yml', 'flash') {} 

  desc 'Place the order'
  post '/es/orders/new',
    'order[name]' => 'Joe User',
    'order[address]' => '123 Main St., Anytown USA',
    'order[email]' => 'juser@hotmail.com',
    'order[pay_type]' => 'Check'
end

section 15.4, 'Task I4: Add a locale switcher.' do
  desc 'Add form for setting and showing the site based on the locale.'
  desc 'Use CSS to position the form.'
  edit DEPOT_CSS, 'i18n' do |data|
    data << "\n" + <<-EOF.unindent(6)
      /* START:i18n */
      .locale {
        float: right;
        margin: -0.25em 0.1em;
      }
      /* END:i18n */
    EOF
  end

  desc "When provided, save the locale in the session."
  edit "app/controllers/store_controller.rb", 'index' do |data|
    data.dcl 'index' do |index|
      index.gsub! /^    /,'      '
      index.msub /def.*\n()/, <<-EOF.unindent(4), :highlight
        if params[:set_locale]
          redirect_to store_path(:locale => params[:set_locale])
        else
      EOF
      index.msub /^()\s+end/, <<-EOF.unindent(4), :highlight
        end
      EOF
      index.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  edit 'app/views/layouts/application.html.erb', 'i18n' do
    clear_highlights
    edit /^\s+<div id="banner">.*?<\/div>\n/m, :mark => 'i18n'
    msub /\n()\s+<%= image_tag/, <<-EOF.unindent(2), :highlight
      <%= form_tag store_path, :class => 'locale' do %>
        <%= select_tag 'set_locale', 
          options_for_select(LANGUAGES, I18n.locale.to_s),
          :onchange => 'this.form.submit()' %>
        <%= submit_tag 'submit' %>
        <%= javascript_tag "$('.locale input').hide()" %>
      <% end %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Try out the form"
  post '/en', 'set_locale' => 'es'
  rake 'test'
end

section 16, 'Deployment' do
  Dir.chdir(File.join($WORK, 'depot'))
  cmd 'git add .'
  cmd 'git commit -a -m "save work"'
  edit 'config/database.yml' do
    # edit 'production.sqlite3', :highlight
    # msub %r((db)/production.sqlite3), '../../shared/db'
    msub /^(production:.*)/m, <<-EOF.unindent(6), :mark => 'production'
      production:
        adapter: mysql
        encoding: utf8
        reconnect: false
        database: depot_production
        pool: 5
        username: username
        password: password
        host: localhost
    EOF
  end
  edit 'Gemfile' do
    clear_all_marks
    msub /sqlite.*\n()/, <<-EOF.unindent(6), :mark => 'mysql'
      group :production do
        gem 'mysql'
      end
    EOF
    edit 'capistrano', :highlight
    msub /^(# )gem .capistrano/, ''
  end
  cmd 'bundle install'

  #
  # mysql -u root
  # > GRANT ALL PRIVILEGES ON depot_production.*
  #   TO 'username'@'localhost' IDENTIFIED BY 'password';
  #

  rake 'db:setup RAILS_ENV=production'
  cmd 'bundle pack'
  cmd 'capify .'
  edit 'config/deploy.rb' do
    self.all = read('config/deploy.rb')
  end
  if File.exist? 'public/images'
    edit 'config/environments/production.rb' do
      msub /^()end/, "\n" + <<-EOF.unindent(4)
        require 'active_support/core_ext/numeric/bytes'
        config.logger = Logger.new(paths.log.first, 2, 10.kilobytes)
      EOF
    end
    console "Depot::Application.configure { paths.log.first }", 'production'
  else
    rake 'assets:precompile'
    cmd 'ls public/assets'
    edit 'config/environments/production.rb' do
      msub /^()end/, "\n" + <<-EOF.unindent(4)
        require 'active_support/core_ext/numeric/bytes'
        config.logger = Logger.new(paths['log'].first, 2, 10.kilobytes)
      EOF
    end
    console "Depot::Application.configure { paths['log'].first }", 'production'
  end
  cmd 'git st'
end

section 17, 'Retrospective' do
  edit 'doc/README_FOR_APP' do
    self.all = read('README_FOR_APP')
  end
  rake 'doc:app'
  rake 'stats'
end

section 18, 'Finding Your Way Around' do
  cmd 'rake db:version'
  edit 'lib/tasks/db_schema_migrations.rake' do |data|
    data << <<-EOF.unindent(6)
      namespace :db do
        desc "Prints the migrated versions"
        task :schema_migrations => :environment do
          puts ActiveRecord::Base.connection.select_values(
            'select version from schema_migrations order by version' )
        end
      end
    EOF
  end
  cmd 'rake db:schema_migrations'
  cmd 'ls log'
  cmd 'find script -type f'
  console 'puts $:'
end

section 19, 'Active Record' do
  edit 'config/initializers/inflections.rb' do
    self << "\n" + <<-EOF.unindent(6)
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular 'tax', 'taxes'
      end
    EOF
  end

end

section 20.1, 'Testing Routes' do
  edit 'test/unit/routing_test.rb' do
    self.all = read('test/routing_test.rb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  rake 'test:units'
end

section 21.1, 'Views' do
  edit 'app/views/products/index.xml.builder' do
    self.all = read('products/index.xml.builder')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/controllers/products_controller.rb', 'index' do
    dcl 'index', :mark => 'index' do
      if self =~ /format\.xml/
        msub /format.xml(.*)/, '  # index.xml.builder'
      else
        msub /format.html.*\n()/, "      format.xml\n"
      end
    end
  end
  cmd 'curl --silent --user dave:secret http://localhost:3000/products.xml'
  irb 'helpers/date.rb'
  irb 'helpers/number.rb'
  publish_code_snapshot :t
end

section 21.2, 'Form Helpers' do
  rails 'views'
  generate 'model model input:string address:text color:string ' +
    'ketchup:boolean mustard:boolean mayonnaise:boolean start:date ' +
    'alarm:time'
  generate 'controller Form input'
  rake 'db:migrate'
  restart_server

  edit 'app/views/form/input.html.erb' do
    self.all = read('form/input.html.erb')
  end
  get '/form/input'

  publish_code_snapshot nil, :views
end

section 22, 'Caching' do
# Dir.chdir(File.join($WORK,'views'))
# generate 'model article body:text'
# cmd 'rake db:migrate'
# cmd "cp -v #{$CODE}/e1/views/app/models/article.rb app/models"
# cmd "cp -vr #{$CODE}/e1/views/app/views/blog app/views"
# get '/blog/list'
# cmd "cp -vr #{$CODE}/e1/views/app/views/blog1 app/views"
# get '/blog1/list'
# cmd "cp -vr #{$CODE}/e1/views/app/views/blog2 app/views"
# get '/blog2/list'

  Dir.chdir(File.join($WORK,'depot'))
  restart_server
  cmd 'curl --silent --head http://localhost:3000/'

  desc "add a method to return the latest product"
  edit 'app/models/product.rb' do
    clear_all_marks
    msub /\n()\s+private/, "\n" + <<-EOF.unindent(4) + "\n", :highlight
      def self.latest
        Product.order('updated_at desc').limit(1).first
      end
    EOF
  end

  desc "set ETAG and LastModified headers on the response"
  edit 'app/controllers/store_controller.rb' do
    dcl 'index' do
      msub /^()  end/, "\n" + <<-EOF.unindent(4)
        latest = Product.latest
        fresh_when :etag => latest, :last_modified => latest.created_at.utc
        expires_in 10.minutes, :public => true
      EOF
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  cmd 'curl --silent --head http://localhost:3000/'
  response = Net::HTTP.get_response(URI.parse('http://localhost:3000/'))

  cmd "curl --silent --head http://localhost:3000/ " +
    "-H 'If-None-Match: #{response['Etag']}'"

  cmd "curl --silent --head http://localhost:3000/ " +
    "-H 'If-Modified-Since: #{response['Last-Modified']}'"

  unless File.exist? 'public/images'
    desc "Turn on caching in development"
    edit 'config/environments/development.rb' do
      edit 'perform_caching', :highlight do
        msub /perform_caching = (false)/, 'true'
      end
    end
  end

  restart_server
  cmd 'curl --silent --head http://localhost:3000/'
  response = Net::HTTP.get_response(URI.parse('http://localhost:3000/'))
  cmd 'curl --silent --head http://localhost:3000/ ' +
    "-H 'If-None-Match: #{response['Etag']}'"
end

section 24.3, 'Active Resources' do
  rails 'depot_client'
  edit 'app/models/product.rb' do |data|
    data << <<-EOF.unindent(6)
      class Product < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/'
      end
    EOF
  end
  console 'Product.find(2).title'
  Dir.chdir(File.join($WORK,'depot'))
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    clear_all_marks
    dcl 'create', :mark do
      msub /\n()\s+product = Product.find/, <<-EOF.unindent(4), :highlight
        if params[:line_item]
          # ActiveResource
          params[:line_item][:order_id] = params[:order_id]
          @line_item = LineItem.new(params[:line_item])
        else
          # HTML forms
      EOF
      msub /\n()\s+product = Product.find/, '  '
      msub /\n()\s+@line_item = @cart.add/, '  '
      msub /@line_item = @cart.add.*\n()/, <<-EOF.unindent(4), :highlight
        end
      EOF
    end
  end
  edit 'config/routes.rb' do |data|
    clear_all_marks
    edit 'resources :orders', :highlight
    data[/resources :orders()/,1] = 
      " do\n      resources :line_items\n    end\n"
  end
  # restart_server
  Dir.chdir(File.join($WORK,'depot_client'))
  console 'Product.find(2).title'
  if File.exist? 'public/images'
    console 'p = Product.find(2)\nputs p.price\np.price -= 5\np.save'
  else
    console 'p = Product.find(2)\nputs p.price\n' +
      'p.price = BigDecimal.new(p.price)-5\np.save'
  end

  desc 'expire cache'
  cmd 'rm -rf tmp/cache/rack/*'

  desc 'fetch storefront'
  get '/'

  desc 'fetch product (fallback in case storefront is cached)'
  post '/login',
    'name' => 'dave',
    'password' => 'secret'
  get '/products/2'

  edit 'app/models/order.rb' do |data|
    data << <<-EOF.unindent(6)
      class Order < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/'
      end
    EOF
  end
  console 'Order.find(1).name\nOrder.find(1).line_items\n'
  edit 'app/models/line_item.rb' do |data|
    data << <<-EOF.unindent(6)
      class LineItem < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/orders/:order_id'
      end
    EOF
  end
  post '/admin', {'submit' => 'Logout'}, {:snapget => false}
  console 'LineItem.find(:all, :params => {:order_id=>1})'
  if File.exist? 'public/images'
    console 'li = LineItem.find(:all, :params => {:order_id=>1}).first\n' +
         'puts li.price\nli.price *= 0.8\nli.save'
  else
    get '/orders/1/line_items.json', :auth => ['dave', 'secret']
    Dir.chdir(File.join($WORK,'depot')) do
      edit 'app/controllers/line_items_controller.rb', 'index' do
        dcl 'index', :mark => 'index' do
          msub /format.json.*\n()/, 
            "      format.xml { render :xml => @line_items }\n"
        gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
        end
      end
    end
  end
  get '/orders/1/line_items.xml', :auth => ['dave', 'secret']
  console 'LineItem.format = :xml\n' +
       'li = LineItem.find(:all, :params => {:order_id=>1}).first\n' +
       'puts li.price\nli.price *= 0.8\nli.save'
  console 'li2 = LineItem.new(:order_id=>1, :product_id=>2, :quantity=>1, ' +
       ':price=>0.0)\nli2.save'
       'li2.save'
  publish_code_snapshot nil, 'depot_client'
end

section 25.1, 'rack' do
  Dir.chdir(File.join($WORK,'depot'))

  edit 'store.ru' do
    self.all = read('rack/store.ru')
  end

  edit 'app/store.rb' do
    self.all = read('rack/store.rb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  edit 'config/routes.rb' do
    clear_highlights
    msub /^()/, <<-EOF.unindent(6), :highlight
      require './app/store'
    EOF
    msub /do\n()/, <<-EOF.unindent(4), :highlight
      match 'store' => StoreApp.new
    EOF
  end

  get '/store'
end

section 25.2, 'rake' do
  desc 'implement a custom rake task'
  edit "lib/tasks/db_backup.rake" do
    self.all = read('depend/db_backup.rake')
  end
  rake "db:backup"

  desc 'cleanup (for HAML)'
  edit 'app/views/store/index.html.erb', 'none' do 
    clear_all_marks
  end

  publish_code_snapshot :u

  desc 'remove scaffolding needed for standalone operation'
  edit 'app/store.rb' do
    msub /(.*?)class StoreApp/m, ''
  end
end

section 26.1, 'Active Merchant' do
  desc 'Determine if a credit card is valid'
  edit 'Gemfile', 'plugins' do
    clear_all_marks
    if File.exist? 'public/images'
      edit 'will_paginate', :mark => 'plugins'
      msub /paginate.*\n()/, <<-EOF.unindent(8), :highlight
        gem 'activemerchant', '~> 1.10.0'
      EOF
    else
      msub /()\Z/, "\n\n" + <<-EOF.unindent(8)
        gem 'activemerchant'
      EOF
      edit 'activemerchant', :mark => 'plugins'
      edit 'activemerchant', :highlight
    end
  end
  cmd 'bundle install'
  edit 'script/creditcard.rb' do
    self.all = read('script/creditcard.rb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  ENV.delete('BUNDLE_GEMFILE')
  runner 'script/creditcard.rb'

  `rake about 2> /dev/null > /dev/null`
  unless $?.success?
    edit 'Gemfile', 'plugins' do
      msub /()gem 'activemerchant'/, '# '
    end
  end
end

if File.exist? 'public/images'
  section 26.2, 'Asset Packager' do

    Dir.chdir(File.join($WORK,'depot'))
    overview <<-EOF
      Minimize scripts and stylesheets
    EOF

    desc 'rails plugin install git://github.com/sbecker/asset_packager.git'
    # cmd "mkdir -p vendor/plugins"
    cmd "cp -rpv #{$DATA}/plugins/asset_packager vendor/plugins/"

    desc 'list the new tasks introduced'
    rake '-T asset'

    desc 'inventory existing assets'
    rake 'asset:packager:create_yml'

    desc 'Look at the file that was produced'
    cmd 'cat config/asset_packages.yml'

    desc 'produce a minimized version'
    rake 'asset:packager:build_all'

    edit 'app/views/layouts/application.html.erb', 'head' do
      clear_all_marks
      msub /()<!DOCTYPE/, "<!-- #START:head -->\n"
      msub /<\/head>\n()/, "<!-- ... -->\n<!-- END:head -->\n"
      edit 'stylesheet_link_tag', :highlight do
	msub /link_(tag.*) %>/, 'merged :base'
	msub /<%=() /, ' raw'
      end
      edit 'javascript_include_tag', :highlight do
	msub /include_(tag.*) %>/, 'merged :base'
	msub /<%=() /, ' raw'
      end
    end
  end
end

section 26.3, 'HAML' do
  edit 'Gemfile', 'plugins' do
    msub /activemerchant.*\n()/, <<-EOF.unindent(6), :highlight
      gem 'haml', '~> 3.1.1'
    EOF
  end
  cmd 'bundle install'

  cmd %{rails runner "require \'haml\'"}
  `rails runner "require 'haml'" 2> /dev/null > /dev/null`
  unless $?.success?
    edit 'Gemfile', 'plugins' do
      msub /()gem 'haml'/, '# '
    end
    next
  end

  restart_server
  cmd 'cat app/views/store/index.html.erb'
  cmd 'rm app/views/store/index.html.erb'
  edit 'app/views/store/index.html.haml' do
    self.all = read('plugins/index.html.haml')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  get '/'
end

if File.exist? 'public/images'
  section 26.4, 'JQuery' do
    edit 'Gemfile', 'plugins' do
      msub /haml.*\n()/, <<-EOF.unindent(8), :highlight
	gem 'jquery-rails', '~> 0.2.2'
      EOF
    end
    cmd 'bundle install'
    generate 'jquery:install --ui --force'
    edit 'app/views/line_items/create.js.rjs' do
      clear_all_marks
    end
    cmd 'rm app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.erb' do
      self.all = read('plugins/create.js.erb')
    end
    edit 'app/views/layouts/application.html.erb', 'banner' do
      msub /()\s+<div/, "\n<!-- #START:banner -->\n<!-- ... -->"
      msub /<\/div>\n()/, "<!-- ... -->\n<!-- END:banner -->\n"
      edit 'javascript_tag', :highlight do
	msub /"(.*)"/, "$('.locale input').hide()"
      end
    end
    rake 'test'
    edit 'test/functional/line_items_controller_test.rb', 'ajax' do
      clear_all_marks
      dcl "should create line_item via ajax", :mark => 'ajax' do
	edit ':replace_html', :highlight do
	  msub /assert_select_(rjs .*) do/, "jquery :html, '#cart'"
	end
      end
    end
    rake 'test'
    edit 'config/asset_packages.yml' do
      if include? 'dragdrop'
	msub /\s+- (dragdrop)\n/, 'jquery'
	msub /\s+- (effects)\n/, 'jquery-ui'
	msub /(\s+- controls)\n/, ''
	msub /(\s+- prototype)\n/, ''
      else
	msub /().*prototype\n/, "  - jquery\n"
	msub /\s+- (prototype)\n/, 'jquery-ui'
      end
    end
    rake 'asset:packager:build_all'
    rake "db:seed"
  end
end

section 99, 'cleanup' do
  publish_code_snapshot :v

  unless File.exist? 'public/images'
    desc "Turn caching back off"
    edit 'config/environments/development.rb' do
      msub /perform_caching = (true)/, 'false'
    end
    cmd 'rm -f public/assets/*'
    cmd 'rm -rf tmp/*cache/*'
    restart_server
  end
end

# what version of Rails are we running?
if `#{Gorp.which_rails($rails)} -v` =~ /^Rails 2/
  STDERR.puts 'This scenario is for Rails 3'
  Process.exit!
end

required = %w(will_paginate rdoc nokogiri htmlentities)
required.push 'rails' if $rails == 'rails'
required.push 'test-unit' if RUBY_VERSION =~ /^1\.9/
required -= `gem list`.scan(/(^[-_\w]+)\s\(/).flatten

# only one of nokogiri and htmlentities are required
required.delete('nokogiri') or required.delete('htmlentities')
required.delete('will_paginate') or required.delete('mislav-will_paginate')

unless required.empty?
  required.each do |gem|
    STDERR.puts "Missing gem: #{gem}"
  end
  Process.exit!
end

# verify that required libraries are present
fail = false
%w().each do |lib|
  unless $:.any? {|path| File.exist? File.join(path,lib)}
    STDERR.puts "Missing library: #{lib}"
    fail = true
  end
end
Process.exit! if fail

# verify that MySQL is installed and permissions are granted
begin
  require 'mysql'
  configs = %w(mysql_config mysql_config5)
  config = configs.find {|config| not `which #{config}`.empty?}
  socket = `#{config} --socket`.chomp
  dbh = Mysql.real_connect("localhost", "username", "password", nil, 0, socket)
  unless dbh.list_dbs.include?('depot_production')
    dbh.query('create database depot_production')
  end
rescue Exception => e
  puts "MySQL: #{e}"
  Process.exit!
end


$cleanup = Proc.new do
  # fetch stylesheets
  if File.exist?(File.join($WORK,'depot/public/stylesheets'))
    Dir[File.join($WORK,'depot/public/stylesheets/*.css')].each do |css|
      File.open(css) {|file| $style.text! file.read}
    end
  else
    require 'sass'
    Dir[File.join($WORK,'depot/app/assets/stylesheets/*.css*')].each do |css|
      text = File.read(css)
      next if text =~ /\A\/\*[^*]*\*\/\s*\Z/ # nothing but a single comment
      text = Sass::Engine.new(text, :syntax => :scss).render if css =~ /\.scss/
      $style.text! text
    end
  end

  # Link static files
  system "ln -f -s #{$DATA} #{$WORK}"
end

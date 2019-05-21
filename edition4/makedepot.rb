require 'rubygems'
require 'gorp'

Gorp::Config.load('~/.awdwr')

include Gorp::Commands

# what version of Rails are we running?
$rails_version = `#{Gorp.which_rails($rails)} -v 2>#{DEV_NULL}`.split(' ').last
if $rails_version =~ /^2/
  STDERR.puts 'This scenario is for Rails 3'
  Process.exit!
end

if $rails_version =~ /^[34]/
  $title = 'Agile Web Development with Rails, Edition 4'
  DEPOT_CSS = "app/assets/stylesheets/application.css.scss"
elsif $rails_version =~ /^[5]/
  $title = 'Agile Web Development with Rails, Edition 5'
  DEPOT_CSS = "app/assets/stylesheets/application.scss"
else
  $title = 'Agile Web Development with Rails, Edition 6'
  DEPOT_CSS = "app/assets/stylesheets/application.scss"
end

$autorestart = 'depot'
$output = 'makedepot'
$checker = 'checkdepot'


begin
  require './pub_gorp'
rescue LoadError => ex
  def publish_code_snapshot *args
  end

  def publish_screenshot *args
  end
end

omit 100..199

section 2, 'Instant Gratification' do
  overview <<-EOF
    We start with a simple "hello world!" demo application
    and in the process verify that everything is installed correctly.
  EOF

  desc 'Create the application'
  ENV.delete('BUNDLE_GEMFILE')
  rails 'demo1', :work

  restart_server
  get "/", screenshot: { 
    filename: "demo2_1_hello_rails.pdf", 
    dimensions: [ 700, 700 ],
    scale: 0.4
  }

  desc 'See what files were created'
  cmd 'ls -p'

  desc 'Create a simple controller'
  generate 'controller Say hello goodbye'
  edit 'app/controllers/say_controller.rb' do
    dcl 'hello', :highlight
  end

  restart_server

  desc 'Attempt to fetch the file - note that it is missing'
  get '/say/hello', screenshot: { filename: "demo2_2_hello_missing.pdf", dimensions: [320,200] }

  desc 'Replace file with a simple hello world'
  edit 'app/views/say/hello.html.erb' do
    self.all = <<-EOF.unindent(6)
      <h1>Hello from Rails!</h1>
    EOF
  end

  desc 'This time it works!'
  get '/say/hello', screenshot: { filename: "demo2_3_hello_works.pdf", dimensions: [320,200] }
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
  get '/say/hello', screenshot: { filename: "demo2_4_hello_time.pdf", dimensions: [ 320, 200 ] }
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
  get '/say/goodbye', screenshot: { filename: "demo4_1_goodbye.pdf", dimensions: [ 320, 200 ] }
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
  get '/say/hello', screenshot: { filename: "demo5_1_goodbye_link.pdf", dimensions: [ 320, 200 ] }

  desc 'Add a link back to the hello page'
  edit 'app/views/say/goodbye.html.erb' do
    msub /<\/p>\n()/, <<-EOF.unindent(6), :highlight
      <p>
        Say <%= link_to "Hello", say_hello_path %> again.
      </p>
    EOF
  end
  get '/say/goodbye'

  desc 'Intentionally introduce a typo in the code'
  edit 'app/controllers/say_controller.rb' do
   sub! 'Time.now', 'Time.know'
  end
  get '/say/hello', screenshot: { filename: "demo5_2_typo.pdf", dimensions: [ 320, 200 ] }

  desc 'Intentionally introduce a typo in a URL'
  get '/say/hullo', screenshot: { filename: "demo5_2_route_typo.pdf", dimensions: [ 320, 200 ] }

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

  if Gorp::Config[:protect_from_forgery] == false
    if File.read('app/controllers/application_controller.rb').include? \
      'protect_from_forgery'
    then
      warn 'Disable forgery protection in order to make progress on tests'
      edit 'app/controllers/application_controller.rb' do
        msub /protect_from_forgery.*\n()/, \
          "  skip_before_action :verify_authenticity_token\n"
      end
    end
  end

  desc 'Look at the files created.'
  cmd 'ls -p'

  overview <<-EOF
    Generate scaffolding for a real model, modify a template, and do
    our first bit of data entry.
  EOF

  desc 'Generating our first model and associated scaffolding'
  generate :scaffold, :Product,
    'title:string description:text image_url:string price:decimal'

  if File.read('app/controllers/products_controller.rb').include? 'location'
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
      dcl 'destroy' do
        msub /,( ):?notice/, "\n          " if self =~ /notice/
      end
      sub! /(, only allow the white) (list through\.)$/, "\\1\n    # \\2"
    end
  end

  edit 'app/views/products/index.html.erb' do
    msub /,( ):?method/, "\n            "
  end

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
  db :migrate

  restart_server

  desc 'Get an (empty) list of products'
  get '/products', screenshot: { filename: "a_1_products.pdf", dimensions: [ 320,200] }
  get '/products/new', screenshot: { filename: "a_2_new_product.pdf", dimensions: [ 320,400] }

  desc 'Show (and modify) one of the templates produced'
  edit 'app/views/products/_form.html.erb' do
    msub /<%= pluralize.*%>( )/, "\n      "
    edit 'text_area :description', :highlight do
      msub /() %>/, ', rows: 10, cols: 60'
    end
  end

  desc 'Create a product'
  new_product_title = 'Docker for Rails Developers'
  new_product_description = %{
<p>
  <em>Build, Ship, and Run Your Applications
  Everywhere</em> Docker does for DevOps what Rails did
  for web development—it gives you a new set of
  superpowers. Gone are “works on my machine” woes and
  lengthy setup tasks, replaced instead by a simple,
  consistent, Docker-based development environment that
  will have your team up and running in seconds.
</p>
}
  new_product_price = "38.00"
  new_product_image_url = "ridocker.jpg"
  get '/products/new', screenshot: {
    filename: "a_3_new_product_filled_in.pdf",
    form_data: {
      '#product_title' => new_product_title,
      '#product_description' => new_product_description,
      '#product_price' => new_product_price,
      '#product_image_url' => new_product_image_url
    }
  }
  post '/products/new',
    'product[title]' => new_product_title,
    'product[description]' => new_product_description,
    'product[price]' => new_product_price,
    'product[image_url]' => new_product_image_url

  desc 'Verify that the product has been added'
  get '/products', screenshot: { filename: "a_4_added_product.pdf", dimensions: [ 720,380] }

  desc "And, just to verify that we haven't broken anything"
  test
end

section 6.2, 'Iteration A2: Making Prettier Listings' do
  overview <<-EOF
    Show the relationship between various artifacts: seed data,
    stylesheets, html, and images.
  EOF

  if File.exist? 'public/images'
    desc 'Copy some images and a stylesheet'
    cmd "cp -v #{$DATA}/images/* public/images/"
    cmd "cp -v #{$DATA}/depot.css public/stylesheets"
    DEPOT_CSS[0..-1] = "public/stylesheets/depot.css"
  else
    desc 'Copy some images'
    cmd "cp -vp #{$DATA}/assets/* app/assets/images/"

    if $rails_version =~ /^4\.2/
      desc 'Workaround for sprockets-rails issue 321'
      restart_server 
    end

    desc 'Add some style'
    edit "app/assets/stylesheets/products*.scss" do
      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, read('products.css.scss')
    end
  end

  desc 'Load some "seed" data'
  edit "db/seeds.rb", 'vcc' do |data|
    data.all = read('products/seeds.rb')
    data.gsub! '/images/', '' unless File.exist? 'public/images'
    data.gsub! /:(\w+) =>/, '\1:' unless RUBY_VERSION =~ /^1\.8/
  end
  db :seed

  desc 'Link to the stylesheet in the layout'
  edit 'app/views/layouts/application.html.erb' do
    clear_highlights
    msub /^(    <%= yield %>)/,%{
    <!-- START_HIGHLIGHT -->
    <main class='<%= controller.controller_name %>'>
      <%= yield %>
    </main>
    <!-- END_HIGHLIGHT -->
}
    if self =~ /, ['"]data-turbolinks-track['"]/
      msub /,( )['"]data-turbolinks-track['"]/, "\n    "
    end
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
  get '/products', screenshot: { filename: "a_5_styled_products.pdf", dimensions: [ 800,400] }
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
  cmd 'git config --get-regexp user.*'

  desc 'Look at the .gitignore that Rails helpfully provided...'
  edit '.gitignore', 'files' do
    msub /#.*\n\s*()\n/, "\n# START:files"
    msub /()\Z/, "\n# END:files"
  end
  
  unless File.exist? '.git'
    desc 'Initialize repository.'
    cmd 'git init'
  end

  desc 'Add all the files.'
  cmd 'git add .'

  desc 'Initial commit.'
  cmd 'git commit -m "Depot Scaffold"'

  edit "test/fixtures/products.yml" do
    msub /^# Read about fixtures at() http.{50}/, "\n#", :optional
  end
  publish_code_snapshot :a
end

section 7.1, 'Iteration B1: Validation and Unit Testing' do
  overview <<-EOF
    Augment the model with a few vailidity checks.
  EOF

  desc 'Various validations: required, numeric, positive, and unique'
  edit 'app/models/product.rb' do
    msub /^()end/, <<-'EOF'.unindent(6)
      #START:validation
      #START:val1
        validates :title, :description, :image_url, :presence => true
      #END:val1
      # #START:val3
        validates :title, :uniqueness => true
      #END:val3
      #START:val4
        validates :image_url, :allow_blank => true, :format => {
          :with    => %r{\.(gif|jpg|png)\Z}i,
          :message => 'must be a URL for GIF, JPG or PNG image.'
        }
      #END:val4
      #END:validation
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  desc 'Demonstrate failures.'
  post '/products/new',
    { 'product[price]' => '0.0' },
    screenshot: { filename: "b_1_validation_errors.pdf", dimensions: [ 640, 720 ], submit_form: true }

  desc 'Add price validations'
  edit 'app/models/product.rb' do
    msub /#END:validation()/,%{
  #START:val2
  validates :price, numericality: { greater_than_or_equal_to: 0.01 }
  #END:val2
}
  end


  desc 'Demonstrate more failures.'
  post '/products/new', {
    'product[title]' => 'Pragmatic Unit Testing',
    'product[description]' => <<-EOF.unindent(6),
      A true masterwork.  Comparable to Kafka at
      his funniest, or Marx during his slapstick
      period.  Move over, Tolstoy, there's a new
      funster in town.
    EOF
    'product[image_url]' => 
      (File.exist?('public/images') ? '/images/utj.jpg' : 'utj.jpg'),
    'product[price]' => 'wibble' },
    screenshot: { filename: "b_2_price_validation_errors.pdf", dimensions: [ 640, 720 ], submit_form: true }

  edit 'app/models/product.rb' do |data|
    data.sub! /\s:allow_blank.*,/, ''
    data.sub! /0.00/,  '0.01'
  end

  desc 'Now run the tests... and watch them fail :-('
  test

  desc 'Solution is simple, provide valid data.'
  edit 'test/*/products_controller_test.rb', 'valid' do
    msub /()require/, "#START:valid\n"

    msub /@product = products\(:one\)()/,%{
    # START_HIGHLIGHT
    @title = "The Great Book \#{rand(1000)}"
    # END_HIGHLIGHT
}
    msub /()test "should get index" do/,%{
# END:valid
  }


    msub /()test "should create product" do/,%{
# START:should_create_product
  }

    msub /()test "should show product" do/,%{
# END:should_create_product
  }

    msub /(post products_url.*$)/,%{
    post products_url, params: { 
        product: { 
          description: @product.description, 
          image_url: @product.image_url, 
          price: @product.price, 
          # START_HIGHLIGHT
          title: @title,
          # END_HIGHLIGHT
        }
      }
    }

    msub /()test "should update product" do/,%{
# START:should_update_product
  }

    msub /(patch product_url.*$)/,%{
    patch product_url(@product), params: { 
        product: { 
          description: @product.description, 
          image_url: @product.image_url, 
          price: @product.price, 
          # START_HIGHLIGHT
          title: @title,
          # END_HIGHLIGHT
        }
      }
    }
    msub /()test "should destroy product" do/,%{
# END:should_update_product
  }
  end

  desc 'Onto the next failure...'
  test

  desc 'Update test data'
  edit "test/fixtures/products.yml" do
    edit 'image_url: MyString', :highlight do
      sub! 'MyString', 'lorem.jpg'
    end
    edit 'image_url: MyString', :highlight do
      sub! 'MyString', 'lorem.jpg'
    end
  end

  desc 'Tests now pass again :-)'
  test
end

section 7.2, 'Iteration B2: Unit Testing' do
  overview <<-EOF
    Introduce the importance of unit testing.
  EOF

  desc 'Look at what files are generated'
  if File.exist? 'test/unit'
    cmd 'ls test/unit'
  else
    cmd 'ls test/models'
  end

  desc 'Add some unit tests for new function.'
  edit "test/*/product_test.rb" do
    msub /class ProductTest < ActiveSupport::TestCase()/, %{
  
  #START:test_empty_attributes
  test "product attributes must not be empty" do
    product = Product.new
    assert product.invalid?
    assert product.errors[:title].any?
    assert product.errors[:description].any?
    assert product.errors[:price].any?
    assert product.errors[:image_url].any?
  end
  #END:test_empty_attributes
}
  end

  publish_code_snapshot :b

  edit "test/*/product_test.rb" do
    self.all = read('test/product_test.rb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    gsub! 'activerecord.errors', 'errors' unless $rails_version =~ /^3\./
  end

  desc 'Add a fixture.'
  edit "test/fixtures/products.yml" do
    msub /.*\n()/m, "\n" + <<-EOF.unindent(6), :mark => 'ruby'
      # START_HIGHLIGHT
      ruby: 
        title:       Programming Ruby 1.9
        description: 
          Ruby is the fastest growing and most exciting dynamic
          language out there.  If you need to get working programs
          delivered fast, you should add Ruby to your toolbox.
        price:       49.50
        image_url:   ruby.jpg 
      # END_HIGHLIGHT
    EOF
  end

  desc 'Tests pass!'
  test :models
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

  desc "Route the 'root' of the site to the store"
  edit 'config/routes.rb' do
    if match /welcome/
      edit 'welcome#index', :highlight do
        msub /^\s+(# )root.*/, ''
        msub /(welcome)#index/, 'store'
        msub /()$/, ", :as => 'store'"
        gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
      end
    else
      msub /(\s*)\Z/, "\n\n"
      msub /, see( )http/, "\n  # "
      msub /^\s+(get 'store\/index')$/, 
        "  root 'store#index', as: 'store_index'", :highlight
    end

    if self =~ /priority is based upon order of creation: first created/
      msub /creation:( )first created/, "\n  # "
    end
  end

  if File.exist? 'public/index.html'
    desc 'Delete public/index.html, as instructed.'
    cmd 'rm public/index.html'
  end

  desc 'Demonstrate that everything is wired together'
  get '/', screenshot: { filename: "d_1_new_root.pdf", dimensions: [ 400, 200 ] }

  desc 'In the controller, get a list of products from the model'
  edit 'app/controllers/store_controller.rb' do
    msub /def index.*\n()/, <<-EOF.unindent(2), :highlight
      @products = Product.order(:title)
    EOF
  end

  desc 'In the view, display a list of products'
  edit 'app/views/store/index.html.erb' do
    self.all = read('store/index.html.erb')
  end

  unless File.exist? 'public/images'
    desc 'Add some basic style'
    edit "app/assets/stylesheets/store*.scss" do
      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, read('store.css.scss')
    end
  end

  desc 'Show our first (ugly) catalog page'
  get '/', screenshot: { filename: "d_2_catalog.pdf", dimensions: [ 1024, 600 ] }
  publish_code_snapshot :d
end

section 8.2, 'Iteration C2: Add a Page Layout' do
  overview <<-EOF
    Demonstrate layouts.
  EOF

  desc 'Modify the application layout'
  edit 'app/views/layouts/application.html.erb' do
    pack = self[/<%= javascript_pack_tag.*?%>/m]
    clear_highlights
    self.all = read('store/application.html.erb')
    self[/<%= javascript_include_tag.*?%>/m] = pack if pack
    gsub! '"application"', '"depot"' if File.exist? 'public/images'
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    gsub! 'csrf_meta_tags', 'csrf_meta_tag' if $rails_version =~ /^3\.0/
  end

  desc 'Modify the stylesheet'
  if DEPOT_CSS =~ /scss/
    
    desc 'Rename the application stylesheet so that we can use SCSS'
    cmd "mv app/assets/stylesheets/application.css #{DEPOT_CSS}"

    desc 'Add our style rules'
    edit DEPOT_CSS do
      # reflow comments
      gsub! /^ [^\n]{76}.*?\n\s.\n/m do |paragraph|
        paragraph.gsub(/^\s\*/,' ').gsub(/\s+/,' ').strip.
          gsub(/(.{1,76})(\s+|$)/, "\\1\n").gsub(/^/,' * ') + " * \n"
      end

      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, <<-EOF
body {
  margin: 0;
  padding: 0;
}
header.main {
  text-align: center; // center on mobile
  @media (min-width: 30em) {
    text-align: left; // left align on desktop
  }
  background: #282;
  margin: 0;
  h1 {
    display: none;
  }
}
.content {
  margin: 0;
  padding: 0;

  display: flex;
  display: -webkit-flex;
  flex-direction: column; // mobile is horizontally laid out
  -webkit-box-orient: vertical;
  -webkit-box-direction: normal;

  @media (min-width: 30em) {
    flex-direction: row;  // desktop is vertically laid out
    -webkit-box-orient: horizontal;
  }

  nav {
    padding-bottom: 1em;
    background: #141;
    text-align: center;  // mobile has centered nav
    @media (min-width: 30em) {
      text-align: left; // desktop nav is left-aligned
      padding: 1em;     // and needs more padding
    }
    ul {
      list-style: none;
      margin: 0;
      padding: 0;
      @media (min-width: 30em) {
        padding-right: 1em; // give desktop some extra space
      }
      li {
        margin: 0;
        padding: 0.5em;
        text-transform: uppercase;
        letter-spacing: 0.354em;
        a {
          color: #bfb;
          text-decoration: none;
        }
        a:hover {
          background: none;
          color: white;
        }
      }
    }
  }
  main {
    padding: 0.5em;
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

        #side ul {
          padding: 0;
        }

        #side li {
          list-style: none;
        }
        /* END:mainlayout */
      EOF
    end
  end

  desc 'Show the results.'
  get '/', screenshot: { filename: "e_1_catalog_with_nav.pdf", dimensions: [ 1024, 600 ] }
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
  get '/', screenshot: { filename: "e_2_prices_fixed.pdf", dimensions: [ 1024, 300 ] }
end

section 8.4, 'Iteration C4: Functional Testing' do
  overview <<-EOF
    Demonstrate use of assert_select to test views.
  EOF

  desc 'Verify that the tests still pass.'
  test

  desc 'Add tests for layout, product display, and formatting, using ' +
    'counts, string comparisons, and regular expressions.'
  edit 'test/*/store_controller_test.rb' do
    clear_highlights
    dcl 'should get index' do
      msub /^()\s+end/, <<-'EOF'.unindent(4), :highlight
        assert_select 'nav.side_nav a', :minimum => 4 
        assert_select 'main ul.catalog li', 3
        assert_select 'h2', 'Programming Ruby 1.9'
        assert_select '.price', /\$[,\d]+\.\d\d/
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Review fixure data'
  edit 'test/fixtures/products.yml'

  desc 'Show that the tests pass.'
  test :controllers
end

section 8.5, 'Iteration C5 - Caching' do
  ced = 'config/environments/development.rb'

  unless File.exist? 'public/images'
    desc "Turn on caching in development"
    if File.read(ced).include? 'tmp/caching-dev.txt'
      cmd 'rails dev:cache'
    else
      edit ced, 'perform_caching' do
        clear_all_marks
        edit 'perform_caching', :mark => 'perform_caching' do
          msub /perform_caching = (false|true)/, 'true'
        end
      end
    end
  end

  unless $rails_version =~ /^3\./
    desc 'cache sections'
    edit 'app/views/store/index.html.erb' do
      self.all = read('store/cached-index.html.erb')
    end
  end
  edit "test/fixtures/products.yml" do
    clear_all_marks
    clear_highlights
  end

  publish_code_snapshot :e

  unless File.exist? 'public/images'
    desc "Turn caching back off"
    if File.read(ced).include? 'tmp/caching-dev.txt'
      cmd 'rails dev:cache'
    else
      edit ced, 'perform_caching' do
        msub /perform_caching = (true)/, 'false'
      end
      cmd 'rm -f public/assets/*'
      cmd 'rm -rf tmp/*cache/*'
      restart_server
    end
  end
end

section 8.6, 'Playtime' do
  cmd 'git tag iteration-b'
  cmd 'git commit -a -m "Prettier listings"'
  cmd 'git tag iteration-c'
end

section 9.1, 'Iteration D1: Finding a Cart' do
  overview <<-EOF
    Create a cart.  Put it in a session.  Find it.
  EOF

  desc 'Create a cart.'
  if Gorp::Config[:dummy_field]
    warn 'dummy field added to avoid Rails bug'
    generate :scaffold, :Cart, :title
  else
    generate :scaffold, :Cart
  end
  db :migrate

  desc "Implement set_cart, which creates a new cart if it" +
    " can't find one."
  if File.exist? 'app/controllers/concerns'
    current_cart = 'app/controllers/concerns/current_cart.rb'
  else
    current_cart = 'app/controllers/application_controller.rb'
  end
  edit current_cart do
    if File.exist? 'app/controllers/concerns'
      self.all = <<-EOF.unindent(8)
        module CurrentCart
        end
      EOF
    end
    msub /()^end/, "\n" + <<-EOF.unindent(4)
      private

        def set_cart 
          @cart = Cart.find(session[:cart_id])
        rescue ActiveRecord::RecordNotFound
          @cart = Cart.create
          session[:cart_id] = @cart.id
        end
    EOF
  end
end

section 9.2, 'Iteration D2: Connecting Products to Carts' do
  overview <<-EOF
    Create line item which connects products to carts'
  EOF

  desc 'Create the model object.'
  generate :scaffold, :LineItem, 'product:references cart:belongs_to'
  db :migrate

  desc 'Cart has many line items.'
  edit 'app/models/cart.rb' do
    msub /class Cart.*\n()/, <<-EOF.unindent(4), :highlight
      has_many :line_items, :dependent => :destroy
    EOF
    gsub! /^\s+# attr_accessible.*\n/, ''
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

    unless $rails_version =~ /^[34]/
      msub /(if) line_items.empty\?/, 'unless'
      sub! /return true\s*else\s*/, ''
      sub! /return false/, 'throw :abort'
    end
  end

  desc 'Line item belongs to both Cart and Product ' +
       '(But slightly more to the Cart).  Also provide convenient access ' +
       "to the total price of the line item"
  edit 'app/models/line_item.rb' do
    unless self =~ /belongs_to/
      msub /class LineItem.*\n()/, <<-EOF.unindent(2), :highlight
        belongs_to :product
        belongs_to :cart
      EOF
    end
    if $rails_version =~ /^3.2/
      msub /^()end/, <<-EOF.unindent(2), :highlight
        attr_accessible :cart_id, :product_id
      EOF
    end
  end

  desc "Add a test ensuring that non-empty carts can't be deleted."
  edit 'test/*/products_controller_test.rb', 'destroy' do
    clear_highlights
    gsub! "\n\n  # ...\n", "\n" 
    dcl 'should destroy product', :mark => 'destroy' do
      destroy_product_ruby = dup
      sub! /\A/, "  # START_HIGHLIGHT\n"
      sub!('@product', 'products(:two)')
      sub! 'should destroy product', "can't delete product in cart"
      sub! '-1', '0'
      sub! /\Z/, "\n  # END_HIGHLIGHT"
      self << "\n" + destroy_product_ruby
    end
  end

  desc 'change fixture so that product two is in both carts'
  edit 'test/fixtures/line_items.yml' do
    if self =~ /_id:/
      msub /product(_id: .*)/, ': two'
      msub /cart(_id: .*)/, ': one'
      msub /product(_id: .*)/, ': two'
      msub /cart(_id: .*)/, ': two'
    else
      edit 'product: one', :highlight do
        sub! 'one', 'two'
      end
    end
  end

  test :controllers
end

section 9.3, 'Iteration D3: Adding a button' do
  overview <<-EOF
    Now we connect the model objects we created to the controller and the view.
  EOF

  desc 'Add the button, connecting it to the Line Item Controller, passing ' +
       'the product id.'
  edit 'app/views/store/index.html.erb' do
    clear_all_marks
    msub /number_to_currency.*\n()/, '    ' + <<-EOF, :highlight
        <%= button_to 'Add to Cart', line_items_path(:product_id => product) %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add a bit of style to make it show all on one line'
  if DEPOT_CSS =~ /scss/
    edit 'app/assets/stylesheets/store*.scss', 'inline' do
      edit /^      .price \{.*?\n()    \}\n/m, :mark => 'inline'
      msub /^      .price \{.*?\n()    \}\n/m, "\n" + <<-EOF.unindent(2)
        /* START_HIGHLIGHT */
        form, div {
          display: inline;
        }
        input[type="submit"] {
          background-color: #282;
          border-radius: 0.354em;
          border: solid thin #141;
          color: white;
          font-size: 1em;
          padding: 0.354em 1em;
        }
        input[type="submit"]:hover {
          background-color: #141;
        } 
        /* END_HIGHLIGHT */
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

  desc "See the button on the page"
  get '/', screenshot: { filename: "f_1_added_button.pdf", dimensions: [ 1024, 300 ] }

  desc 'Update the LineItem.new call to use set_cart and the ' +
       'product id. Additionally change the logic so that redirection upon ' +
       'success goes to the cart instead of the line item.'
  edit 'app/controllers/line_items_controller.rb', 'current_cart' do
    clear_highlights
    edit /class.*?\n\s*(#.*?)\n/m, :mark => 'current_cart' do
      msub /class.*?\n()/, <<-EOF.unindent(6), :highlight
        include CurrentCart
        before_action :set_cart, :only => [:create]
      EOF
      sub! /\s+include CurrentCart/, '' if $rails_version =~ /^3\./
      gsub! '_action', '_filter' if $rails_version =~ /^3\./
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
    edit /^end/, :mark => 'current_cart' do
      msub /^()end/, "  #...\n"
    end
  end

  edit 'app/controllers/line_items_controller.rb', 'create' do
    dcl 'create', :mark do
      edit 'LineItem.new', :highlight do
        msub /^()/, <<-EOF.unindent(6)
          product = Product.find(params[:product_id])
        EOF
        if $rails_version =~ /^3\./
          msub /(LineItem.new\(.*\))/,
            "@cart.line_items.build\n    @line_item.product = product"
        else
          msub /(LineItem.new\(.*\))/,
            "@cart.line_items.build(product: product)"
        end
        gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
      end
      msub /,( ):?notice/, "\n          "
      msub /,( ):?status/, "\n          "
      msub /,( ):?status/, "\n          "
    end

    edit 'redirect_to', :highlight
    msub /redirect_to[\(\s]@line_item()/, '.cart'
  end

  desc "Try it once, and see that the output isn't very useful yet."
  post '/', { 'product_id' => 3 },
    screenshot: { filename: "f_2_boring_cart.pdf", dimensions: [ 640, 200 ], form_data: {}, submit_form: 1 }

  desc 'Update the template that shows the Cart.'
  edit 'app/views/carts/show.html.erb' do
    self.all = <<-EOF.unindent(6)
      <% if notice %>
        <aside id="notice"><%= notice %></aside>
      <% end %>

      <h2>Your Pragmatic Cart</h2>
      <ul>    
        <% @cart.line_items.each do |item| %>
          <li><%= item.product.title %></li>
        <% end %>
      </ul>
    EOF
  end

  desc "Style the flash"
  edit 'app/assets/stylesheets/application.scss' do
    msub /()^.content/,%{
// START:notice
.notice, #notice {
  background: #ffb;
  border-radius: 0.5em;
  border: solid 0.177em #882;
  color: #882;
  font-weight: bold;
  margin-bottom: 1em;
  padding: 1em 1.414em;
  text-align: center;
}
// END:notice
}
  end

  desc "Try it once again, and see that the products in the cart."
  post '/', { 'product_id' => 3 },
    screenshot: { filename: "f_3_better_cart.pdf", dimensions: [ 640, 200 ], form_data: {}, submit_form: 1 }
  publish_code_snapshot :f
end

section 9.4, 'Playtime' do
  overview <<-EOF
    Once again, get the tests working, and add tests for the smarter cart.
  EOF

  desc 'See that the tests fail.'
  test

  desc 'Update parameters passed as well as expected target of redirect'
  edit 'test/*/line_items_controller_test.rb', 'create' do
    dcl 'should create', :mark => 'create' do
      edit 'post', :highlight do
        if match /params: /
          msub /(line_item: \{ (.*?) \})/, 'product_id: products(:ruby).id'
        elsif match /:line_item =>/
          msub /(:line_item =>.*)/, ':product_id => products(:ruby).id'
        else
          msub /(line_item:.*)/, 'product_id: products(:ruby).id'
        end
      end
      if $rails_version =~ /^[34]/
        edit 'line_item_path', :highlight do
          msub /(line_item_path.*)/, 'cart_path(assigns(:line_item).cart)'
        end
      else
        edit 'line_item_url', :highlight do
          msub /(assert_redirect.*)/, 
            "follow_redirect!\n\n" +
            "    assert_select 'h2', 'Your Pragmatic Cart'\n" +
            "    assert_select 'li', 'Programming Ruby 1.9'"
        end
      end
    end
  end

  desc 'Rerun the previously failing test to verify the fix.'
  test 'test/*/line_items_controller_test.rb'
end

section 10.1, 'Iteration E1: Creating a Smarter Cart' do
  overview <<-EOF
    Change the cart to track the quantity of each product.
  EOF

  desc 'Add a few products to the order.'
  post '/', {'product_id' => 2}
  post '/', {'product_id' => 2}
  post '/', {'product_id' => 3}


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
  db :migrate

  desc 'Create a method to add a product to the cart by either incrementing ' +
       'the quantity of an existing line item, or creating a new line item.'
  edit 'app/models/cart.rb', 'add_product' do
    msub /^()end/, "\n" + <<-'EOF'.unindent(4), :mark => 'add_product'
      def add_product(product)
        current_item = line_items.find_by_product_id(product.id)
        if current_item
          current_item.quantity += 1
        else
          current_item = line_items.build(:product_id => product.id)
        end
        current_item
      end
    EOF
    gsub! 'by_product_id(', 'by(product_id: ' unless $rails_version =~ /^3/
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Replace the call to LineItem.new with a call to the new method.'
  edit 'app/controllers/line_items_controller.rb', 'create' do
    clear_highlights
    dcl 'create' do
      edit 'line_items.build', :highlight do
        msub /@line_item = (.*)/, '@cart.add_product(product)'
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
    dcl = self[/^class.*/]
    selfup = include?('self.up')
    self.all = read('cart/combine_items_in_cart.rb')
    self[/^class.*/] = dcl
    gsub! 'self.', '' unless selfup
    gsub! ', :quantity=>1', '' if $rails_version =~ /^3\.2/
    gsub! /:(\w+)=>/, '\1: \2' unless RUBY_VERSION =~ /^1\.8/ # add a space
  end

  desc 'Combine entries'
  db :migrate

  desc "Verify that the entries have been combined."
  %w(1).each do |cart_id|
    get "/carts/#{cart_id}", screenshot: { filename: "g_1_cart_#{cart_id}_quantities.pdf", dimensions: [ 640, 200 ] }
  end

  desc 'Fill in the self.down method'
  migration = Dir['db/migrate/*combine_items_in_cart.rb'].first
  edit migration, 'down'

  desc 'Separate out individual items.'
  db :rollback
  db :'migrate:status'
  cmd "mv #{migration} #{migration.sub('.rb', '.bak')}"

  desc 'Every item should (once again) only have a quantity of one.'
  %w(1).each do |cart_id|
    get "/carts/#{cart_id}", screenshot: { filename: "g_2_cart_#{cart_id}_no_quantities.pdf", dimensions: [ 640, 200 ] }
  end

  desc 'Recombine the item data.'
  cmd "mv #{migration.sub('.rb', '.bak')} #{migration}"
  db :migrate

  desc 'Add a few products to the order.'
  post '/', {'product_id' => 2}, {:snapget => false}
  post '/', {'product_id' => 3}, {:snapget => false}
  publish_code_snapshot :g

  unless $rails_version =~ /^[34]/
    desc 'fix the test case'
    edit 'test/*/line_items_controller_test.rb', 'create' do
      dcl 'should create' do
        clear_all_marks
        msub /Programming Ruby 1\.9(')/, '"'
        msub /(')Programming Ruby 1\.9/, '"1 \\u00D7 '
        edit '00D7', :highlight
      end
    end

    desc 'rerun tests'
    test
  end

  desc 'Try something malicious.'
  get '/carts/wibble',
    screenshot: { filename: "g_3_cart_error.pdf", dimensions: [ 640, 800 ] }
end

section 10.2, 'Iteration E2: Handling Errors' do
  overview <<-EOF
    Log errors and show them on the screen.
  EOF

  sleep 1 if RUBY_PLATFORM =~ /darwin/i

  desc 'Rescue error: log, flash, and redirect.'
  edit 'app/controllers/carts_controller.rb', 'setup' do |data|
    edit /class.*?\n\s*(#.*?)\n/m, :mark => 'setup' do
      msub /\n(\s*)(\n|  #)/, 
        "  rescue_from ActiveRecord::RecordNotFound, :with => :invalid_cart\n",
        :highlight
    end

    if include? 'private'
      edit /^ *private\s*/, :mark => 'setup'
      msub /^() *private\s*/, "  # ...\n"
      msub /^ *private\n(\s*)\n/, "  # ...\n"
    end

    edit /^()end/, :mark => 'setup'
    msub /^()end/, <<-'EOF'.unindent(2), :highlight
      def invalid_cart
        logger.error "Attempt to access invalid cart #{params[:id]}"
        redirect_to store_index_url, :notice => 'Invalid cart'
      end
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  if RUBY_VERSION =~ /^1\.8/ and $rails_version =~ /^3\.2/
    desc 'Intermittent cache reloading issue'
    restart_server
  end

  desc 'Reproduce the error.'
  get '/carts/wibble',
    screenshot: { filename: "g_4_cart_error_fixed.pdf", dimensions: [ 1024, 300 ] }

  desc 'Inspect the log.'
  cmd 'tail -25 log/development.log', :highlight => ['Attempt to access']

  unless $rails_version =~ /^3\./
    desc 'Limit access to product_id'
    edit 'app/controllers/line_items_controller.rb', 'line_item_params' do
      edit /^ *# Never.*?end\n/m, :mark => 'line_item_params'
      dcl 'line_item_params'  do
        edit 'permit', :highlight do
          msub /require\(:line_item\)(.*)/, '.permit(:product_id)'
        end
      end
      sub! /(, only allow the white) (list through\.)$/, "\\1\n    # \\2"
    end

    test :controllers

    desc 'Inspect the log.'
    cmd 'grep -B 8 -A 7 "Unpermitted parameter" log/test.log',
      :highlight => ['Unpermitted parameter']

    edit 'test/*/line_items_controller_test.rb', 'update' do
      dcl "should update line_item", :mark => 'update' do
        edit 'cart_id', :highlight
        msub /(cart_id: .*?, )/, ''
        sub! ', params:', ",\n      params:"
      end
    end
 
    rake 'log:clear LOGS=test'
    test :controllers
    cmd 'grep "Unpermitted parameters" log/test.log | wc -l'
  end
end

section 10.3, 'Iteration E3: Finishing the Cart' do
  overview <<-EOF
    Add empty cart button, remove flash for line item create, add totals to
    view.
  EOF

  desc 'Add button to the view.'
  edit 'app/views/carts/show.html.erb' do
    clear_highlights
    msub /(\s*)\Z/, "\n\n"
    msub /\n\n()\Z/, <<-EOF.unindent(6)
    <!-- START_HIGHLIGHT -->
      <%= button_to 'Empty cart', @cart, :method => :delete,
          :data => { :confirm => 'Are you sure?' } %>
    <!-- END_HIGHLIGHT -->
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Clear session and change flash notice when cart is destroyed.'
  edit 'app/controllers/carts_controller.rb', 'destroy' do
    dcl 'destroy', :mark => 'destroy' do
      if include? 'Cart.find'
        edit 'Cart.find', :highlight do
          msub /(@cart = .*)/, 'set_cart'
        end
      else
        edit '@cart.destroy', :highlight do
          msub /()$/, ' if @cart.id == session[:cart_id]'
        end
      end

      msub /@cart.destroy.*\n()/,<<-EOF.unindent(4), :highlight
        session[:cart_id] = nil
      EOF

      edit 'carts_url', :highlight do
        sub! /carts_url.*?}/, 
          "store_index_url,\n        :notice => 'Your cart is currently empty' }"
      end
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc 'Try it out.'
  post '/carts/1', {'_method'=>'delete'},
    screenshot: { filename: "g_5_empty_cart.pdf", dimensions: [ 1024, 300 ], submit_form: true }

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
  edit 'app/views/carts/show.html.erb' do
    self.all = read('cart/show.html.erb')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add a method to compute the total price of a single line item.'
  edit 'app/models/line_item.rb', 'total_price' do
    msub /()^end/, "\n" + <<-EOF.unindent(4), :mark => 'total_price'
      def total_price
        product.price * quantity
      end
    EOF
  end

  if RUBY_VERSION =~ /^1\.8/ and $rails_version =~ /^3\.2/
    desc 'Intermittent cache reloading issue'
    restart_server
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
  if DEPOT_CSS =~ /scss/
    edit 'app/assets/stylesheets/carts*.scss' do
      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, <<-EOF
.carts {
  table {
    border-collapse: collapse;
  }
  td {
    padding: 0.5em;
  }
  td.quantity {
    white-space: nowrap;
  }
  td.quantity::after {
    content: " ×";
  }
  td.price {
    font-weight: bold;
    text-align: right;
  }
  tfoot {
    th, td.price {
      font-weight: bold;
      padding-top: 1em;
    }
    th {
      text-align: right;
    }
    td.price {
      border-top: solid thin;
    }
  }
  input[type="submit"] {
    background-color: #881;
    border-radius: 0.354em;
    border: solid thin #441;
    color: white;
    font-size: 1em;
    padding: 0.354em 1em;
  }
  input[type="submit"]:hover {
    background-color: #992;
  }
}
      EOF
    end
  else
    edit DEPOT_CSS, 'cartmain' do |data|
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
  %w(1 2 3).each do |cart_id|
    get "/carts/#{cart_id}", screenshot: { filename: "h_1_cart_#{cart_id}_styled.pdf", dimensions: [ 640, 200 ] }
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
  test

  unless $rails_version =~ /^[34]/
    desc 'Update the value of the header that we are looking for'
    edit 'test/controllers/line_items_controller_test.rb', 'create' do
      dcl 'should create' do
        edit 'Your Pragmatic Cart', :highlight do
          sub! /Pragmatic\s/, ''
        end
        edit 'Programming Ruby', :highlight do
          sub! "'li'", "'td'"
          sub! /1 .*? /, ''
        end
      end
    end
  end

  desc 'Update expected target of redirect: Cart#destroy.'
  unless $rails_version =~ /^[34]/
    warn 'avoid using session in integration tests'
  end
  edit 'test/*/carts_controller_test.rb', 'destroy' do
    dcl 'should destroy', :mark => 'destroy' do
      if $rails_version =~ /^[34]/
        msub /do\n()/, "    session[:cart_id] = @cart.id\n",
          :highlight
      else
        msub /do\n()/, 
          "    post line_items_url, params: " +
                    "{ product_id: products(:ruby).id }\n" +
          "    @cart = Cart.find(session[:cart_id])\n\n",
          :highlight
      end
      edit /^.*carts_(path|url).*\n/, :highlight do
        msub /(carts)/, 'store_index'
      end
    end
  end

  desc 'Test both unique and duplicate products.'
  edit "test/*/cart_test.rb" do
    self.all = read('test/cart_test.rb')
  end

  test 'test/*/cart_test.rb'

  publish_code_snapshot :i

  desc 'Refactor.'
  edit "test/*/cart_test.rb" do
    self.all = read('test/cart_test1.rb')
  end
  test 'test/*/cart_test.rb'

  desc 'Verify that the tests pass.'
  test

  desc 'Now the tests should pass.'
  test

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
  db :migrate
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
    data[/()/,1] = <<-EOF
<tr>
  <td class="quantity"><%= line_item.quantity %></td>
  <td><%= line_item.product.title %></td>
  <td class="price"><%= number_to_currency(line_item.total_price) %></td>
</tr>
EOF
  end

  desc 'Replace that portion of the view with a callout to the partial'
  edit 'app/views/carts/show.html.erb' do
    clear_highlights
    msub /^(    <% @cart.line_items.each do .* end %>\n)/m, %{
    <!-- START_HIGHLIGHT -->
    <%= render(@cart.line_items) %>
    <!-- END_HIGHLIGHT -->
}
  end

  desc 'Make a copy as a partial for the cart controller'
  cmd 'cp app/views/carts/show.html.erb app/views/carts/_cart.html.erb'

  desc 'Modify the copy to reference the (sub)partial and take input from @cart'
  edit 'app/views/carts/_cart.html.erb' do
    clear_highlights
    sub! /^<% if notice %>.*?<% end %>\n\n/m, ''
    sub! /^<p id="notice"><%= notice %><\/p>\n\n/m, ''
    while include? '@cart'
      edit '@cart', :highlight
      sub! '@cart', 'cart'
    end
    sub! /#START_HIGHLIGHT/, "<!-- START_HIGHLIGHT -->"
#    sub! /#END_HIGHLIGHT/, "<!-- END_HIGHLIGHT -->"
  end

  publish_code_snapshot :j

  desc 'Keep things DRY'
  edit 'app/views/carts/show.html.erb' do
    msub /(<article.*)/m, "<%= render @cart %>\n", :highlight
  end

  desc 'Reference the partial from the layout.'
  edit 'app/views/layouts/application.html.erb' do
    clear_highlights
    msub /<nav class="side_nav">\n()/, <<-EOF, :highlight
        <div id="cart" class="carts">
          <%= render @cart %>
        </div>
    EOF
    gsub! /(<!-- <label id="[.\w]+"\/> -->)/, ''
    gsub! /(# <label id="[.\w]+"\/>)/, ''
  end

  desc 'Insert a call in the controller to find the cart'
  edit 'app/controllers/store_controller.rb' do
    clear_highlights
    msub /class.*?\n()/, <<-EOF.unindent(4), :highlight
      include CurrentCart
      before_action :set_cart
    EOF
    sub! /\s+include CurrentCart/, '' if $rails_version =~ /^3\./
    gsub! '_action', '_filter' if $rails_version =~ /^3\./
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add a small bit of style.'
  if DEPOT_CSS =~ /scss/
    edit 'app/assets/stylesheets/application.scss' do
      clear_highlights
      msub /()^    ul {/,%{
        // START:side
    #cart {
      article {
        h2 {
          margin-top: 0;
        }
        background: white;
        border-radius: 0.5em;
        margin: 1em;
        padding: 1.414em;
        @media (min-width: 30em) {
          margin: 0; // desktop doesn't need this margin
        }
      }
    }
        // END:side
}
    end
  else
    edit DEPOT_CSS, 'cartside' do |data|
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

  desc 'Change the redirect to be back to the store.'
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    data[/(@line_item.cart)/,1] = "store_index_url"
  end

  desc 'Purchase another product.'
  post '/', { 'product_id' => 3 },
    screenshot: { filename: "j_1_side_cart.pdf", dimensions: [ 1024, 300 ], form_data: {}, submit_form: 1 }

  publish_code_snapshot :k

  desc 'Run tests... oops.'
  test

  desc 'Verify that the products page is indeed broken'
  get '/products',
    screenshot: { filename: "k_1_products_page_broken.pdf", dimensions: [ 1024, 300 ]}

  desc 'Clear highlights'
  edit "app/views/layouts/application.html.erb" do
    clear_highlights
  end
  desc 'Start side'
  edit "app/views/layouts/application.html.erb" do
    msub /()<nav/, "<!-- START:side -->\n      "
  end

  desc 'End side'
  edit "app/views/layouts/application.html.erb" do
    msub /()<main/, "<!-- END:side -->\n      "
  end
  desc 'Add if statement'
  edit "app/views/layouts/application.html.erb" do
    msub /()\s+<div id=\"cart\"/, %{
        <!-- START_HIGHLIGHT -->
        <% if @cart %>
}
  end
  desc 'Add end statement'
  edit "app/views/layouts/application.html.erb" do
    msub /\s+<\/div>()/, %{
        <% end %>
        <!-- END_HIGHLIGHT -->
}
  end

  if $rails_version =~ /^[34]/
    desc 'Update the redirect test.'
    edit 'test/*/line_items_controller_test.rb', 'create' do
      clear_highlights
      edit "assert_redirected_to", :highlight do
        msub /assert_redirected_to (cart_path.*)/, 'store_index_path'
      end
    end
  end

  desc 'all better'
  test
end

section 11.2, 'Iteration F2: Creating an AJAX-Based Cart' do
  desc 'Add remote: true to the Add to Cart button'
  edit 'app/views/store/index.html.erb' do
    clear_all_marks
    edit '<%= button_to', :highlight
    msub /<%= button_to.*() %>/, ",\n              :remote => true"
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Enable a the controller to respond to js requests'
  edit 'app/controllers/line_items_controller.rb', 'create' do
    clear_highlights
    msub /format.html.*store_index_url.*\n()/, "        format.js\n", :highlight
  end

  desc 'Use Coffeescript to replace the cart with a new rendering'
  if File.exist? 'public/images'
    edit 'app/views/line_items/create.js.rjs' do |data|
      data.all =  <<-EOF.unindent(8)
        page.replace_html('cart', render(@cart))
      EOF
    end
  else
    ext = ($rails_version =~ /^[45]/ ? 'coffee' : 'erb')
    edit "app/views/line_items/create.js.#{ext}" do |data|
      data.all =  <<-EOF.unindent(8)
        #{ext == 'erb' ? 'var ' : ''}cart = document.getElementById("cart")
        cart.innerHTML = "<%= j render(@cart) %>"
      EOF
    end
  end

  publish_code_snapshot :l

  test

end

section 11.3, 'Iteration F3: Highlighting Changes' do
  desc 'Assign the current item to be the line item in question'
  edit 'app/controllers/line_items_controller.rb', 'create' do
    clear_highlights
    dcl 'create' do
      msub /format.js()\n/, '   { @current_item = @line_item }'
      edit 'format.js', :highlight
    end
  end

  desc 'Add the id to the row in question'
  edit 'app/views/line_items/_line_item.html.erb' do
    msub /(<tr>\n)/, <<-EOF.unindent(6), :highlight
      <% if line_item == @current_item %>
      <tr class="line-item-highlight">
      <% else %>
      <tr>
      <% end %>
    EOF
  end

  desc 'Animate the background color of that row'
  if File.exist? 'app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.rjs' do |data|
      msub /.*()/m, "\n" + <<-EOF.unindent(8), :highlight
        page[:current_item].visual_effect :highlight,
                                          :startcolor => "#88ff88",
                                          :endcolor => "#114411"
      EOF
    end
  else
    edit 'app/assets/stylesheets/line_items.scss' do |data|
      msub /.*()/m, "\n" + <<-EOF.unindent(8), :highlight
        @keyframes line-item-highlight {
          0% {
            background: #8f8;
          }
          100% {
            background: none;
          }
        }

        .line-item-highlight {
          animation: line-item-highlight 1s;
        }
      EOF
    end
    # TODO: Blind effect
  end

  desc 'Add an XHR test.'
  edit 'test/*/line_items_controller_test.rb', 'ajax' do
    msub /^()end/, "\n"
    msub /^()end/, <<-EOF.unindent(4), :mark => 'ajax'
      test "should create line_item via ajax" do
        assert_difference('LineItem.count') do
          xhrpost
        end 
    
        assert_response :success
        assert_match /<tr class=\\\\\"line-item-highlight/, @response.body
      end
    EOF

    if $rails_version =~ /^[34]/
      sub! 'xhrpost', 'xhr :post, :create, :product_id => products(:ruby).id'
    else
      sub! 'xhrpost', 'post line_items_url, params: ' + 
        "{ product_id: products(:ruby).id },\n        xhr: true"
    end

    unless File.exist? 'public/images'
      gsub! "_rjs :replace_html, 'cart'", "_jquery :html, '#cart'"
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  test
  publish_code_snapshot :m

end

section 11.4, 'Iteration F4: Hide an Empty Cart' do
  desc 'Add a blind down visual effect on the first item'
  if File.exist? 'app/views/line_items/create.js.rjs'
    edit 'app/views/line_items/create.js.rjs' do
      msub /().*visual_effect/, <<-EOF.unindent(8) + "\n", :highlight
        page[:cart].visual_effect :blind_down if @cart.total_items == 1
      EOF
    end

    edit 'app/models/cart.rb' do
      clear_highlights
      msub /()^end/, "\n" + <<-EOF.unindent(4), :mark => 'total_items'
        def total_items
          line_items.sum(:quantity)
        end
      EOF
    end
  end

  desc 'Look at the app/helpers directory'
  cmd 'ls -p app'
  cmd 'ls -p app/helpers'

  desc 'Call a render_if helper'
  edit 'app/views/layouts/application.html.erb' do
    clear_highlights
    msub /^(\s*<% if @cart %>\n)/,''
    msub /^(\s*<% end %>\n)/,''
    msub /^(\s*<%= render @cart %>\n)/,%{
          <!-- START_HIGHLIGHT -->
          <%= render_if @cart && @cart.line_items.any?, @cart %>
          <!-- END_HIGHLIGHT -->
}
  end

  desc 'Implement helper'
  edit 'app/helpers/application_helper.rb' do
    msub /()^end/, <<-EOF.unindent(4), :highlight
      def render_if(condition, record)
        if condition
          render record
        end
      end
    EOF
  end

  desc "hide notice when adding to cart"
  if $rails_version =~ /^[45]/
    edit "app/views/line_items/create.js.coffee" do |data|
      data << %{
# START_HIGHLIGHT
notice = document.getElementById("notice")
if notice
  notice.style.display = "none"
# END_HIGHLIGHT
}
    end
  else
    edit "app/views/line_items/create.js.erb" do |data|
      data << %{
// START_HIGHLIGHT
var notice = document.getElementById("notice")
if (notice) notice.style.display = "none"
// END_HIGHLIGHT
}
    end
  end

  desc 'Demonstrate emptying and recreating the cart'
  post '/carts/2', '_method'=>'delete'
  post '/', 'product_id' => 2

  test

  publish_code_snapshot :n
end
     

if $rails_version =~ /^4\./

  section 11.5, 'Iteration F5: Making Images Clickable' do
    desc 'Review our current storefront markup'
    edit 'app/views/store/index.html.erb' do
      clear_highlights
    end

    desc 'Associate image clicks with submit button clicks'
    edit 'app/assets/javascripts/store*.coffee' do
      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, <<-EOF.unindent(8), :highlight
        $(document).on "ready page:change", ->
          $('.store .entry > img').click ->
            $(this).parent().find(':submit').click()
      EOF
    end

    desc 'The page looks no different'
    get '/'

    desc 'Run tests'
    test
  end

else

  section 11.5, 'Iteration F5: Broadcasting Updates' do
    desc 'create a channel'
    generate 'channel products'

    desc 'create a channel'
    edit 'app/channels/products_channel.rb' do
      msub /Action Cable( )runs/, "\n# "  if self =~ /^#/
      edit '# stream_from', :highlight do
        gsub! /#.*/, 'stream_from "products"'
      end
    end

    desc 'Update price when notified of price changes'
    if $rails_version =~ /^[345]/
      file = 'app/assets/javascripts/channels/products.coffee'
    else
      file = 'app/javascript/channels/products_channel.js'
    end
    edit file do
      edit 'incoming data', :highlight do
        gsub! %r{(#|//).*}, 
          'document.getElementsByTagName("main")[0].innerHTML = data.html'
      end
      gsub! /^#/, '//' if file.end_with? '.js'
    end

    desc 'send updates when price changes'
    edit 'app/controllers/products_controller.rb', 'update' do
      dcl 'update', :mark do
        msub /\n()\s*else/, "\n" + <<-EOF.unindent(2), :highlight
          @products = Product.all
          ActionCable.server.broadcast 'products',
            html: render_to_string('store/index', layout: false)
        EOF
      end
    end

    desc 'Run tests'
    test

    desc 'Save our progress'
    cmd 'git commit -a -m "AJAX"'
    cmd 'git tag iteration-f'
  end
end

section 12.1, 'Iteration H1: Capturing an Order' do
  desc 'Create a model to contain orders'
  if $rails_version =~ /^3\.[01]/
    generate :scaffold, :Order,
      'name:string address:text email:string pay_type:string'
  elsif $rails_version =~ /^3|4\.0/
    generate :scaffold, :Order, 'name address:text email pay_type'
  else
    generate :scaffold, :Order, 'name address:text email pay_type:integer'
  end

  desc 'Create a migration to add an order_id column to line_items'
  generate 'migration add_order_id_to_line_item order_id:integer'

  desc 'Apply both migrations'
  db :migrate

  desc 'Add a Checkout button to the cart'
  edit 'app/views/carts/_cart.html.erb' do
    clear_highlights
    msub /().*Empty cart/, %{
  <!-- START_HIGHLIGHT -->
  <div class="actions">
  <!-- END_HIGHLIGHT -->
}
    msub /()<\/article>/,%{
  <!-- START_HIGHLIGHT -->
  <%= button_to 'Checkout', new_order_path,
                method: :get,
                class: "checkout"%>
  </div>
  <!-- END_HIGHLIGHT -->
}
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Style the new button"
  edit "app/assets/stylesheets/carts.scss" do
    msub /^(  input\[type=\"submit.*$)/m, %{
  // START_HIGHLIGHT
  .actions {
    text-align: right;
    form {
      display: inline;
  // END_HIGHLIGHT
      input[type="submit"] {
        background-color: #881;
        border-radius: 0.354em;
        border: solid thin #441;
        color: white;
        font-size: 1em;
        padding: 0.354em 1em;
      }
      input[type="submit"]:hover {
        background-color: #992;
      }
  // START_HIGHLIGHT
      input[type="submit"].checkout {
        background-color: #bfb;
        color: black;
        font-weight: bold;
      }
      input[type="submit"].checkout:hover {
        background-color: #efe;
      }
    }
  }
  // END_HIGHLIGHT
\}
}
  end

  desc 'Return a notice when checking out an empty cart'
  edit 'app/controllers/orders_controller.rb', 'current_cart' do
    edit /class.*?\n\s*(#.*?)\n/m, :mark => 'current_cart' do
      msub /class.*?\n()/, <<-EOF.unindent(6), :highlight
        include CurrentCart
        before_action :set_cart, :only => [:new, :create]
        before_action :ensure_cart_isnt_empty, only: :new
      EOF
      sub! /\s+include CurrentCart/, '' if $rails_version =~ /^3\./
      gsub! '_action', '_filter' if $rails_version =~ /^3\./
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
    edit /^end/, :mark => 'current_cart' do
      msub /^()end/, "  #...\n"
      msub /^()end/, "\n" + <<-EOF.unindent(6), :highlight
        private
           def ensure_cart_isnt_empty
             if @cart.line_items.empty?
               redirect_to store_index_url, notice: 'Your cart is empty'
             end
           end
      EOF
    end
  end

  desc 'Modify tests to ensure that there is an item in the cart'
  edit 'test/*/orders_controller_test.rb', 'new' do |data|
    data.dcl 'should get new', :mark => 'new' do |getnew|
      empty = getnew.dup
      empty.edit 'assert_response' do |assert|
        assert.msub /assert_(response :success)/, 'redirected_to store_index_path'
        assert << "\n    assert_equal flash[:notice], 'Your cart is empty'"
      end
      empty.sub! 'should get new', 'requires item in cart'
      empty.dcl 'requires item in cart', :highlight
    
      if $rails_version =~ /^[34]/
        getnew.msub /do\n()/, <<-EOF.unindent(6) + "\n", :highlight
          item = LineItem.new
          item.build_cart
          item.product = products(:ruby)
          item.save!
          session[:cart_id] = item.cart.id
        EOF
      else
        getnew.msub /do\n()/, <<-EOF.unindent(6) + "\n", :highlight
          post line_items_url, params: { product_id: products(:ruby).id }
        EOF
      end

      getnew.msub /()\A/, empty + "\n"
      getnew.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/

      getnew.gsub! ', email:', ",\n      email:"
      getnew.gsub! ', pay_type:', ",\n      pay_type:"
    end
  end

  desc 'Modify the template for new orders'
  edit 'app/views/orders/new.html.erb' do
    self.all = read('orders/new.html.erb')
  end

  desc 'Add payment types to the order'
  edit 'app/models/order.rb', 'select' do |data|
    if $rails_version =~ /^(3|4\.0)/
      msub /class Order.*\n()/, <<-EOF.unindent(6), :mark => 'select'
        PAYMENT_TYPES = [ "Check", "Credit card", "Purchase order" ]
      EOF
      edit 'PAYMENT_TYPES', :highlight
    else
      msub /class Order.*\n()/, <<-EOF.unindent(6), :mark => 'select'
        enum pay_type: {
          "Check"          => 0, 
          "Credit card"    => 1, 
          "Purchase order" => 2
        }
      EOF
      edit 'pay_type', :highlight
    end

    edit 'class Order', :mark => 'select'
    edit /^end/, :mark => 'select'
  end

  desc 'Modify the partial used by the template'
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

    if $rails_version =~ /^(3|4\.0)/
      edit 'text_field :pay_type', :highlight # while it still is on one line
      edit 'text_field :pay_type' do
        msub /(text_field)/, 'select'
        msub /() %>/, ", Order::PAYMENT_TYPES,\n" + 
          (' ' * 18) + ":prompt => 'Select a payment method'"
      end
      edit 'submit', :highlight do
        msub /() %>/, " 'Place Order'"
      end
    else
      edit 'number_field :pay_type', :highlight # while it still is on one line
      edit 'number_field :pay_type' do
        msub /(number_field)/, 'select'
        msub /:pay_type()/, ", Order.pay_types.keys"
        msub /() %>/,  ",\n" + (' ' * 18) + 
          ":prompt => 'Select a payment method'"
      end
      edit 'submit', :highlight do
        msub /() %>/, " 'Place Order'"
      end
    end

    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add some CSS'
  if DEPOT_CSS =~ /scss/
    edit DEPOT_CSS, 'form' do
      msub /(\s*)\Z/, "\n\n"
      msub /\n\n()\Z/, <<-EOF, :mark => 'form'
.depot_form {
  padding: 0 1em;
  h1 {
    font-size: 1.99em;
    line-height: 1.41em;
    margin-bottom: 0.5em;
    padding: 0;
  }
  .field, .actions {
    margin-bottom: 0.5em;
    padding: 0;
  }
  .actions {
    text-align: right;
    padding: 1em 0;
  }
  input, textarea, select, option {
    border: solid thin #888;
    box-sizing: border-box;
    font-size: 1em;
    padding: 0.5em;
    width: 100%;
  }
  label {
    padding: 0.5em 0;
  }
  input[type="submit"] {
    background-color: #bfb;
    border-radius: 0.354em;
    border: solid thin #888;
    color: black;
    font-size: 1.41em;
    font-weight: bold;
    padding: 0.354em 1em;
  }
  input[type="submit"]:hover {
    background-color: #9d9;
  }
  // Also, clean up the error styling
  #error_explanation {
    background-color: white;
    border-radius: 1em;
    border: solid thin red;
    margin-bottom: 0.5em;
    padding: 0.5em;
    width: 100%;
    h2 {
      background: none;
      color: red;
      font-size: 1.41em;
      line-height: 1.41em;
      padding: 1em;
    }
    ul {
      margin-top: 0;
      li {
        color: red;
        font-size: 1em;
      }
    }
  }
  .field_with_errors {
    background: none;
    color: red;
    width: 100%;
    label {
      font-weight: bold;
    }
    label::before {
      content: "! ";
    }
    input,textarea {
      background: pink;
    }
  }
}
      EOF
    end
  else
    edit DEPOT_CSS, 'form' do |data|
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

  post '/', {'product_id' => 2}
  get '/', screenshot: {
    filename: "o_1_checkout_form.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "orders/new",
    ]
  }

  desc 'Validate that required fields are present'
  edit 'app/models/order.rb', 'validate' do |data|
    msub /^()(#START:.*\n)*end/, <<-EOF.unindent(4), :mark => 'validate'
      # ...
    EOF
    msub /^()(#START:.*\n)*end/, <<-EOF.unindent(4), :mark => 'validate'
      #START_HIGHLIGHT
      validates :name, :address, :email, :presence => true
      validates :pay_type, :inclusion => pay_types.keys
      #END_HIGHLIGHT
    EOF
    sub! 'pay_types.keys', 'PAYMENT_TYPES' if $rails_version =~ /^(3|4\.0)/
    edit 'class Order', :mark => 'validate'
    edit /^end/, :mark => 'validate'
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Update the test data in the orders fixture'
  edit 'test/fixtures/orders.yml' do
    edit "name: MyString", :highlight do
      sub! /MyString/, 'Dave Thomas'
    end
    edit "email: MyString", :highlight do
      sub! /MyString/, 'dave@example.org' 
    end
    edit 'pay_type:', :highlight do
      sub! /MyString|1/, 'Check'
    end
    msub /^# Read about fixtures at() http.{50}/, "\n#", :optional
  end

  desc 'Move a line item from a cart to an order'
  edit 'test/fixtures/line_items.yml' do
    clear_all_marks
    msub /^two:.*(product(_id)?:.*?)\n/m, 'product: ruby'
    msub /^two:.*(cart(_id)?:.*?)\n/m, 'order: one'
    edit 'product: ruby', :highlight
    edit 'order: one', :highlight
    msub /^# Read about fixtures at() http.{50}/, "\n#", :optional
  end

  desc 'Define an optional relationship from the line item to the order'
  edit 'app/models/line_item.rb' do
    clear_all_marks
    edit 'belongs_to', :highlight do
      msub /.*()/, ', optional: true'
    end
    msub /class LineItem.*\n()/, <<-EOF.unindent(4), :highlight
      belongs_to :order, optional: true
    EOF

    if $rails_version =~ /^4\.[2-9]/
      gsub! 'optional: true', 'required: false' 
    elsif $rails_version =~ /^[34]/
      gsub! ', optional: true', ''
    end
  end

  desc 'Define a relationship from the order to the line item'
  edit 'app/models/order.rb', 'has_many' do |data|
    msub /^()(#START:.*\n)* *# \.\.\./, <<-EOF.unindent(4), :mark => 'has_many'
      has_many :line_items, :dependent => :destroy
    EOF
    edit 'class Order', :mark => 'has_many'
    edit 'has_many :line_items', :highlight
    edit '# ...', :mark => 'has_many'
    edit /^end()/, :mark => 'has_many'
    data.gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add line item to order, destroy cart, and redisplay catalog page'
  edit 'app/controllers/orders_controller.rb', 'create' do
    dcl 'create', :mark => 'create' do
      msub /@order = Order.new\(.*\)\n()/, <<-EOF.unindent(4)
        #START_HIGHLIGHT
        @order.add_line_items_from_cart(@cart)
        #END_HIGHLIGHT
      EOF
      msub /if @order.save\n()/, <<-EOF
        #START_HIGHLIGHT
        Cart.destroy(session[:cart_id])
        session[:cart_id] = nil
      EOF
      msub /Order was successfully created.*\n()/, <<-EOF
        #END_HIGHLIGHT
      EOF
      msub /redirect_to[\(\s](@order), :?notice/, 'store_index_url'
      msub /('Order was successfully created.')/,
        "\n          'Thank you for your order.'"
      msub /,( ):?location/, "\n          "
      msub /,( ):?status:?\s=?>?\s?:un/, "\n          "
    end
  end

  publish_code_snapshot :o

  desc 'Implement add_line_items_from_cart'
  edit 'app/models/order.rb', 'alifc' do
    clear_all_marks
    msub /^()end/, <<-EOF.unindent(4), :mark => 'alifc'
      def add_line_items_from_cart(cart)
        cart.line_items.each do |item|
          item.cart_id = nil
          line_items << item
        end
      end
    EOF
    edit 'class Order', :mark => 'alifc'
    dcl 'add_line_items_from_cart', :highlight
    edit '...', :mark => 'alifc'
    edit /^end/, :mark => 'alifc'
  end

  desc 'Modify the test to reflect the new redirect'
  edit 'test/*/orders_controller_test.rb', 'valid' do
    dcl 'should create order', :mark => 'valid' do
      linktype = (self =~ /_path/ ? 'path' : 'url')
      edit "order_#{linktype}", :highlight do
        msub /(order_#{linktype}.*)/, "store_index_#{linktype}"
      end
      sub! ', email:', ",\n        email:"
      sub! ', pay_type:', ",\n        pay_type:"
    end
  end

  desc 'take a look at the validation errors'
  post '/orders/new', { "order[name]" => "" }

  get '/', screenshot: {
    filename: "o_2_checkout_errors.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "orders/new",
      "/orders",
    ]
  }

  desc 'process an order'
  post '/orders/new',
    'order[name]' => 'Dave Thomas',
    'order[address]' => '123 Main St',
    'order[email]' => 'customer@example.com',
    'order[pay_type]' => 'Check'

  desc 'look at the underlying database'
  db "select * from orders"
  db "select * from line_items"

  desc 'hide the notice when adding items to the cart'
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
  end
end

section 12.2, 'Iteration G2: Atom Feeds' do
  overview <<-EOF
    Demonstrate various respond_to/format options, as well as "through"
    relations and basic authentication.
  EOF

  desc 'Define a "who_bought" member action'
  edit 'app/controllers/products_controller.rb', 'who_bought' do
    insert_at = /()\n *private/
    insert_at = /^()end/ unless self =~ insert_at
    msub insert_at, "\n"
    msub insert_at, <<-EOF.unindent(4), :mark => 'who_bought'
      def who_bought
        @product = Product.find(params[:id])
        @latest_order = @product.orders.order(:updated_at).last
        if stale?(@latest_order)
          respond_to do |format|
            format.atom
          end
        end
      end
    EOF
    if $rails_version =~ /^3\.[01]/
      msub /stale\?\((.*)\)/, 
        ":etag => @latest_order, :last_modified => @latest_order.created_at.utc"
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Define an Atom view (using the Atom builder)'
  edit 'app/views/products/who_bought.atom.builder' do
    self.all = <<-'EOF'.unindent(6)
      atom_feed do |feed|
        feed.title "Who bought #{@product.title}"

        feed.updated @latest_order.try(:updated_at) 
      
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
              author.name order.name
              author.email order.email
            end
          end
        end
      end
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add "orders" to the Product class'
  edit 'app/models/product.rb', 'relationships' do
    clear_all_marks
    msub /^( +#\.\.\.\n\n)/, ''
    edit /class.*has_many.*?\n/m, :mark=>'relationships' do
      self.all += "  #...\n"
    end
    edit /^end/, :mark=>'relationships'
    msub /has_many :line_items\n()/, <<-EOF.unindent(4), :highlight
      has_many :orders, :through => :line_items
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Add to the routes'
  edit 'config/routes.rb', 'root' do
    clear_highlights
    edit 'resources :products', :highlight do |products|
      products.all = <<-EOF.unindent(6)
        resources :products do
          get :who_bought, :on => :member
        end
      EOF
    end
    gsub! /\n\n\n+/, "\n\n"
    edit ':who_bought' do
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  fetch =  "--user dave:secret http://localhost:#$PORT/products/2/who_bought.atom"
  desc 'Fetch the Atom feed'
  cmd "curl --max-time 15 --silent #{fetch}"

  desc 'Look at the headers'
  cmd "curl --max-time 15 --silent --dump - --output /dev/null #{fetch}"
  req = Net::HTTP::Get.new('/products/2/who_bought.atom')
  req.basic_auth 'dave', 'secret'
  response = Net::HTTP.start('localhost', $PORT) {|http| http.request(req)}

  cmd "curl --max-time 15 --silent --dump - --output /dev/null #{fetch} " +
    "-H 'If-None-Match: #{response['Etag']}'"

  cmd "curl --max-time 15 --silent --dump - --output /dev/null #{fetch} " +
    "-H 'If-Modified-Since: #{response['Last-Modified']}'"

  publish_code_snapshot :p
end

unless $PUB or $rails_version =~ /^3\./
section 12.4, 'Iteration G2: Downloading an eBook' do
  overview <<-EOF
    demonstrate streaming with ActionController::Live
  EOF

  if Gorp::Config[:skip_actioncontroller_live]
    warn 'section skipped as this locks the database'
    next
  end
  
  if $rails_version =~ /^[34]/
    desc 'Switch to puma as a server'
    edit 'Gemfile', 'puma' do
      clear_all_marks
      self << "\ngem 'puma'\n"
      edit 'puma', :mark => 'puma'
    end

    restart_server
  end

  desc 'add a route for downloading a product'
  edit 'config/routes.rb' do
    msub /resources :products do\n()/, <<-EOF.unindent(2), :highlight
      get :download, :on => :member
    EOF
  end

  desc 'mock streaming implementation for download'
  edit 'app/controllers/products_controller.rb', 'download' do
    insert_at = /()\n *private/
    msub insert_at, "\n"
    msub insert_at, <<-'EOF'.unindent(4), :mark => 'download'
      include ActionController::Live
      def download
        response.headers['Content-Type'] = 'text/plain'
        40.times do |i|
          response.stream.write "Line #{i}\n\n"
          sleep 0.10
        end
        response.stream.write "Fini.\n"
      ensure
        response.stream.close
      end
    EOF
  end

  desc 'add order to the session'
  edit 'app/controllers/orders_controller.rb', 'create' do
    dcl 'create' do
      msub /\n()\s+format/, <<-EOF, :highlight
        session[:order_id] = @order.id
      EOF
    end
  end

  desc 'render order in the side bar'
  edit 'app/views/layouts/application.html.erb' do
    clear_all_marks
    msub /()\n +<ul>/, "\n" + <<-EOF, :highlight
      <%= render Order.find(session[:order_id]) if session[:order_id] -%>
    EOF
  end

  desc 'implement order partial'
  edit 'app/views/orders/_order.html.erb' do
    self.all = read('orders/_order.html.erb')
  end

  desc 'css tweaks'
  edit DEPOT_CSS, 'side' do
    clear_highlights
    edit '#cart', :highlight do
      msub /#cart()/, ', #order'
    end

    msub /^() +main/, <<-EOF + "\n", :highlight
      a, a:hover {
        color: white;
        background-color: #141;
      }
    EOF
  end

  desc 'place an order'
  post '/', 'product_id' => 2
  post '/orders/new',
    'order[name]' => 'Dave Thomas',
    'order[address]' => '123 Main St',
    'order[email]' => 'customer@example.com',
    'order[pay_type]' => 'Check'

  desc 'click download'
  get '/products/2/download'

  if $rails_version =~ /^[34]/
    desc 'Switch back to WEBRick'
    edit 'Gemfile', 'puma' do
      msub /()gem 'puma'/, '# '
    end

    restart_server
  end

  desc 'make sure that nothing is broken'
  test
end
end

section 12.5, 'Playtime' do
  if Gorp::Config[:skip_xml_serialization]
    warn 'xml serialization skipped'
    next
  end

  unless $rails_version =~ /^[34]/
    desc 'add activemodel-serializers-xml'
    edit 'Gemfile', 'as_xml' do
      clear_all_marks
      self << "\ngem 'activemodel-serializers-xml'\n"
      edit 'activemodel-serializers-xml', :mark => 'as_xml'
    end

    bundle 'install'
    restart_server

    desc 'include xml serializers'
    edit 'app/models/product.rb', 'asxml' do
      edit /^class.*\n/, mark: 'asxml'
      edit /^end.*\n/, mark: 'asxml'
      msub /^()class/, "require 'active_model/serializers/xml'\n",
        :highlight
      msub /^class.*\n()/, "  include ActiveModel::Serializers::Xml\n",
        :highlight
    end

    edit 'app/models/order.rb', 'asxml' do
      edit /^class.*\n/, mark: 'asxml'
      edit /^end.*\n/, mark: 'asxml'
      msub /^()class/, "require 'active_model/serializers/xml'\n",
        :highlight
      msub /^class.*\n()/, "  include ActiveModel::Serializers::Xml\n",
        :highlight
    end
  end

  desc 'Add the xml format to the controller'
  edit 'app/controllers/products_controller.rb', 'who_bought' do
    clear_highlights
    dcl 'who_bought' do
      msub /respond_to.*\n()/, <<-EOF, :highlight
        format.xml { render :xml => @product }
      EOF
    end
  end

  desc 'Fetch the XML, see that there are no orders there'
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought.atom"

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
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought.xml"

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
      wb.msub /respond_to.*\n()/, <<-EOF, :highlight
        format.html
      EOF
    end
  end

  desc 'See the (raw) HTML'
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought"

  desc 'Anything that XML can do, JSON can too...'
  edit 'app/controllers/products_controller.rb', 'who_bought' do |data|
    data.dcl('who_bought') do |wb|
      xml = wb[/\n(\s+format.xml \{.*?\}\n)/m,1]
      wb.msub /respond_to.*?\n()\s+end/m, xml.gsub('xml','json')
    end
  end

  desc 'Fetch the data in JSON format'
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought.json"

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
  edit 'app/controllers/products_controller.rb', 'who_bought' do
    clear_highlights
    dcl('who_bought') do
      edit 'format.xml', :highlight
      msub /format.xml( \{ render .*)/, ''
    end
  end

  desc 'Fetch the (much streamlined) XML'
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought.xml"

  desc 'Verify that the tests still pass'
  test

  desc 'Commit'
  cmd 'git commit -a -m "Orders"'
  cmd 'git tag iteration-g'
end

unless $rails_version =~ /^4|^5\.0/
section 13.1, 'Iteration H1: Webpacker and App-Like JavaScript' do
  overview <<-EOF
    Demonstrate how Webpacker works and why it exists by using React.
  EOF

  if $rails_version =~ /^5/
    edit 'Gemfile' do
      self << "gem 'webpacker', '~> 3.0'"
    end
    bundle 'install'
    cmd 'echo Y | rails webpacker:install'
  end

  cmd 'rails webpacker:install:react'
  edit 'app/javascript/packs/hello_react.jsx' do
    sub! /^\/\/.*$/,''
    sub! /^\/\/.*$/,''
    sub! /^\/\/.*$/,''
  end
  bundle 'install'
  edit 'app/views/orders/new.html.erb' do
    clear_all_marks
    clear_highlights
    self << %{
<!-- START_HIGHLIGHT -->
<%= javascript_pack_tag("hello_react") %>
<!-- END_HIGHLIGHT -->
}
  end

  restart_server

  get '/', screenshot: {
    filename: "pa_1_js_fixed.pdf",
    dimensions: [ 1024, 800 ],
    workflow: [
      "line_items?product_id=2",
      "orders/new",
    ]
  }

  post '/', 'product_id' => 2
  post '/orders/new',
    'order[name]' => 'Dave Thomas',
    'order[address]' => '123 Main St',
    'order[email]' => 'customer@example.com',
    'order[pay_type]' => 'Check'
  publish_code_snapshot :pa

  edit 'app/views/orders/_form.html.erb' do
    clear_all_marks
    clear_highlights
    edit /<div class="field">.*\n\s+<%= form.label :email %>/ do
      sub! /<div class="field"/,"<!-- START:pay-type-component -->\n  <div class=\"field\""
    end
    sub! /<div class="field">.*\n\s+<%= form.label :pay_type %>.*\n\s+<%= form.select :pay_type.*\n.*\n\s+<\/div>/,
      "<!-- START_HIGHLIGHT -->\n  <div id='pay-type-component'></div>\n<!-- END_HIGHLIGHT -->"
    sub! /^<% end %>/,"<% end %>\n<!-- END:pay-type-component -->"
  end
  edit 'app/views/orders/new.html.erb' do
    sub! /<%= javascript_pack_tag\("hello_react"\) %>/, "<%= javascript_pack_tag(\"pay_type\") %>"
  end
  edit 'app/javascript/packs/pay_type.jsx' do
    self << %{import React           from 'react'              // <callout id="co.payment-details.pay_type.import-react"/>
import ReactDOM        from 'react-dom'           // <callout id="co.payment-details.pay_type.import-react-dom"/>
import PayTypeSelector from 'PayTypeSelector'     // <callout id="co.payment-details.pay_type.import-PayTypeSelector"/>

document.addEventListener('turbolinks:load', function() {       // <callout id="co.payment-details.pay_type.DOMContentLoaded"/>
  var element = document.getElementById(\"pay-type-component\"); // <callout id="co.payment-details.pay_type.getElementById"/>
  ReactDOM.render(<PayTypeSelector />, element);                 // <callout id="co.payment-details.pay_type.jsx"/>
});
}
  end
  cmd 'mkdir app/javascript/PayTypeSelector'
  edit 'app/javascript/PayTypeSelector/index.jsx' do
    self << %{import React from 'react'

class PayTypeSelector extends React.Component \{
  render() \{
    return (
      <div className="field">
        <label htmlFor="order_pay_type">Pay type</label>
        <select id="order_pay_type" name="order[pay_type]">
          <option value="">Select a payment method</option>
          <option value="Check">Check</option>
          <option value="Credit card">Credit card</option>
          <option value="Purchase order">Purchase order</option>
        </select>
      </div>
    );
  \}
\}
export default PayTypeSelector
}
  end
  publish_code_snapshot :pb
  cmd 'rm app/javascript/PayTypeSelector/index.jsx'
  edit 'app/javascript/PayTypeSelector/index.jsx' do
    self << %{//START:import
import React from 'react'

// START_HIGHLIGHT
import NoPayType            from './NoPayType';
import CreditCardPayType    from './CreditCardPayType';
import CheckPayType         from './CheckPayType';
import PurchaseOrderPayType from './PurchaseOrderPayType';
// END_HIGHLIGHT
// END:import

// START:bind
class PayTypeSelector extends React.Component \{
  // START_HIGHLIGHT
  constructor(props) \{
    super(props);
    this.onPayTypeSelected = this.onPayTypeSelected.bind(this);
    this.state = { selectedPayType: null };
  \}
  // END_HIGHLIGHT
// END:bind

// START:onPayTypeSelected
  onPayTypeSelected(event) \{
    // START_HIGHLIGHT
    this.setState({ selectedPayType: event.target.value });
    // END_HIGHLIGHT
  \}
  // END:onPayTypeSelected

  // START:render
  render() \{
    // START_HIGHLIGHT
    let PayTypeCustomComponent = NoPayType;
    if (this.state.selectedPayType == "Credit card") {
      PayTypeCustomComponent = CreditCardPayType;
    } else if (this.state.selectedPayType == "Check") {
      PayTypeCustomComponent = CheckPayType;
    } else if (this.state.selectedPayType == "Purchase order") {
      PayTypeCustomComponent = PurchaseOrderPayType;
    }
    // END_HIGHLIGHT
    return (
      // START_HIGHLIGHT
      <div>
        <div className="field">
          <label htmlFor="order_pay_type">Pay type</label>
          <select id="order_pay_type" onChange={this.onPayTypeSelected} 
            name="order[pay_type]">
            <option value="">Select a payment method</option>
            <option value="Check">Check</option>
            <option value="Credit card">Credit card</option>
            <option value="Purchase order">Purchase order</option>
          </select>
        </div>
        <PayTypeCustomComponent />
      </div>
      // END_HIGHLIGHT
    );
  \}
  // END:render
\}
export default PayTypeSelector
}
  end
  edit 'app/javascript/PayTypeSelector/NoPayType.jsx' do
    self << %{import React from 'react'

class NoPayType extends React.Component \{
  render() \{
    return (<div></div>);
  \}
\}
export default NoPayType
}
  end
  edit 'app/javascript/PayTypeSelector/CreditCardPayType.jsx' do
    self << %{import React from 'react'

class CreditCardPayType extends React.Component \{
  render() \{
    return (
      <div>
        <div className="field">
          <label htmlFor="order_credit_card_number">CC #</label>
          <input type="password"
                 name="order[credit_card_number]" 
                 id="order_credit_card_number" />
        </div>
        <div className="field">
          <label htmlFor="order_expiration_date">Expiry</label>
          <input type="text"
                 name="order[expiration_date]" 
                 id="order_expiration_date"
                 size="9"
                 placeholder="e.g. 03/19" />
        </div>
      </div>
    );
  \}
\}
export default CreditCardPayType
}
  end
  edit 'app/javascript/PayTypeSelector/CheckPayType.jsx' do
    self << %{import React from 'react'

class CheckPayType extends React.Component \{
  render() \{
    return (
      <div>
        <div className="field">
          <label htmlFor="order_routing_number">Routing #</label>
          <input type="password"
                 name="order[routing_number]" 
                 id="order_routing_number" />
        </div>
        <div className="field">
          <label htmlFor="order_account_number">Account #</label>
          <input type="text"
                 name="order[account_number]" 
                 id="order_account_number" />
        </div>
      </div>
    );
  \}
\}
export default CheckPayType
}
  end
  edit 'app/javascript/PayTypeSelector/PurchaseOrderPayType.jsx' do
    self << %{import React from 'react'

class PurchaseOrderPayType extends React.Component \{
  render() \{
    return (
      <div>
        <div className="field">
          <label htmlFor="order_po_number">PO #</label>
          <input type="password"
                 name="order[po_number]" 
                 id="order_po_number" />
        </div>
      </div>
    );
  \}
\}
export default PurchaseOrderPayType
}
  end
  edit "app/controllers/orders_controller.rb" do
    clear_highlights
    msub /^()end/, %{
    # START: pay_type_params
      
    def pay_type_params
      if order_params[:pay_type] == "Credit Card"
        params.require(:order).permit(:credit_card_number, :expiration_date)
      elsif order_params[:pay_type] == "Check"
        params.require(:order).permit(:routing_number, :account_number)
      elsif order_params[:pay_type] == "Purchase Order"
        params.require(:order).permit(:po_number)
      else
        {}
      end
    end

    # END: pay_type_params
}
  end
  edit "config/application.rb" do
    msub /^()  end/, %{
    #START:filter_parameters
    config.filter_parameters += [ :credit_card_number ]
    #END:filter_parameters
}
  end

  publish_code_snapshot :pc
end

section 13.2, 'Iteration H2: System testing' do
  unless $rails_version =~ /^5.1/
    edit 'test/system/products_test.rb' do
      sub! ':one', ':ruby'
      sub! 'Product was successfully created', 'Title has already been taken'
    end
    cmd 'rm test/system/carts_test.rb'
    cmd 'rm test/system/line_items_test.rb'

    edit 'test/system/orders_test.rb' do
      dcl 'creating a Order' do
        sub! /.*/m, ''
      end

      dcl 'updating a Order' do
        sub! /.*/m, ''
      end

      gsub! /\n\n+/, "\n\n"
    end
  end

  edit 'test/system/orders_test.rb' do
    gsub! /^  #.*\n/, ''
    msub /^()end/, <<-EOF.unindent(4), :highlight
      test "check routing number" do
        visit store_index_url

        click_on 'Add to Cart', match: :first

        click_on 'Checkout'

        fill_in 'order_name', with: 'Dave Thomas'
        fill_in 'order_address', with: '123 Main Street'
        fill_in 'order_email', with: 'dave@example.com'

        assert_no_selector "#order_routing_number"

        select 'Check', from: 'Pay type'

        assert_selector "#order_routing_number"
      end 
    EOF
  end

  cmd 'RAILS_ENV=test bin/webpack' if $rails_version =~ /^5\.1/

  cmd 'rake test:system'
  cmd 'rake test'
end
end


section 14.1, 'Iteration I1: Email Notifications' do
  desc 'Create a mailer'
  if $rails_version =~ /^[34]/
    generate 'mailer OrderMailer received shipped'
  else
    generate 'mailer Order received shipped'
  end

  desc 'Edit development configuration'
  edit 'config/environments/development.rb' do
    msub /action_mailer.*\n()/, "\n" + <<-EOF.unindent(4), :highlight
      # Don't actually send emails
      config.action_mailer.delivery_method = :test
      #
      # Alternate configuration example, using gmail:
      #   config.action_mailer.delivery_method = :smtp
      #   config.action_mailer.smtp_settings = {
      #     address:        "smtp.gmail.com",
      #     port:           587, 
      #     domain:         "domain.of.sender.net",
      #     authentication: "plain",
      #     user_name:      "dave",
      #     password:       "secret",
      #     enable_starttls_auto: true
      #   } 
    EOF
  end

  desc 'Tailor the from address'
  edit 'app/mailers/order*.rb' do
    if match /from/
      msub /from:?\s*=?>?\s*(.*)/, "'Sam Ruby <depot@example.com>'"
    else
      msub /class.*\n()/, "  default from: 'Sam Ruby <depot@example.com>'\n"
    end
    edit 'from', :highlight
  end

  desc 'Tailor the confirm receipt email'

  unless Dir['app/views/order*/received.html.erb'].empty?
    cmd 'rm app/views/order*/received.html.erb'
  end

  edit 'app/views/order*/received.text.erb' do
    self.all = <<-EOF.unindent(6)
      Dear <%= @order.name %>

      Thank you for your recent order from The Pragmatic Store.

      You ordered the following items:

      <%= render @order.line_items -%>

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

  publish_code_snapshot :q

  desc 'Get the order, sent the confirmation'
  edit 'app/mailers/order*.rb' do
    clear_highlights
    %w(received shipped).each do |notice|
      dcl notice, :mark => notice
      msub /def #{notice}(.*)/, '(order)'
      msub /(.*@greeting.*\n)/, ''
      msub /def #{notice}.*\n()/, <<-EOF.unindent(4)
        @order = order
      EOF
      if notice == 'received'
        msub /("to@example.org")/, 
          "order.email, :subject => 'Pragmatic Store Order Confirmation'"
      else
        msub /("to@example.org")/, 
          "order.email, :subject => 'Pragmatic Store Order Shipped'"
      end
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Invoke mailer from the controller'
  edit 'app/controllers/orders_controller.rb', 'create' do
    clear_highlights
    dcl 'create' do
      msub /\n()\s+format/, <<-EOF, :highlight
        OrderMailer.received(@order).deliver_later
      EOF
      if $rails_version =~ /^3\./ or $rails_version =~ /^4\.[01]/
        gsub! 'deliver_later', 'deliver'
      end
    end
  end

  desc 'Tailor the confirm shipped email (this time in HTML)'
  cmd "rm #{Dir['app/views/order_*'].first}/shipped.text.erb"
  edit "#{Dir['app/views/order_*'].first}/shipped.html.erb" do
    self.all = <<-EOF.unindent(6)
      <h3>Pragmatic Order Shipped</h3>
      <p>
        This is just to let you know that we've shipped your recent order:
      </p>

      <table>
        <tr><th colspan="2">Qty</th><th>Description</th></tr>
      <%= render @order.line_items -%>
      </table>
    EOF
  end

  desc 'Review HTML partial for the line items'
  edit 'app/views/line_items/_line_item.html.erb' do
    clear_all_marks
  end

  desc 'Update the test case'
  edit 'test/mailers/order*_test.rb' do
    2.times do
      msub /Order\w*\.\w+()$/, '(orders(:one))'
      msub /do()\s+mail =/, "\n#START_HIGHLIGHT"
      msub /mail.body.encoded()\s+end/, "\n#END_HIGHLIGHT"
    end
    gsub! 'Received', 'Pragmatic Store Order Confirmation'
    gsub! 'Shipped', 'Pragmatic Store Order Shipped'
    gsub! 'to@example.org', 'dave@example.org'
    gsub! 'from@example.com', 'depot@example.com'
    msub /assert_match (".*?), mail/, '/1 x Programming Ruby 1.9/'
    msub /assert_match ".*?,( )mail/, "\n      "
    msub /assert_match (".*?),\s+mail/, 
      '/<td[^>]*>1<\/td>\s*<td>Programming Ruby 1.9<\/td>/'
  end

  if $rails_version =~ /^3/ or $rails_version =~ /^4\.0/
    rake 'db:test:load'
  end

  test 'test/mailers/order*_test.rb'
  publish_code_snapshot :qa
end

section 14.2, 'Iteration I2: Connecting to a Slow Payment Processor with Active Job' do
  edit 'lib/pago.rb' do
    self <<%{require 'ostruct'
class Pago
  def self.make_payment(order_id:,
                        payment_method:,
                        payment_details:)

    case payment_method
    when :check
      Rails.logger.info "Processing check: " +
        payment_details.fetch(:routing).to_s + "/" + 
        payment_details.fetch(:account).to_s
    when :credit_card
      Rails.logger.info "Processing credit_card: " +
        payment_details.fetch(:cc_num).to_s + "/" + 
        payment_details.fetch(:expiration_month).to_s + "/" + 
        payment_details.fetch(:expiration_year).to_s
    when :po
      Rails.logger.info "Processing purchase order: " +
        payment_details.fetch(:po_num).to_s
    else
      raise "Unknown payment_method \#{payment_method}"
    end
    sleep 3 unless Rails.env.test?
    Rails.logger.info "Done Processing Payment"
    OpenStruct.new(succeeded?: true)
  end
end
}
  end
  edit 'app/models/order.rb' do
    clear_highlights
    clear_all_marks
    msub /^()class/,<<EOF
# START_HIGHLIGHT
require 'pago'
# END_HIGHLIGHT

EOF
    msub /^()end/, <<EOF

# START_HIGHLIGHT
  def charge!(pay_type_params)
    payment_details = {}
    payment_method = nil

    case pay_type
    when "Check"
      payment_method = :check
      payment_details[:routing] = pay_type_params[:routing_number]
      payment_details[:account] = pay_type_params[:account_number]
    when "Credit card"
      payment_method = :credit_card
      month,year = pay_type_params[:expiration_date].split(/\/)
      payment_details[:cc_num] = pay_type_params[:credit_card_number]
      payment_details[:expiration_month] = month
      payment_details[:expiration_year] = year
    when "Purchase order"
      payment_method = :po
      payment_details[:po_num] = pay_type_params[:po_number]
    end

    payment_result = Pago.make_payment(
      order_id: id,
      payment_method: payment_method,
      payment_details: payment_details
    )

    if payment_result.succeeded?
      OrderMailer.received(self).deliver_later
    else
      raise payment_result.error
    end
  end
# END_HIGHLIGHT
EOF
  end
  generate "job charge_order"
  edit "app/jobs/charge_order_job.rb" do
    msub /(  def perform\(\*args\))/, <<EOF
  # START_HIGHLIGHT
  def perform(order,pay_type_params)
EOF
    msub /(    . Do something later)/,<<EOF
    order.charge!(pay_type_params)
  # END_HIGHLIGHT
EOF
  end
  edit "app/controllers/orders_controller.rb" do
    msub /(        OrderMailer.received\(@order\).deliver_later)/,"        ChargeOrderJob.perform_later(@order,pay_type_params.to_h)"
  end

  edit "test/system/orders_test.rb" do
    msub /(class OrdersTest < ApplicationSystemTestCase)/,%{
#START:test_helper
class OrdersTest < ApplicationSystemTestCase
  # START_HIGHLIGHT
  include ActiveJob::TestHelper
  # END_HIGHLIGHT
#END:test_helper
    }
  
    msub /^(  test "check routing number" do)/,%{
# START:clear
  test "check routing number" do

    # START_HIGHLIGHT
    LineItem.delete_all
    Order.delete_all
    # END_HIGHLIGHT

    visit store_index_url
# END:clear
}
  
    msub /^(    assert_selector "#order_routing_number")/,%{
# START:fill_in
    assert_selector "#order_routing_number"

# START_HIGHLIGHT
    fill_in "Routing #", with: "123456"
    fill_in "Account #", with: "987654"
# END_HIGHLIGHT
# END:fill_in

# START:perform_enqueued_jobs
# START_HIGHLIGHT
    perform_enqueued_jobs do
      click_button "Place Order"
    end
# END_HIGHLIGHT
# END:perform_enqueued_jobs

# START:check_order
# START_HIGHLIGHT
    orders = Order.all
    assert_equal 1, orders.size

    order = orders.first

    assert_equal "Dave Thomas",      order.name
    assert_equal "123 Main Street",  order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check",            order.pay_type
    assert_equal 1, order.line_items.size
# END_HIGHLIGHT
# END:check_order

# START:check_mail
# START_HIGHLIGHT
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"],                 mail.to
    assert_equal 'Sam Ruby <depot@example.com>',       mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject
# END_HIGHLIGHT
# START:check_mail
}
  end
  cmd 'rake test:system'
  cmd 'rake test'
  publish_code_snapshot :qb
end

section 14.3, 'Playtime' do
  cmd 'git commit -a -m "formats"'
  cmd 'git tag iteration-h'
end

section 15.1, 'Iteration J1: Adding Users' do
  desc 'Scaffold the user model'
  if File.exist? 'public/images'
    generate 'scaffold User name:string hashed_password:string salt:string'
  else
    if $rails_version =~ /^3/
      generate 'scaffold User name:string password_digest:string'
    else
      generate 'scaffold User name:string password:digest'
    end

    if File.read('Gemfile') =~ /^#\sgem\s+['"]bcrypt(-ruby)?['"]/
      desc 'uncomment out bcrypt'
      edit 'Gemfile', 'bcrypt' do
        clear_all_marks
        edit /^.*has_secure_password\n.*\n/, :mark => 'bcrypt'
        edit /# gem ['"]bcrypt.*\n/, :highlight do
          msub /^(#\s)/, ''
        end
      end
      restart_server
    end
  end

  desc 'Run the migration'
  db :migrate

  desc 'wrap the flash in an if statement'
  edit "app/views/users/index.html.erb" do
    msub /(<p id="notice.*$)/,%{
<!-- START:notice -->
<!-- START_HIGHLIGHT -->
<% if notice %>
  <aside class="notice"><%= notice %></aside>
<% end %>
<!-- END_HIGHLIGHT -->
<!-- END:notice -->
    }
  end

  desc 'Add validation, has_secure_password'
  edit "app/models/user.rb" do
    if File.exist? 'public/images'
      self.all = read('users/user.rb')
    else
      msub /class.*\n()/, 
      "  validates :name, :presence => true, :uniqueness => true\n", :highlight

      if $rails_version =~ /^3\./
        msub /class.*\n()/, 
          "    attr_accessible :name, :password, :password_confirmation\n"
        msub /()end/, "    has_secure_password\n"
      end
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Avoid redirect after create, update operations'
  %w(create update).each do |action|
    edit 'app/controllers/users_controller.rb', action do
      dcl action, :mark do
        edit /.*'.*'.*/, :highlight do
          gsub!("'",'"').sub!('User ', 'User #{@user.name} ')
        end
        msub /redirect_to\(?\s?(@user, ):?notice/, "users_url,\n" + (' ' * 10)
        sub! ', status: :unprocessable_entity', 
          ",\n" + (' ' * 10) + 'status: :unprocessable_entity'
      end
    end
  end

  desc 'Display users sorted by name'
  edit 'app/controllers/users_controller.rb', 'index' do
    dcl 'index', :mark do
      edit '.all', :highlight
      msub /\.(all)/, 'order(:name)'
    end
  end

  if $rails_version =~ /^(3|4\.[01])/
    desc 'Add Notice'
    edit 'app/views/users/index.html.erb' do
      msub /<\/h1>\n()/, <<-EOF.unindent(8), :highlight
        <% if notice %>
          <aside class="notice"><%= notice %></aside>
        <% end %>
      EOF
      if File.exist? 'public/images'
        msub /(.*<th>Hashed password.*\n)/, ''
        msub /(.*<th>Salt.*\n)/, ''
        msub /(.*user.hashed_password.*\n)/, ''
        msub /(.*user.salt.*\n)/, ''
      elsif self =~ /password/i
        msub /(.*<th>Password digest.*\n)/, ''
        msub /(.*user.password_digest.*\n)/, ''
      end
      unless $rails_version =~ /^3\.[01]/
        if self =~ /,( ):?data/
          msub /,( ):?data/, "\n" + (' ' * 8)
        else
          msub /,( ):?method/, "\n" + (' ' * 6)
        end
      end
    end
  end

  desc 'Update form used to both create and update users'
  edit "app/views/users/_form.html.erb" do
    msub /\A()/, <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <div class="depot_form">

      <!-- END_HIGHLIGHT -->
    EOF

    edit 'pluralize' do
      msub /%>()/, "\n       "
    end

    msub /^()  <div class="field">/, <<-EOF.unindent(4)
      <!-- START_HIGHLIGHT -->
      <h2>Enter User Details</h2>

      <!-- END_HIGHLIGHT -->
    EOF

    edit 'label :name', :highlight do
      msub /:name()/, ", 'Name:'"
    end
    edit 'field :name', :highlight do
      msub /() %>/, ', size: 40'
    end

    edit 'label :password ', :highlight do
      msub /:password()/, ", 'Password:'"
    end
    edit 'field :password', :highlight do
      msub /() %>/, ', size: 40'
    end

    edit 'label :password_', :highlight do
      msub /:password_confirmation()/, ", 'Confirm:'"
    end
    msub /^(\s*<%= form.password_field :password_confirmation.*%>)/,%{
    <!-- START_HIGHLIGHT -->
    <%= form.password_field :password_confirmation,
                            id: :user_password_confirmation,
                            size: 40 %>
    <!-- END_HIGHLIGHT -->
    }

    msub /\n()\Z/, <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->

      </div>
      <!-- END_HIGHLIGHT -->
    EOF

    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  get '/users/new', screenshot: {
    filename: "r_1_new_user.pdf",
    dimensions: [ 1024, 300 ]
  }

  desc 'Demonstrate creating a new user'
  get '/users'
  post '/users/new',
    'user[name]' => 'dave',
    'user[password]' => 'secret',
    'user[password_confirmation]' => 'secret'

  desc 'Show how this is stored in the database'
  db 'select * from users'

  desc 'Update tests to reflect the changes in redirection and uniqueness'
  if $rails_version =~ /^3\./
    edit 'test/*/users_controller_test.rb', 'update' do
      msub /\A()/, "#START:update\n"
      msub /^  end\n()/, "#END:update\n"
      edit /^end/, :mark => 'update'

      msub /setup do\n()/, <<-EOF.unindent(4) + "\n"
        #START_HIGHLIGHT
        @input_attributes = {
          :name                  => "sam",
          :password              => "private",
          :password_confirmation => "private"
        }
        #END_HIGHLIGHT
      EOF

      %w(update create).each do |test|
        dcl "should #{test} user", :mark => 'update' do
          msub /\A()/, "  #...\n"
          if match /attributes/
            edit 'attributes', :highlight
            sub! '@user.attributes', '@input_attributes'
          else
            edit /^\s+(put|post|patch) :.*\n/, :highlight do
              sub! /\{.*\}/, "@input_attributes"
            end
          end
          edit 'user_path', :highlight
          msub /(user_path.*)/, 'users_path'
          msub /,( )password/, "\n" + (' ' * 8)
        end
      end

      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  else
    edit 'test/*/users_controller_test.rb', 'create' do
      dcl "should create user", :mark => 'create' do
        edit '@user.name', :highlight
        sub! '@user.name', "'sam'"

        edit "assert_redirected_to user_", :highlight do
          msub /(user_)/, "users_"
          msub /(\(.*\))/, ''
        end

        sub! /, password:/, ",\n" + (' ' * 6) + 'password:'
      end
    end

    edit 'test/*/users_controller_test.rb', 'create' do
      dcl "should update user", :mark => 'update' do
        edit "assert_redirected_to user_", :highlight do
          msub /(user_)/, "users_"
          msub /(\(.*\))/, ''
        end

        sub! /, password:/, ",\n" + (' ' * 6) + 'password:'
      end
    end
  end

  desc 'Make sure that all test names are unique'
  edit "test/fixtures/users.yml" do
    if File.exist? 'public/images'
      msub /(#.*)/, '<% SALT = "NaCl" unless defined?(SALT) %>'
      edit /one:.*?\n\n/m do
        msub  /name: (.*)/, 'dave'
        msub  /salt: (.*)/, '<%= SALT %>'
        msub  /hashed_password: (.*)/, 
          "<%= User.encrypt_password('secret', SALT) %>"
      end
    else
      edit /one:.*?\n\n/m do
        edit 'name:', :highlight
        msub /^  name: (.*)\n/, 'dave'
        msub /password_digest: (.*)/, 
          "<%= BCrypt::Password.create('secret') %>" if $rails_version =~ /^3\./
      end
      edit /two:.*\Z/m do
        edit 'name:', :highlight
        msub /^  name: (.*)\n/, 'susannah'
      end
      msub /^# Read about fixtures at() http.{50}/, "\n#", :optional
    end
  end

  if Gorp::Config[:inline_queue]
    desc 'Workaround https://github.com/rails/rails/issues/23989'
    edit 'config/environments/test.rb' do
      msub /()^end/, "\nconfig.active_job.queue_adapter = :inline\n"
    end
  end

  test
end

section 15.2, 'Iteration J2: Authenticating Users' do
  desc 'Generate empty controllers for sessions and administration'
  generate 'controller Sessions new create destroy'
  generate 'controller Admin index'

  desc 'Implement login in and out by storing the user_id in the session'
  edit "app/controllers/sessions_controller.rb" do
    dcl 'create', :mark => 'login' do
      msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        user = User.find_by_name(params[:name])
        if user.try(:authenticate, params[:password])
          session[:user_id] = user.id
          redirect_to admin_url
        else
          redirect_to login_url, :alert => "Invalid user/password combination"
        end
      EOF
      gsub! 'by_name(', 'by(name: ' unless $rails_version =~ /^3/
      if File.exist? 'public/images'
        msub /user = (.*)/, 
          'User.authenticate(params[:name], params[:password])'
        msub /user (and .*)/, ''
      end
    end
    dcl 'destroy', :mark => 'logout' do
      msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        session[:user_id] = nil
        redirect_to store_index_url, :notice => "Logged out"
      EOF
    end
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'Create the view using form_for as there is no underlying model'
  edit "app/views/sessions/new.html.erb" do
    self.all = read('users/login.html.erb')
  end

  desc 'Create a landing page for the administrator'
  edit "app/views/admin/index.html.erb" do
    self.all = read('users/index.html.erb')
  end

  desc 'Make the orders count available to the admin page'
  edit "app/controllers/admin_controller.rb" do
    dcl 'index' do
      msub /^()\s*end/, <<-EOF.unindent(4), :highlight
        @total_orders = Order.count
      EOF
    end
  end

  desc 'Connect the routes to the controller actions'
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
    gsub! /\n\n\n+/, "\n\n"
  end

  desc 'Do a login'
  post '/login', {'name' => 'dave', 'password' => 'secret'},
    screenshot: { filename: "r_2_login.pdf", dimensions: [ 1024, 200 ], submit_form: true }

  unless $rails_version =~ /^[34]/
    edit "test/*/admin_controller_test.rb" do |data|
      edit 'admin_index_url', :highlight
      sub! 'admin_index_url', 'admin_url'
    end
  end

  desc 'Fix the sessions controller test'
  edit "test/*/sessions_controller_test.rb" do |data|
    if $rails_version =~ /^[34]/
      dcl 'should get create' do
        self.all = <<-EOF.unindent(8)
          test "should login" do
            dave = users(:one)
            post :create, :name => dave.name, :password => 'secret'
            assert_redirected_to admin_url
            assert_equal dave.id, session[:user_id]
          end

          test "should fail login" do
            dave = users(:one)
            post :create, :name => dave.name, :password => 'wrong'
            assert_redirected_to login_url
          end
        EOF
      end
      dcl 'should get destroy' do
        self.all = <<-EOF.unindent(8)
          test "should logout" do
            delete :destroy
            assert_redirected_to store_index_url
          end
        EOF
      end
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    else
      dcl 'should get new' do
        self.all = <<-EOF.unindent(8)
          test "should prompt for login" do
            get login_url
            assert_response :success
          end
        EOF
      end

      dcl 'should get create' do
        self.all = <<-EOF.unindent(8)
          test "should login" do
            dave = users(:one)
            post login_url, params: { name: dave.name, password: 'secret' }
            assert_redirected_to admin_url
            assert_equal dave.id, session[:user_id]
          end

          test "should fail login" do
            dave = users(:one)
            post login_url, params: { name: dave.name, password: 'wrong' }
            assert_redirected_to login_url
          end
        EOF
      end

      dcl 'should get destroy' do
        self.all = <<-EOF.unindent(8)
          test "should logout" do
            delete logout_url
            assert_redirected_to store_index_url
          end
        EOF
      end
    end
  end

  test
end

section 15.3, 'Iteration J3: Limiting Access' do
  desc 'require authorization before every access'
  edit "app/controllers/application_controller.rb", 'auth' do
    clear_highlights
    edit /class.*\n/, :mark => 'auth' do
      msub /\n()\Z/, <<-EOF.unindent(6), :highlight
        before_action :authorize
      EOF
      gsub! '_action', '_filter' if $rails_version =~ /^3\./
    end

    edit /^end\n?$/, :mark => 'auth' do
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
    gsub! 'by_id(', 'by(id: ' unless $rails_version =~ /^3/
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc 'whitelist the sessions and store controllers'
  %w(sessions store).each do |controller|
    edit "app/controllers/#{controller}_controller.rb", 'setup' do |data|
      data.edit /class.*\n/, :mark => 'setup' do
        msub /class.*\n()/, <<-EOF.unindent(8), :highlight
          skip_before_action :authorize
        EOF
        gsub! '_action', '_filter' if $rails_version =~ /^3\./
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

  auth.keys.each do |controller|
    if auth[controller]
      desc "whitelist #{controller.sub(/s$/,'')} operations"
      edit "app/controllers/#{controller}_controller.rb", 'setup' do |data|
        clear_all_marks
        clear_highlights
        data.edit /class.*\n/, :mark => 'setup' do
          msub /class.*\n()/, <<-EOF.unindent(10), :highlight
            skip_before_action :authorize, :only => #{auth[controller].inspect}
          EOF
          gsub! '_action', '_filter' if $rails_version =~ /^3\./
          gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
        end
      end
    end
  end

  desc 'Cause all tests to do an implicit login'
  edit 'test/test_helper.rb' do
    if $rails_version =~ /^[34]/
      edit /\n +# Add more.*\nend\n/ do
        msub /\A()/, <<-EOF.unindent(8)
          # ...
        EOF
        msub /^()end/, <<-EOF.unindent(8)
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
    else
      msub /()\Z/, "\n"
      msub /()\Z/, <<-EOF.unindent(8), mark: 'more'
        class ActionDispatch::IntegrationTest
          def login_as(user)
            if respond_to? :visit
              visit login_url
              fill_in :name, with: user.name
              fill_in :password, with: 'secret'
              click_on 'Login'
            else
              post login_url, params: { name: user.name, password: 'secret' }
            end
          end

          def logout
            delete logout_url
          end

          def setup
            login_as users(:one)
          end
        end
      EOF
    end
  end

  desc 'Show that the now pass'
  test
end

section 15.4, 'Iteration J4: Adding a Sidebar' do

  desc 'Add admin links and a button to Logout'
  edit "app/views/layouts/application.html.erb" do |data|
    data.clear_highlights
    data.msub /<nav class="side_nav">.*?() *<\/nav>/m, "\n" + <<-EOF.gsub(/^/, '  '), :highlight
      <% if session[:user_id] %>
        <nav class="logged_in_nav">
          <ul>
            <li><%= link_to 'Orders',   orders_path   %></li>
            <li><%= link_to 'Products', products_path %></li>
            <li><%= link_to 'Users',    users_path    %></li>
            <li><%= button_to 'Logout', logout_path, :method => :delete   %></li>
          </ul>
        </nav>
      <% end %>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Add some styles"
  edit "app/assets/stylesheets/application.scss" do
    msub /\s*END:side.*$()/, %{

// START: logged_in_nav
nav.logged_in_nav {
  border-top: solid thin #bfb;
  padding: 0.354em 0;
  margin-top: 0.354em;
  input[type="submit"] {
    // Make the logout button look like a
    // link, so it matches the nav style
    background: none;
    border: none;
    color: #bfb;
    font-size: 1em;
    letter-spacing: 0.354em;
    margin: 0;
    padding: 0;
    text-transform: uppercase;
  }
  input[type="submit"]:hover {
    color: white;
  }
}
// END: logged_in_nav
}
  end

  desc 'Log out'
  post '/admin', 'submit' => 'Logout'

  desc 'Demonstrate that everybody can get to the store'
  get '/'

  desc 'Demonstrate that login is required to see the products'
  get '/products'

  desc 'Log in'
  post '/login',
    'name' => 'dave',
    'password' => 'secret'

  desc 'Demonstrate logged in users can see the products'
  get '/products'

  desc 'Demonstrate logged in users can see the users'
  get '/users', screenshot: { 
    filename: "r_3_user_list.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "/login?name=dave&password=secret",
      "GET:/users"
    ]
  }

  desc 'Show that the tests fail (good!)'
  test

  publish_code_snapshot :r

  edit "app/models/user.rb" do |data|
    msub /^()end/, "\n" + <<-EOF.unindent(4)
      #START:after_destroy
      after_destroy :ensure_an_admin_remains

      class Error < StandardError
      end

      private
        def ensure_an_admin_remains
          if User.count.zero?
            raise Error.new "Can't delete last user"
          end
        end     
      #END:after_destroy
    EOF
  end

  edit "app/controllers/users_controller.rb" do
    dcl 'destroy', mark: 'delete_user' do
      if self =~ /, notice/
        msub /redirect_to users_url,( )notice:/, "\n" + (' ' * 8)
        msub /notice: ['"](.*)['"]/, '"User #{@user.name} deleted"'
      else
        msub /@user.destroy()/, "\n    " + 
          'flash[:notice] = "User #{@user.name} deleted"'
      end

      self << "\n" + <<-EOF.unindent(6)
        #START_HIGHLIGHT
        rescue_from 'User::Error' do |exception|
          redirect_to users_url, notice: exception.message
        end
        #END_HIGHLIGHT
      EOF
    end
  end
end

section 15.5, 'Playtime' do
  desc 'Verify that accessing product information requires login'
  edit 'test/*/products_controller_test.rb', 'logout' do
    clear_all_marks
    msub /^()end/, "\n"
    if $rails_version =~ /^[34]/
      msub /^()end/, <<-EOF.unindent(6), :mark => 'logout'
        test "should require login" do
          logout
          get :index
          assert_redirected_to login_path
        end
      EOF
    else
      msub /^()end/, <<-EOF.unindent(6), :mark => 'logout'
        test "should require login" do
          logout
          get products_url
          follow_redirect!
          assert_select 'h2', 'Please Log In'
        end
      EOF
    end
  end

  desc 'Verify  that the test passes'
  test :controllers

  desc 'Look at the data in the database'
  if $rails_version =~ /^[34]/
    cmd 'sqlite3 db/development.sqlite3 .schema'
  else
    cmd 'echo .schema | rails dbconsole'
  end

  desc 'Try requesting the xml... see auth failure.'
  cmd "curl --max-time 15 --silent http://localhost:#$PORT/products/2/who_bought.xml"

  # issue 'Is this the best way to detect request format?'
  desc 'Enable basic auth'
  edit 'app/controllers/application_controller.rb', 'auth' do
    clear_highlights
    dcl 'authorize', :mark => 'auth' do
      gsub! /^      /, '        '
      msub /def authorize\n()/, <<-EOF.unindent(2), :highlight
        if request.format == Mime[:html]
      EOF
      msub /\n()    end/, <<-EOF.unindent(2), :highlight
        else
          authenticate_or_request_with_http_basic do |username, password|
            user = User.find_by_name(username)
            user && user.authenticate(password)
          end
        end
      EOF
      gsub! 'by_name(', 'by(name: ' unless $rails_version =~ /^3/
      if File.exist? 'public/images'
        msub /user = (.*\n.*)/, 'User.authenticate(username, password)'
      end
    end
    sub! 'Mime[:html]', 'Mime::HTML' if $rails_version =~ /^[34]/
  end

  desc 'Try requesting the xml... see auth succeed.'
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products/2/who_bought.xml"
end

section 16.1, 'Task K1: Selecting the locale' do
  desc 'Define the default and available languages.'
  FileUtils.mkdir_p "depot/config/initializers"
  FileUtils.touch "depot/config/initializers/i18n.rb"
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
    if $rails_version =~ /^4\./
      nonadmin = data.slice! /^\s*resources.*?root.*?\n/m
      nonadmin[/^ +get/] = "  post 'store/index'\n  get"
    else
      nonadmin = data.slice! /^\s*resources.*?\n +end\n/m
      nonadmin.gsub! /.*get ['"]store\/index.*\n/, ''
    end
    nonadmin.extend Gorp::StringEditingFunctions
    nonadmin.gsub! /^/, '  '
    nonadmin.msub /()\s*resource/, "  scope '(:locale)' do\n", :highlight
    nonadmin.msub /root.*\n()/, "  end\n", :highlight
    nonadmin.msub /root.*()/, ', via: :all' unless $rails_version =~ /^3\./ 

    admin =  nonadmin.slice! /^\s*resources :users\n/
    admin += nonadmin.slice! /^\s*resources :products do\n.*?end\n/m
    admin.gsub! /^  /, ''

    # append to end
    data.msub /^()end/, "\n" + admin + "\n" + nonadmin
  end

  unless $rails_version =~ /^3\./
    desc 'inspect the results'
    get '/rails/info/routes', screenshot: { filename: "s_1_routes.pdf", dimensions: [ 1024, 800 ], }
  end

  desc "Default locale parameter, and set locale based on locale parameter."
  edit "app/controllers/application_controller.rb", 'i18n' do |data|
    data.clear_all_marks

    data.dcl 'ApplicationController', :mark => 'i18n'

    data.msub /^class.*\n()/, <<-EOF.unindent(4)
      #START_HIGHLIGHT
      before_action :set_i18n_locale_from_params
      #END_HIGHLIGHT
      # ...
      #END:i18n
    EOF
    data.gsub! '_action', '_filter' if $rails_version =~ /^3\./

    data.edit 'protected', :mark => 'i18n'

    data.msub /^()end\n/, "\n" + <<-'EOF'.unindent(2)
      #START:i18n
      #START_HIGHLIGHT
      def set_i18n_locale_from_params
        if params[:locale]
          if I18n.available_locales.map(&:to_s).include?(params[:locale])
            I18n.locale = params[:locale]
          else
            flash.now[:notice] = 
              "#{params[:locale]} translation not available"
            logger.error flash.now[:notice]
          end
        end
      end
      #END_HIGHLIGHT
    EOF

    if $rails_version =~ /^[34]/
      data.msub /^() +def set_i18n_locale/, <<-'EOF'.unindent(4) + "\n"
        def default_url_options
          { :locale => I18n.locale }
        end
      EOF
    end

    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Verify that the routes work."
  get '/en', screenshot: { filename: "s_2_en.pdf", dimensions: [ 1024, 800 ], }
  get '/es', screenshot: { filename: "s_3_es_error.pdf", dimensions: [ 1024, 800 ], }
end

section 16.2, 'Task K2: translating the store front' do
  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/layouts/application.html.erb' do
    clear_highlights
    gsub! '"Pragmatic Bookshelf"', "t('.title')"
    gsub! 'Home', "<%= t('.home') %>"
    gsub! 'Questions', "<%= t('.questions') %>"
    gsub! 'News', "<%= t('.news') %>"
    gsub! 'Contact', "<%= t('.contact') %>"
    gsub! /(.*t\('\..*'\))/, "<!-- START_HIGHLIGHT -->\n\\1"
    gsub! /(t\('\..*'\).*)/, "\\1\n<!-- END_HIGHLIGHT -->"
  end

  desc 'Replace translatable text with calls out to translation functions.'
  cmd "cp -r #{$DATA}/i18n/*.yml config/locales"

  desc 'Define some translations for the layout.'
  edit('config/locales/en.yml', 'layout') {}
  edit('config/locales/es.yml', 'layout') {}

  desc 'Server needs to be restarted when introducting a new language'
  restart_server

  desc 'See results'
  get '/es', screenshot: { filename: "s_4_es_works.pdf", dimensions: [ 1024, 800 ], }

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/store/index.html.erb' do
    clear_highlights
    edit '<h1>', :highlight do
      gsub! 'Your Pragmatic Catalog', "<%= t('.title_html') %>"
    end
    edit 'button_to' do
      gsub! "'Add to Cart'", "t('.add_html')"
      gsub! /\A/, "<!-- START_HIGHLIGHT -->\n"
      gsub! /\Z/, "\n# END_HIGHLIGHT"
    end
  end

  desc 'Define some translations for the main page.'
  edit('config/locales/en.yml', 'main') {}
  edit('config/locales/es.yml', 'main') {} 

  desc 'See results'
  get '/es', screenshot: { filename: "s_5_more_es.pdf", dimensions: [ 1024, 800 ], }

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/views/carts/_cart.html.erb' do
    clear_highlights

    gsub! 'Your Cart', "<%= t('.title') %>"
    sub! /(t\('\..*'\).*)/, "\\1\n<!-- END_HIGHLIGHT -->"

    gsub! "'Checkout'", "t('.checkout')"
    msub /new_order_path(,)/, "(locale: I18n.locale),\n   "
    sub! /(I18n.locale.*)/, "\\1\n# END_HIGHLIGHT"

    gsub! "'Empty cart'", "t('.empty')"
    gsub! /(t\('\.empty'\).*)/, "\\1\n# END_HIGHLIGHT"

    gsub! /(.*t\('\..*'\))/, "<!-- START_HIGHLIGHT -->\n\\1"
  end

  desc 'Define some translations for the cart.'
  edit('config/locales/en.yml', 'cart') {}
  edit('config/locales/es.yml', 'cart') {} 
  
  publish_code_snapshot :s

  desc 'Handle remote calls too'
  edit 'app/views/store/index.html.erb', 'price_line' do
    clear_all_marks
    edit /^\s+<div class="price">.*?<\/div>\n/m, :mark => 'price_line'
    msub /,( )line_items_path/, "\n            "
    msub /line_items_path\(.*?()\)/, ", locale: I18n.locale"
    edit 'line_items_path', :highlight
  end

  desc 'Format the currency.'
  edit('config/locales/es.yml', 'currency') {} 

  desc 'Add to Cart'
  post '/es', 'product_id' => 2
  get '/es', screenshot: {
    filename: "t_1_cart_translated.pdf",
    dimensions: [ 1024, 800 ],
    workflow: [
      "line_items?product_id=2",
    ]
  }
end

section 16.3, 'Task K3: Translating Checkout' do
  desc 'Edit the new order page'
  edit 'app/views/orders/new.html.erb' do
    clear_highlights
    edit 'Please Enter Your Details', :highlight
    gsub! 'Please Enter Your Details', "<%= t('.legend') %>"
  end

  desc 'Edit the form used by the new order page'
  edit 'app/views/orders/_form.html.erb' do
    clear_highlights
    edit "'Place Order'", :highlight do
      gsub! "'Place Order'", "t('.submit')"
    end

    if $rails_version =~ /^[34]|^5\.0/
      edit "'Select a payment method'" do
        gsub! "'Select a payment method'", "t('.pay_prompt_html')"
        msub /()$/, "\n<!-- END_HIGHLIGHT -->"
        msub /^()/, "#START_HIGHLIGHT\n"
      end
    end

    edit ':name', :highlight do
      msub /() %>/, ", t('.name')"
    end
    edit ':address', :highlight do
      msub /() %>/, ", t('.address_html')"
    end

    if $rails_version =~ /^[34]|^5\.0/
      edit ':pay_type', :highlight do
        msub /() %>/, ", t('.pay_type')"
      end
    end

    edit ':email', :highlight do
      msub /() %>/, ", t('.email')"
    end
  end

  desc 'Install i18n-js'
  edit 'Gemfile', 'i18n-js' do
    self << "# START: i18n-js\n"
    self << "gem 'i18n-js'\n"
    self << "# END: i18n-js\n"
  end
  bundle 'install'
  edit "config/application.rb" do
    clear_all_marks
    clear_highlights
    msub /^()  end/, %{
    # START:i18n-js
    config.middleware.use I18n::JS::Middleware
    # END:i18n-js
}
  end

  restart_server

  if $rails_version =~ /^[345]/
    edit 'app/assets/javascripts/application.js' do
      clear_highlights
      msub /^()\/\/= require_tree ./, %{
// START:i18n-js
//= require i18n
//= require i18n/translations
// END:i18n-js
}
    end
  else
    edit 'app/javascript/packs/application.js' do
      self << "\n\n" + <<-EOF
// START:i18n-js
window.I18n = require("../../../public/javascripts/i18n")
require("../../../public/javascripts/translations")
// END:i18n-js
EOF
    end
  end

  edit "app/views/layouts/application.html.erb" do
    msub /()<%= javascript_(include|pack)_tag 'application'/, %{
    <!-- START:i18n-js -->
    }
    msub /()\s+<\/head>/,%{
    <!-- START_HIGHLIGHT -->
    <script type="text/javascript">
      I18n.defaultLocale = "<%= I18n.default_locale %>";
      I18n.locale        = "<%= I18n.locale %>";
    </script>
    <!-- END_HIGHLIGHT -->
    <!-- END:i18n-js -->

}

  end
  edit "app/javascript/PayTypeSelector/index.jsx" do
    clear_highlights
    gsub!  '          <label htmlFor="order_pay_type">Pay type</label>', <<EOF
          <label htmlFor="order_pay_type">
            {I18n.t("orders.form.pay_type")}
          </label>
EOF
    gsub! '            <option value="">Select a payment method</option>', <<EOF
            <option value="">
              {I18n.t("orders.form.pay_prompt_html")}
            </option>
EOF
    gsub! '            <option value="Check">Check</option>', <<EOF
            <option value="Check">
              {I18n.t("orders.form.pay_types.check")}
            </option>
EOF
    gsub! '            <option value="Credit card">Credit card</option>', <<EOF
            <option value="Credit card">
              {I18n.t("orders.form.pay_types.credit_card")}
            </option>
EOF
    gsub! '            <option value="Purchase order">Purchase order</option>', <<EOF
            <option value="Purchase order">
              {I18n.t("orders.form.pay_types.purchase_order")}
            </option>
EOF
  end
  edit "app/javascript/PayTypeSelector/CheckPayType.jsx" do
    gsub! '          <label htmlFor="order_routing_number">Routing #</label>', <<EOF
          <label htmlFor="order_routing_number">
            {I18n.t("orders.form.check_pay_type.routing_number")}
          </label>
EOF
    gsub! '          <label htmlFor="order_account_number">Account #</label>', <<EOF
          <label htmlFor="order_acount_number">
            {I18n.t("orders.form.check_pay_type.account_number")}
          </label>
EOF
  end
  edit "app/javascript/PayTypeSelector/CreditCardPayType.jsx" do
    gsub! '          <label htmlFor="order_credit_card_number">CC #</label>', <<EOF
          <label htmlFor="order_credit_card_number">
            {I18n.t("orders.form.credit_card_pay_type.cc_number")}
          </label>
EOF
    gsub! '          <label htmlFor="order_expiration_date">Expiry</label>', <<EOF
          <label htmlFor="order_expiration_date">
            {I18n.t("orders.form.credit_card_pay_type.expiration_date")}
          </label>
EOF
  end
  edit "app/javascript/PayTypeSelector/PurchaseOrderPayType.jsx" do
    gsub! '          <label htmlFor="order_po_number">PO #</label>', <<EOF
          <label htmlFor="order_po_number">
            {I18n.t("orders.form.purchase_order_pay_type.po_number")}
          </label>
EOF
  end

  desc 'Define some translations for the new order.'
  edit('config/locales/en.yml', 'checkout') {}
  edit('config/locales/es.yml', 'checkout') {}


  publish_code_snapshot :t

  cmd 'bin/webpack' if $rails_version =~ /^5\.1/
  restart_server

  desc 'Add to cart'
  post '/es', 'product_id' => 2
  get '/es', screenshot: {
    filename: "u_1_checkout_translated.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "/es/orders/new",
    ]
  }

  desc 'Show mixed validation errors'
  post '/es/orders/new', 'order[name]' => '', 'submit' => 'Realizar Pedido'

  desc 'Translate the errors to human names.'
  edit('config/locales/es.yml', 'errors') {} 

  desc 'Display messages in raw form, and translate error messages'
  edit 'app/views/orders/_form.html.erb' do
    edit "<%= #{include?('msg') ? 'msg' : 'message'} %>", :highlight do
      msub /<%=() /, 'raw'
    end

    msub /\A()/, "<!-- START:explanation -->\n"
    msub /<h2>(.*)<\/h2>/m,  ''
    edit '<h2>', :highlight
    msub /(<h2><\/h2>)/, 
      "<h2><%=raw t('errors.template.header', :count=>@order.errors.count,\n" +
      "        :model=>t('activerecord.models.order')) %>.</h2>\n" +
      "      <p><%= t('errors.template.body') %></p>"
    msub /^  <% end %>\n()/, <<-EOF.unindent(6)
      <!-- ... -->
      <!-- END:explanation -->
    EOF
    gsub! /:(\w+)=>/, '\1: \2' unless RUBY_VERSION =~ /^1\.8/ # add a space
  end

  cmd 'bin/webpack' if $rails_version =~ /^5\.1/
  restart_server

  get '/es', screenshot: {
    filename: "u_3_checkout_errors_better.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "/es/orders/new",
      "/orders",
    ]
  }

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

  if RUBY_VERSION =~ /^1\.8/ and $rails_version =~ /^3\.2/
    desc 'Intermittent cache reloading issue'
    restart_server
  end

  cmd 'bin/webpack' if $rails_version =~ /^5\.1/
  restart_server

  get '/es', screenshot: {
    filename: "u_4_checkout_errors_fixed.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=3",
      "es/orders/new",
      "/orders",
    ]
  }
  desc 'Show validation errors'
  post '/es/orders/new', 'order[name]' => '', 'submit' => 'Realizar Pedido'

  desc 'Replace translatable text with calls out to translation functions.'
  edit 'app/controllers/orders_controller.rb', 'create' do
    clear_highlights
    dcl 'create', :mark => 'create' do
      edit "store_index_url", :highlight
      msub /store_index_url()/, '(locale: I18n.locale)'

      edit  "'Thank you for your order.'", :highlight
      gsub! "'Thank you for your order.'", "I18n.t('.thanks')"

      gsub! ' notice:', ''
      msub /()I18n.t/, 'notice: '
    end
  end

  desc 'Modify the test to reflect the new redirect'
  edit 'test/*/orders_controller_test.rb', 'valid' do
    clear_all_marks
    dcl 'should create order', :mark => 'valid' do
      edit "store_index_", :highlight do
        msub /store_index_\w+()/, "(locale: 'en')"
      end
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

  cmd 'bin/webpack' if $rails_version =~ /^5\.1/
  restart_server

  get '/es', screenshot: {
    filename: "u_5_gracias.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "orders/new",
      "/orders?order[name]=Pat&order[address]=123+Main+St&order[email]=pat@example.com&order[pay_type]=Check",
    ]
  }

  edit "config/locales/es.yml" do
    msub /^  (activerecord:)/,"xactiverecord:"
  end
  get '/es', screenshot: {
    filename: "u_2_checkout_errors.pdf",
    dimensions: [ 1024, 300 ],
    workflow: [
      "line_items?product_id=2",
      "orders/new",
      "/orders",
    ]
  }
  edit "config/locales/es.yml" do
    msub /^  (xactiverecord:)/,"activerecord:"
  end
end

section 16.4, 'Task K4: Add a locale switcher.' do
  desc 'Add form for setting and showing the site based on the locale.'
  desc 'Use CSS to position the form.'
  edit DEPOT_CSS, 'i18n' do |data|
    data << "\n" + <<-EOF.unindent(6)
      /* START:i18n */
      .locale {
        float: right;
        margin: 1em;
      }
      /* END:i18n */
    EOF
  end

  desc "When provided, save the locale in the session."
  edit "app/controllers/store_controller.rb", 'index' do
    dcl 'index', :mark => 'index' do
      clear_highlights
      gsub! /^    /,'      '
      msub /def.*\n()/, <<-EOF.unindent(4), :highlight
        if params[:set_locale]
          redirect_to store_index_url(:locale => params[:set_locale])
        else
      EOF
      msub /^()\s+end/, <<-EOF.unindent(4), :highlight
        end
      EOF
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
  end

  desc "Create the CS for hiding the button"
  if $rails_version =~ /^[345]/
     edit "app/assets/javascripts/locale_switcher.coffee" do |data|
       data.all = %{document.addEventListener 'turbolinks:load', ->
  document.getElementById('submit_locale_change').style.display='none'}
     end
   else
     edit "app/javascript/packs/locale_switcher.js" do |data|
       data.all = %{document.addEventListener('turbolinks:load', () =>
  document.getElementById('submit_locale_change').style.display='none')}
     end
  end

  edit 'app/views/layouts/application.html.erb', 'i18n' do
    clear_highlights
    edit /^\s+<header class="main">.*?<\/header>\n/m, :mark => 'i18n'
    msub /\n()\s+<%= image_tag/, <<-EOF, :highlight
      <aside>
        <%= form_tag store_index_path, :class => 'locale' do %>
          <%= select_tag 'set_locale', 
            options_for_select(LANGUAGES, I18n.locale.to_s),
            :onchange => 'this.form.submit()' %>
          <%= submit_tag 'submit', id: "submit_locale_change" %>
        <% end %>
      </aside>
    EOF
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end

  desc "Try out the form"
  post '/en', 'set_locale' => 'es'
  get '/es', screenshot: {
    filename: "u_6_locale_switcher.pdf",
    dimensions: [ 1024, 300 ]
  }
  test
end

section 17.1, "Receiving Support Emails with Action Mailbox" do
  desc 'install action mailbox'
  cmd 'bin/rails action_mailbox:install'

  desc 'add migrations it created'
  db :migrate

  desc 'Configure active storage'
  edit 'config/environments/development.rb' do
    msub /(^end)/, "\n#START:active-storage\n#START_HIGHLIGHT\n  config.active_storage.service = :local\n#END_HIGHLIGHT\nend\n#END:active-storage"
  end
  edit 'config/environments/test.rb' do
    msub /(^end)/, "\n#START:active-storage\n#START_HIGHLIGHT\n  config.active_storage.service = :test\n#END_HIGHLIGHT\nend\n#END:active-storage"
  end
  edit 'config/storage.yml' do
    self.all = read('config/storage.yml')
  end

  edit 'app/mailboxes/application_mailbox.rb' do
    msub /^()end/,"\n#START_HIGHLIGHT\n  routing \"support@example.com\" => :support\n#END_HIGHLIGHT\n"
  end

  cmd 'bin/rails g mailbox support'

  edit 'app/mailboxes/support_mailbox.rb' do
    msub /def process()/,%{
    # START_HIGHLIGHT
    puts "From : #\{mail.from_address\}"
    puts "Subject: #\{mail.subject\}"
    puts "Body : #\{mail.body\}"
    puts "END SupportMailbox#process:"
    # END_HIGHLIGHT}
  end

  publish_code_snapshot :ta
end

section 17.2, "Storing Support Requests from Our Mailbox" do

  desc "Generate the SupportRequest model"
  cmd "bin/rails g model support_request"

  desc "Create SupportRequest migration"
  edit Dir['db/migrate/*create_support_requests.rb'].first do
    msub /create_table :support_requests do \|t\|(.*)t.timestamps/m,%{
    # START_HIGHLIGHT
      t.string :email, comment: "Email of the submitter"
      t.string :subject, comment: "Subject of their support email"
      t.text :body, comment: "Body of their support email"
      t.references :order, 
                    foreign_key: true,
                    comment: "their most recent order, if applicable"
    # END_HIGHLIGHT
      }
  end
  db :migrate

  desc "Add association to SupportRequest"
  edit "app/models/support_request.rb" do
    msub /^()end/,%{
  #START_HIGHLIGHT
  belongs_to :order, optional: true
  #END_HIGHLIGHT
}
  end

  desc "Implement support mailbox for real"
  edit 'app/mailboxes/support_mailbox.rb' do
    msub /def process(.*  end)/m,%{
    # START_HIGHLIGHT
    recent_order = Order.where(email: mail.from_address.to_s).
                         order('created_at desc').
                         first
    SupportRequest.create!(
      email: mail.from_address.to_s,
      subject: mail.subject,
      body: mail.body.to_s,
      order: recent_order
    )
    # END_HIGHLIGHT
  end}
  end

  restart_server

  # Note - this file does not always get generated
  #        since the bundle running `depot` requires rspec
  #        and this bleeds into Rails creating rspec files
  desc "Add a test for our mailbox"
  cmd "mkdir -p test/mailboxes"
  cmd "touch test/mailboxes/support_mailbox_test.rb"
  edit 'test/mailboxes/support_mailbox_test.rb' do
    self.all = read('test/support_mailbox_test.rb')
  end

  desc "Add some more order test fixtres"
  edit "test/fixtures/orders.yml" do
    clear_highlights
    msub /()two:/,%{
#START_HIGHLIGHT
another_one:
  name: Dave Thomas
  address: 123 Any St
  email: dave@example.org
  pay_type: Check
  created_at: <%= 2.days.ago %>

other_customer:
  name: Chris Jones
  address: 456 Somewhere Ln
  email: chris@nowhere.net
  pay_type: Check
#END_HIGHLIGHT
}
  end

  desc "Run the tests"
  cmd "bin/rails test test/mailboxes/support_mailbox_test.rb"
end

section 17.3, "Responding with Rich Text" do

  edit "config/routes.rb" do
    clear_highlights
    msub /()  resources :users/,%{
  # START_HIGLIGHT
  resources :support_requests, only: [ :index, :update ]
  # END_HIGLIGHT
}
  end

  desc "Create support request controller"
  edit "app/controllers/support_requests_controller.rb" do
    self.all = %{# START:index
# START_HIGHLIGHT
class SupportRequestsController < ApplicationController
  def index
    @support_requests = SupportRequest.all
  end

# END:index
  def update
  end
# START:index
end
# END_HIGHLIGHT
# END:index
}
  end

  cmd "mkdir app/views/support_requests"

  desc "Create support request view"
  edit "app/views/support_requests/index.html.erb" do
    self.all = read("views/support_requests_index.html.erb")
  end

  restart_server
  publish_code_snapshot :tb

  desc "add rich text response to support request"
  edit "app/models/support_request.rb" do
    clear_highlights
    msub /()end/,%{
    has_rich_text :response
}
  end

  desc "install action text"
  cmd "bin/rails action_text:install"

  desc "Run webpack"
  cmd "bin/webpack"

  desc "migrate action text tables"
  db :migrate

  desc "add edit form to support request view"
  edit "app/views/support_requests/index.html.erb" do
    clear_highlights
    msub /^      #{Regexp.escape("<% end %>")}()/,%{
      <!-- START_HIGHLIGHT -->
      <% if support_request.response.blank? %>
        <%= form_with(model: support_request,
                      local: true,
                      class: "depot_form") do |form| %>
          <div class="field">
            <%= form.label :response, "Write Response" %>
            <%= form.rich_text_area :response, id: :support_request_response %>
          </div>
          <div class="actions">
            <%= form.submit "Send Response" %>
          </div>
        <% end %>
      <% else %>
        <h4>Our response:</h4>
        <p>
          <blockquote>
            <%= support_request.response %>
          </blockquote>
        </p>
      <% end %>
     <!-- END_HIGHLIGHT -->
}
  end

  desc "Add update method to controller" do
    clear_highlights
    self.all = %{# START:update
class SupportRequestsController < ApplicationController
  def index
    @support_requests = SupportRequest.all
  end

# START_HIGHLIGHT
  def update
    support_request = SupportRequest.find(params[:id])
    support_request.update(response: params.require(:support_request)[:response])
# END:update
    SupportRequestMailer.respond(support_request).deliver_now
# START:update
    redirect_to support_requests_path
  end
# END_HIGHLIGHT
end
# END:update
}
  end

  restart_server

  desc "Generate mailer"
  cmd "bin/rails g mailer support_request respond"

  edit "app/mailers/support_request_mailer.rb" do
    msub /(def respond.*  end)/m,%{
  # START_HIGHLIGHT
  default from: "support@example.com"

  def respond(support_request)
    @support_request = support_request
    mail to: @support_request.email, subject: "Re: #\{@support_request.subject\}"
  end
  # END_HIGHLIGHT
}
  end

  desc "Create HTML view"
  edit "app/views/support_request_mailer/respond.html.erb" do
    self.all = %{
<%= @support_request.response %>
<hr>
<blockquote>
  <%= @support_request.body %>
</blockquote>
}
  end

  desc "Create Text view"
  edit "app/views/support_request_mailer/respond.text.erb" do
    self.all = %{
<%= @support_request.response.to_plain_text %>

---

<%= @support_request.body %>
}
  end
end

if $rails_version =~ /^[345]/
  if false
section 17, 'Deployment' do
  Dir.chdir(File.join($WORK, 'depot'))

  if Gorp::Config[:mysql_null_primary_key]
    # https://github.com/rails/rails/pull/13247#issuecomment-158787912
    warn 'avoid primary key columns with NULL values'
    edit 'config/initializers/abstract_mysql2_adapter.rb' do
      self.all = <<-EOF.unindent(8)
        require 'active_record/connection_adapters/mysql2_adapter.rb'
        class ActiveRecord::ConnectionAdapters::Mysql2Adapter  
          NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY" 
        end
      EOF
    end
  end

  cmd 'git add .'
  cmd 'git commit -a -m "save work"'
  edit 'config/database.yml' do
    # edit 'production.sqlite3', :highlight
    # msub %r((db)/production.sqlite3), '../../shared/db'
    msub /^(production:.*)/m, <<-EOF.unindent(6), :mark => 'production'
      production:
        adapter: mysql2
        encoding: utf8
        reconnect: false
        database: depot_production
        pool: 5
        username: username
        password: password
        host: localhost
    EOF
    sub! 'mysql2', 'mysql' if $rails_version =~ /^3\.0/
    # msub /adapter: (.*)/, 'postgresql'
    # msub /encoding: (.*)/, 'unicode'
    # msub /(reconnect: .*)/, 'host: localhost'
  end

  edit 'Gemfile', 'mysql' do
    mysql_version = if
                      $rails_version =~ /^3\.[12]/ ||
                      $rails_version =~ /^4\.0/ ||
                      $rails_version =~ /^4\.1/ ||
                      $rails_version =~ /^4\.2\.[01234]/
                    then
                      "~> 0.3.10"
                    else
                      "~> 0.4.0"
                    end

    clear_all_marks
    msub /'sqlite.*\n()/, <<-EOF.unindent(6), :mark => 'mysql'
      group :production do
        gem 'mysql2', '#{mysql_version}'
      end
    EOF

    sub! 'mysql2', 'mysql' if $rails_version =~ /^3\.0/

    if self =~ /^# Turbolinks.*\.( )Read more:/
      msub /^# Turbolinks.*\.( )Read more:/, "\n# "
    end
  end

  edit 'Gemfile', 'capistrano' do
    edit /#.*\n# gem .capistrano.*/, :mark => 'capistrano' do
      edit 'gem', :highlight
      msub /^(# )gem .capistrano/, ''
      sub!(/^gem .capistrano-rails.*\n/) do |line| 
        "#{line}" +
        "#{line.sub('-rails', '-rvm')}" +
        "#{line.sub('-rails', '-bundler')}" +
        "#{line.sub('-rails', '-passenger')}"
      end
    end
  end
  bundle 'install'

  #
  # mysql -u root
  # > GRANT ALL PRIVILEGES ON depot_production.*
  #   TO 'username'@'localhost' IDENTIFIED BY 'password';
  #

  # cmd 'mysqladmin -f -u root drop depot_production 2>&1'
  # ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
  rake 'db:setup RAILS_ENV=production'
  unbundle { cmd 'echo no | bundle exec cap install STAGES=production' }

  edit 'config/deploy.rb' do
    self.all = read('config/deploy.rb')
    msub /user\s*=\s*'(\w+)'/, ENV['USER'] || 'rubys'

    msub /set :rvm_ruby_string, '((ruby-)?\d+\.\d+\.\d+)'/,
      ENV['RUBY_VERSION'] ||
      ("ruby-#{ENV['RBENV_VERSION']}" if ENV['RBENV_VERSION']) ||
      RUBY_VERSION
  end

  edit 'lib/capistrano/tasks/deploy-seed.rake' do
    self.all = read('config/deploy-seed.rake')
  end

  if File.exist? 'public/images'
    edit 'config/environments/production.rb' do
      msub /^()end/, "\n" + <<-EOF.unindent(6)
        require 'active_support/core_ext/numeric/bytes'
        config.logger = Logger.new(paths.log.first, 2, 10.megabytes)
      EOF
    end
    console "Depot::Application.configure { paths.log.first }", 'production'
  else
    edit 'Capfile' do
      %w(rails/assets rvm bundler rails/migrations passenger).each do |option|
        edit /^\s*# require ['"]capistrano\/#{option}.*\n/, :highlight do 
          msub /^(\s*# )require/, ''
        end
      end
    end
#   rake 'assets:precompile'
#   cmd 'ls public/assets'
#
    edit 'config/environments/production.rb' do
      msub /^()end/, "\n" + <<-EOF.unindent(6)
        require 'active_support/core_ext/numeric/bytes'
        config.logger = Logger.new(paths['log'].first, 2, 10.megabytes)
      EOF
    end
    console "Depot::Application.configure { paths['log'].first }", 'production'
  end
  cmd 'git status'
end
  end
end

section 18, 'Retrospective' do
  readme = Dir['doc/README*', 'README*'].first
  edit readme do
    self.all = read('README_FOR_APP')
  end
  rake 'doc:app'
  rake 'stats'
end

section 19, 'Finding Your Way Around' do
  db :version
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
  db :schema_migrations
  cmd 'ls log'
  cmd 'find script -type f'
  console 'puts $:'
end

section 20, 'Active Record' do
  edit 'config/initializers/inflections.rb' do
    self << "\n" + <<-EOF.unindent(6)
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular 'tax', 'taxes'
      end
    EOF
  end
end

if $rails_version =~ /^3\./
  section 21.1, 'Testing Routes' do
    edit 'test/unit/routing_test.rb' do
      self.all = read('test/routing_test.rb')
      gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
    end
    test :units
  end
end

section 22.1, 'Views' do
  edit 'app/views/products/index.xml.builder' do
    self.all = read('products/index.xml.builder')
    gsub! /:(\w+) (\s*)=>/, '\1:\2' unless RUBY_VERSION =~ /^1\.8/
  end
  edit 'app/controllers/products_controller.rb', 'index' do
    dcl 'index', :mark => 'index' do
      if self =~ /format\.xml/
        msub /format.xml(.*)/, '  # index.xml.builder'
      elsif self =~ /format\.html/
        msub /format.html.*\n()/, "      format.xml\n"
      else
        msub /^()  end/, <<-EOF.unindent(6)
          respond_to do |format|
            format.html
            format.xml
          end
        EOF
      end
    end
  end
  cmd "curl --max-time 15 --silent --user dave:secret http://localhost:#$PORT/products.xml"
  edit('Gemfile') {self << "gem 'irb', require: false\n"}
  cmd 'bundle install --local'
  if $rails_version =~ /^3\./
    irb 'helpers/date3.rb'
  else
    irb 'helpers/date4.rb'
  end
  irb 'helpers/number.rb'
  edit('Gemfile') {gsub! /.*'irb'.*\n/, ''}
  cmd 'bundle install --local'
  publish_code_snapshot :u
end

section 22.2, 'Form Helpers' do
  rails 'views'
  generate 'model model input:string address:text color:string ' +
    'ketchup:boolean mustard:boolean mayonnaise:boolean start:date ' +
    'alarm:time'
  generate 'controller Form input'
  db :migrate
  restart_server

  edit 'app/views/form/input.html.erb' do
    self.all = read('form/input.html.erb')
  end
  get '/form/input'

  publish_code_snapshot nil, :views
end


section 25.1, 'RSpec' do
  Dir.chdir(File.join($WORK, 'depot'))

  edit 'Gemfile', 'rspec' do
    msub /()group :development, :test do/, %{
# START:rspec-rails
}
    msub /group :development, :test do()/, %{
# START_HIGHLIGHT
  gem 'rspec-rails'      
# END_HIGHLIGHT
# END:rspec-rails
    }
  end
  bundle 'install'
  generate "rspec:install"
  edit "spec/rails_helper.rb" do
    msub /()RSpec.configure/, %{
# START:fixtures
}
    msub /(config.fixture_path = "\#{::Rails.root}\/spec\/fixtures")/,<<EOF
  # START_HIGHLIGHT
  config.fixture_path = "\#{::Rails.root}/test/fixtures"
  # END_HIGHLIGHT
  # END:fixtures
EOF
  end

  generate "rspec:model Cart"
  edit "spec/models/cart_spec.rb" do
    msub /()require 'rails_helper'/, %{
#START:setup
}
    msub /(pending "add some examples to.*$)/, %{
  #START_HIGHLIGHT
  fixtures :products
  subject(:cart) { Cart.new }

  let(:book_one) { products(:ruby) }
  let(:book_two) { products(:two) }
  #START_HIGHLIGHT
#END:setup

#START:unique
  # START_HIGHLIGHT
  describe "#add_product" do
    context "adding unique products" do
      before do
        cart.add_product(book_one).save!
        cart.add_product(book_two).save!
      end

      it "has two line items" do
        expect(cart.line_items.size).to eq(2)
      end
      it "has a total price of the two items' price" do
        expect(cart.total_price).to eq(book_one.price + book_two.price)
      end
    end
    # END_HIGHLIGHT
#END:unique

#START:dupes
    # START_HIGHLIGHT
    context "adding duplicate products" do
      before do
        cart.add_product(book_one).save!
        cart.add_product(book_one).save!
      end

      it "has one line item" do
        expect(cart.line_items.size).to eq(1)
      end
      it "has a line item with a quantity of 2" do
        expect(cart.line_items.first.quantity).to eq(2)
      end
      it "has a total price of twice the product's price" do
        expect(cart.total_price).to eq(book_one.price * 2)
      end
    end
  # END_HIGHLIGHT
#END:dupes
  end
  }
  msub /^end()/, %{
#END:examples}
  end

  publish_code_snapshot :xa
end

section 25.2, 'Slim' do
  edit 'Gemfile', 'slim' do
    clear_all_marks
    msub /()gem 'webpacker'/, %{
# START:slim
# START_HIGHLIGHT
gem 'slim-rails'
# END_HIGHLIGHT
}
    msub /gem 'webpacker'.*()/, %{
# END:slim
}
  end
  bundle 'install'

  cmd "rm app/views/store/index.html.erb"
  edit "app/views/store/index.slim" do
    self << %{
- if notice
  aside#notice = notice

h1 = t('.title_html')

ul.catalog
  - cache @products do
    - @products.each do |product|
      - cache product do
        li
          = image_tag(product.image_url)
          h2 = product.title
          p = sanitize(product.description)
          .price
            = number_to_currency(product.price)
            = button_to t('.add_html'),
                line_items_path(product_id: product, locale: I18n.locale),
                remote: true
}
  end

  publish_code_snapshot :xb
end

section 25.3, "CSS with Webpack" do
  cmd "mkdir app/javascript/packs/css"
  cmd "mv app/assets/stylesheets/application.scss app/javascript/packs"
  cmd "mv app/assets/stylesheets/*.scss app/javascript/packs/css"
  files = Dir["app/javascript/packs/css/*.scss"].to_a.map { |file|
    basename = File.basename(file)
    "@import \"css/#{basename}\";"
  }.join("\n")
  edit "app/javascript/packs/application.scss" do
    msub /()body/, %{
// START:import
// START_HIGHLIGHT
#{files}
// END_HIGHLIGHT
// END:import
}
  end
  edit "app/views/layouts/application.html.erb" do
    msub /(<%= stylesheet_link_tag.*$)/,""
    msub /(^.*'data-turbolinks-track': .*$)/, %{
    <!-- START:stylesheet_pack_tag -->
    <!-- START_HIGHLIGHT -->
    <%= stylesheet_pack_tag "application" %>
    <!-- END_HIGHLIGHT -->
    <!-- END:stylesheet_pack_tag -->
    }
  end

  cmd "yarn add postcss-cssnext"

  edit ".postcssrc.yml" do
    self << "plugins:\n" unless self.include? 'plugins:'
    self << "  postcss-cssnext: {}\n"
  end

  edit "app/javascript/packs/css/store.scss" do
    msub /().store {/,%{
// START:postcss
}
    msub /(border-top: solid 0.250em;)/, %{
      // START_HIGHLIGHT
    border-top: solid 0.250em gray(50%);
      // END_HIGHLIGHT
}
    msub /()^    li/,%{
    // END:postcss
}
  end
  restart_server
  publish_code_snapshot :xc
end


required = %w(will_paginate nokogiri htmlentities)
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
  configs = %w(mysql_config mysql_config5)
  config = configs.find {|config| not `which #{config}`.empty?}
  socket = `#{config} --socket`.chomp
  if $rails_version =~ /^3\.0/
    require 'mysql'
    dbh = Mysql.real_connect "localhost", "username", "password", nil, 0, socket
    unless dbh.list_dbs.include?('depot_production')
      dbh.query('create database depot_production')
    end
  else
    require 'mysql2'
    client = Mysql2::Client.new host: ENV['MYSQL_HOST'] || 'localhost',
      username: 'username', password: 'password'
    begin
      dbs = client.query('show databases').map {|row| row['Database']}
      unless dbs.include? 'depot_production'
        client.query 'create database depot_production'
      end
    ensure
      client.query 'drop database depot_production'
      client.close
    end
  end
rescue Exception => e
  STDERR.puts "MySQL: #{e}"
end


$cleanup = Proc.new do
  # fetch stylesheets
  if File.exist?(File.join($WORK,'depot/public/stylesheets'))
    Dir[File.join($WORK,'depot/public/stylesheets/*.css')].each do |css|
      File.open(css) {|file| $style.text! file.read}
    end
  else
    begin
      require 'sass'
    rescue LoadError => error
      $style.text! '/* ' + error.to_s + " */\n"
    end

    Dir[File.join($WORK,'depot/app/assets/stylesheets/*.scss')].each do |css|
      text = File.read(css)
      next if text =~ /\A\/\*[^*]*\*\/\s*\Z/ # nothing but a single comment

      if css =~ /\.scss/
        next unless defined? Sass
        text = Sass::Engine.new(text, :syntax => :scss).render
      end

      if text.include? '33px' and not text.include? '8px !important'
        text += "body, body > p, body > ol, body > ul, body > td " + 
          "{margin: 8px !important}"
      end

      $style << text
    end
  end

  if $rails_version =~ /^(3|4\.[01])/
    # Link static files
    system "ln -f -s #{$DATA} #{$WORK}"
  else
    desc "cleanup - precompile assets for inclusion in results"
    if $rails_version =~ /^4/
      cmd "rake assets:precompile"
    else
      cmd "rails assets:precompile"
    end
    system "rm -rf #{$WORK}/data"
    system "cp -rp #{$DATA} #{$WORK}"
    system "cp -rp #{$WORK}/depot/public/assets #{$WORK}/data"
  end
end

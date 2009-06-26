# Micro DSL for declaring an ordered set of book sections
$sections = []
def section number, title, &steps
  $sections << [number, title, steps]
end

section 4, 'Instant Gratification' do
  cmd "erb -r rubygems -r active_support -T - < #{$CODE}/erb/ex1.html.erb |  
       sed 's/<!--.*-->//'"
  cmd "erb -r rubygems -r active_support -T - < #{$CODE}/erb/ex2.html.erb | 
       sed 's/<!--.*-->//'"
  cmd "erb -r rubygems -r active_support -T - < #{$CODE}/erb/ex2a.html.erb | 
       sed 's/<!--.*-->//'"
  cmd "sed 's/-%>\\n/%>/' < #{$CODE}/erb/ex2b.html.erb |  
       erb -r rubygems -r active_support -T - |
       sed 's/<!--.*-->//'"
end

section 6.1, 'Iteration A1: Getting Something Running' do
  rails 'depot', :a
  edit 'config/environments/development.rb' do |data|
    data << "\n\n" + <<-EOF.unindent(6)
      config.logger = Logger.new(config.log_path, 2, 10.kilobytes)
    EOF
  end
end

section 6.2, 'Creating the Products Model and Maintenance Application' do
  cmd 'ls -p'
  cmd 'ruby script/generate scaffold product ' +
    'title:string description:text image_url:string'
  cmd 'rake db:migrate'
  db 'select version from schema_migrations'
  restart_server
  edit 'app/views/products/new.html.erb' do |data|
    data[/ f.text_area :description()/,1] = ', :rows => 6'
  end

  get '/products'
  post '/products/new',
    'product[title]' => 'Pragmatic Version Control',
    'product[description]' => <<-EOF.unindent(6),
      <p>
      This book is a recipe-based approach to
      using Subversion that will get you up
      and running quickly---and correctly. All
      projects need version control: it's a
      foundational piece of any project's
      infrastructure. Yet half of all project
      teams in the U.S.  dont use any version
      control at all. Many others dont use it
      well, and end up experiencing
      time-consuming problems.
      </p>
    EOF
    'product[image_url]' => '/images/svn.jpg'
  get '/products'
  cmd 'sqlite3 db/development.sqlite3 .schema'

  cmd 'rake test'
end

section 6.3, 'Iteration A2: Add a Missing Column' do
  cmd 'ruby script/generate migration add_price_to_product price:decimal'

  cmd 'cat ' + Dir['db/migrate/*add_price_to_product.rb'].first
  edit Dir['db/migrate/*add_price_to_product.rb'].first do |data|
    data[/:decimal()\n/,1] = 
      ",\n      :precision => 8, :scale => 2, :default => 0"
  end

  cmd 'rake db:migrate'
  cmd 'sqlite3 db/development.sqlite3 .schema'

  edit 'app/views/products/index.html.erb' do |data|
    data[/ <th>Image url.*\n()/,1] = <<-EOF.unindent(2)
      <!-- START_HIGHLIGHT -->
      <th>Price</th>
      <!-- END_HIGHLIGHT -->
    EOF
    data[/<td><%=h product.image_url %>.*\n()/,1] = <<-EOF.unindent(2)
      <!-- START_HIGHLIGHT -->
      <td><%=h product.price %></td>
      <!-- END_HIGHLIGHT -->
    EOF
    data[/,() :method => :del/,1] = "\n" + (' ' * 39)
  end

  edit 'app/views/products/new.html.erb' do |data|
    data[/ <%= f.text_field :image_url %>.*\n.*\n+()/,1] =
      <<-EOF.unindent(4) + "\n"
      <!-- START_HIGHLIGHT -->
      <p>
        <%= f.label :price %><br />
        <%= f.text_field :price %>
      </p>
      <!-- END_HIGHLIGHT -->
    EOF
  end

  edit 'app/views/products/edit.html.erb' do |data|
    data[/ <%= f.text_field :image_url %>.*\n.*\n+()/,1] = 
      <<-EOF.unindent(4) + "\n"
      <!-- START_HIGHLIGHT -->
      <p>
        <%= f.label :price %><br />
        <%= f.text_field :price %>
      </p>
      <!-- END_HIGHLIGHT -->
    EOF
  end

  edit 'app/views/products/show.html.erb' do |data|
    data[/ <%=h @product.image_url %>.*\n.*\n+(\n)/,1] =
      <<-EOF.unindent(6) + "\n"
      <!-- START_HIGHLIGHT -->
      <p>
        <b>Price:</b>
        <%=h @product.price %>
      </p>
      <!-- END_HIGHLIGHT -->
    EOF
  end

  get '/products'
  get '/products/1'
  post '/products/new', {}

  cmd 'rake test'

  edit 'app/views/products/show.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/<%=(h) @product.description %>/,1] = ''
    data[/()\s+<%= @product.description %>/,1] = "\n<!-- START_HIGHLIGHT -->"
    data[/<%= @product.description %>()/,1] = "\n<!-- END_HIGHLIGHT -->"
  end
  get '/products/1'
end

section 6.4, 'Iteration A3: Validate!' do

  edit 'app/models/product.rb' do |data|
    data[/class Product.*()/,1] = "\n" + <<-'EOF'.unindent(4)
#START:validation
#START:val1
      validates_presence_of :title, :description, :image_url
#END:val1
#START:val2
      validates_numericality_of :price
#END:val2
#START:val2a
      validate :price_must_be_at_least_a_cent
#END:val2a
#START:val3
      validates_uniqueness_of :title
#END:val3
#START:val4
      validates_format_of :image_url, :allow_blank => true,
                          :with    => %r{\.(gif|jpg|png)$}i,
                          :message => 'must be a URL for GIF, JPG ' +
                                      'or PNG image.'
#END:val4
#START:val2a

    protected
      def price_must_be_at_least_a_cent
        errors.add(:price, 'should be at least 0.01') if price.nil? ||
                           price < 0.00
      end
#END:val2a
#END:validation
    EOF
  end

  post '/products/new',
    'product[price]' => '0.0'

  post '/products/new',
    'product[title]' => 'Pragmatic Unit Testing',
    'product[description]' => <<-EOF.unindent(6),
      A true masterwork.  Comparable to Kafka at
      his funniest, or Marx during his slapstick
      period.  Move over, Tolstoy, there's a new
      funster in town.
    EOF
    'product[image_url]' => '/images/utj.jpg',
    'product[price]' => 'wibble'

  edit 'app/models/product.rb' do |data|
    data[/,( :allow_blank.*)/,1] = ''
    data[/(0.00)/,1] = '0.01'
  end

  edit 'app/views/layouts/products.html.erb', 'head' do |data|
    data[/'scaffold'.*()\n/,1] = ' <!-- <label id="code.scaffold1"/> -->'
  end
end

section 6.5, 'Iteration A4: Making Prettier Listings' do
  # timestamp = Time.now.gmtime.strftime('%Y%m%d%H%M%S')
  edit "db/migrate/003_add_test_data.rb", 'vcc' do |data|
    data[/()/,1] = read('products/003_add_test_data.rb')
  end
  cmd 'rake db:migrate'
  edit 'app/views/layouts/products.html.erb', 'head' do |data|
    data.gsub!(/ <!--.*-->/,'')
    data[/()<!DOCTYPE/,1] = "<!-- START:head -->\n"
    data[/'scaffold'()/,1] = ", 'depot'"
    data[/\n().*'scaffold'.*/,1] = "<!-- START_HIGHLIGHT -->\n"
    data[/'scaffold'.*\n()/,1] = "<!-- END_HIGHLIGHT -->\n"
    data[/()<body>/,1] = "<!-- END:head -->\n"
  end
  edit 'app/views/products/index.html.erb' do |data|
    data[/(.*)/m,1] = read('products/index.html.erb')
  end
  cmd "cp -v #{$DATA}/images/* public/images/"
  cmd "cp -v #{$DATA}/depot.css public/stylesheets"
  get '/products'
end

section 7.1, 'Iteration B1: Create the Catalog Listing' do
  cmd 'ruby script/generate controller store index'
  restart_server
  get '/store'
  edit 'app/controllers/store_controller.rb' do |data|
    data[/def index.*()/,1] = "\n    @products = Product.find_products_for_sale"
  end
  edit 'app/models/product.rb' do |data|
    data[/()class Product/,1] = "#START:salable\n"
    data[/class Product.*()/,1] = "\n" + <<-EOF.unindent(4) + "\n"

      def self.find_products_for_sale
        find(:all, :order => "title")
      end

      # validation stuff...
    #END:salable
    EOF
  end
  edit 'app/views/store/index.html.erb' do |data|
    data[/(.*)/m,1] = read('store/index.html.erb')
  end
  get '/store'
end

section 7.2, 'Iteration B2: Add a Page Layout' do
  edit 'app/views/layouts/store.html.erb' do |data|
    data[/()/,1] = read('store/store.html.erb')
  end
  edit 'public/stylesheets/depot.css', 'mainlayout' do |data|
    data[/().*An entry in the store catalog/,1] = <<-EOF.unindent(6) + "\n"
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
        margin-left: 13em;
        padding-top: 4ex;
        padding-left: 2em;
        background: white;
      }

      #side {
        float: left;
        padding-top: 1em;
        padding-left: 1em;
        padding-bottom: 1em;
        width: 12em;
        background: #141;
      }

      #side a {
        color: #bfb;
        font-size: small;
      }
      /* END:mainlayout */
    EOF
  end
  get '/store'
end

section 7.3, 'Iteration B3: Use a Helper to Format the Price' do
  edit 'app/views/store/index.html.erb' do |data|
    data[/<%= (product.price) %>/m,1] = "number_to_currency(product.price)"
  end
  get '/store'
end

section 7.4, 'Iteration B4: Linking to the Cart' do
  edit 'app/views/store/index.html.erb', 'add_to_cart' do |data|
    data[/number_to_currency.*\n()/,1] =  <<-EOF.unindent(2)
      <!-- START_HIGHLIGHT -->
      <!-- START:add_to_cart -->
      <%= button_to "Add to Cart" %>
      <!-- END:add_to_cart -->
      <!-- END_HIGHLIGHT -->
    EOF
  end

  edit 'public/stylesheets/depot.css', 'inline' do |data|
    data[/().*The error box/,1] = <<-EOF.unindent(6) + "\n"
      /* START:inline */
      #store .entry form, #store .entry form div {
        display: inline;
      }
      /* END:inline */
    EOF
  end
  get '/store'
end

section 8.1, 'Sessions' do
  cmd 'rake db:sessions:create'
  cmd 'rake db:migrate'
  cmd 'sqlite3 db/development.sqlite3 .schema'
  if $R22
    edit 'config/environment.rb' do |data|
      data[/()  config.action_controller.session =/,1] = "  #START:session\n"
      data[/config.action_controller.session =.*?\}()/m,1] = "\n#END:session"
      data[/(# )config.action_controller.session_store/,1] = ''
    end
  else
    edit 'config/initializers/session_store.rb' do |data|
      data[/()# ActionController::Base.session_store =/,1] = "#START:session\n"
      data[/ActionController::Base.session_store =.*()/,1] = "\n#END:session"
      data[/(# )ActionController::Base.session_store/,1] = ''
    end
  end
  restart_server
  edit "app/controllers/#{$APP}.rb" do |data|
    data[/()class ApplicationController.*/,1] = "#START:main\n"
    data[/^end\n()/,1] = "#END:main\n"
    if $R22
      data[/protect_from_forgery (# ):secret/,1] = ''
      data[/().*protect_from_forgery :secret/,1] = "  #START_HIGHLIGHT\n"
      data[/protect_from_forgery :secret.*()/,1] = "\n  #END_HIGHLIGHT"
    end
  end
  edit 'app/controllers/store_controller.rb', 'cart' do |data|
    data[/()^end/,1] = "\n" + <<-EOF.unindent(6) + "\n"
      #START:cart
      private

        def find_cart
          session[:cart] ||= Cart.new
        end
      #END:cart
    EOF
  end
end

section 8.2, 'Iteration C1: Creating a Cart' do
  edit 'app/models/cart.rb' do |data|
    data[/()/,1] = read('cart/cart.rb')
  end
  edit 'app/views/store/index.html.erb', 'add_to_cart' do |data|
    data[/button_to "Add to Cart"()/,1] = 
      ", :action => 'add_to_cart', :id => product"
  end

  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data[/()^#START:cart/,1] = <<-EOF.unindent(4) + "\n"
      #START:add_to_cart
      def add_to_cart
        product = Product.find(params[:id]) # <label id="code.depot.f.find"/>
        @cart = find_cart                   # <label id="code.depot.f.find2"/>
        @cart.add_product(product)          # <label id="code.depot.f.add"/>
      end
      #END:add_to_cart
    EOF
  end
  post '/store/add_to_cart/2', {}
  edit 'app/views/store/add_to_cart.html.erb' do |data|
    data.gsub!(/\s+# <label.*/, '')
    data[/()/,1] = read('cart/add_to_cart.html.erb')
  end
  post '/store/add_to_cart/2', {}
  post '/store/add_to_cart/3', {}
end

section 8.3, 'Iteration C2: Creating a Smarter Cart' do
  edit 'app/models/cart_item.rb' do |data|
    data[/()/,1] = read('cart/cart_item.rb')
  end
  edit 'app/models/cart.rb', 'add_product' do |data|
    data[/()  def add_product\(product\)/,1] = "  #START:add_product\n"
    data[/add_product\(product\)\n.*?  end\n()/m,1] = "  #END:add_product\n"
    data[/add_product\(product\)\n(.*?)  end/m,1] = <<-EOF.unindent(2)
      current_item = @items.find {|item| item.product == product}
      if current_item
        current_item.increment_quantity
      else
        @items << CartItem.new(product)
      end
    EOF
  end
  edit 'app/views/store/add_to_cart.html.erb' do |data|
    data[/<li>(.*?)<\/li>/,1] = 
      '<%= item.quantity %> &times; <%=h item.title %>'
  end
  post '/store/add_to_cart/2', {}
  # cmd 'sqlite3 db/development.sqlite3 ".dump sessions"'
  cmd 'rake db:sessions:clear'
  restart_server unless $R22
  # cmd 'sqlite3 db/development.sqlite3 ".dump sessions"'
  post '/store/add_to_cart/2', {}
  post '/store/add_to_cart/2', {}
  post '/store/add_to_cart/3', {}
  post '/store/add_to_cart/wibble', {}
end

section 8.4, 'Iteration C3: Handling Errors' do
  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data[/def add_to_cart(.*?)  end/m,1] = "\n" + <<-'EOF'.unindent(4)
        product = Product.find(params[:id])
        @cart = find_cart
        @cart.add_product(product)
      rescue ActiveRecord::RecordNotFound
        logger.error("Attempt to access invalid product #{params[:id]}")
        flash[:notice] = "Invalid product"
        redirect_to :action => 'index'
    EOF
  end
  post '/store/add_to_cart/wibble', {}
  cmd 'tail -17 log/development.log', ['Attempt to access']
  edit 'app/views/layouts/store.html.erb' do |data|
    data[/<div id="main">()/,1] = "\n" + <<-'EOF'
      <!-- START_HIGHLIGHT -->
      <!-- START:flash -->
      <% if flash[:notice] -%>
        <div id="notice"><%= flash[:notice] %></div>
      <% end -%>
      <!-- END:flash -->
      <!-- END_HIGHLIGHT -->
    EOF
    data[/(<!-- <label id="code.slt"\/> -->)/,1] = ''
    data[/(<!-- <label id="code.depot.e.title"\/> -->)/,1] = ''
    data[/(<!-- <label id="code.depot.e.include"\/> -->)/,1] = ''
  end
  edit 'public/stylesheets/depot.css', 'notice' do |data|
    data[/Global styles.*()/,1] = "\n\n" + <<-EOF.unindent(6)
      /* START:notice */
      #notice {
        border: 2px solid red;
        padding: 1em;
        margin-bottom: 2em;
        background-color: #f0f0f0;
        font: bold smaller sans-serif;
      }
      /* END:notice */
    EOF
  end
  post '/store/add_to_cart/wibble', {}
end

section 8.5, 'Iteration C4: Finishing the Cart' do
  edit 'app/views/store/add_to_cart.html.erb' do |data|
    data[/.*()/m,1] = "\n" + <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <%= button_to 'Empty cart', :action => 'empty_cart' %>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'empty_cart' do |data|
    data[/()private/,1] = <<-EOF.unindent(4)
      #START:empty_cart
      def empty_cart
        session[:cart] = nil
        flash[:notice] = "Your cart is currently empty"
        redirect_to :action => 'index'
      end
      #END:empty_cart

    EOF
  end
  post '/store/empty_cart', {}
  edit 'app/controllers/store_controller.rb', 'rti' do |data|
    data.gsub!(/flash\[:notice\] = (".*?")\n.*/, 'redirect_to_index(\1)')
    data[/()  #START:add_to_cart/,1] = "  #START:rti\n"
    data[/private\n()/,1] = "\n" + <<-EOF.unindent(4)
      #START:redirect_to_index
      def redirect_to_index(msg)
        flash[:notice] = msg
        redirect_to :action => 'index'
      end
      #END:redirect_to_index
      #END:rti
    EOF
  end
  edit 'app/views/store/add_to_cart.html.erb' do |data|
    data[/(.*)/m,1] = read('cart/add_to_cart.html.erb.2')
  end
  edit 'public/stylesheets/depot.css', 'cartmain' do |data|
    data[/().*The error box/,1] = <<-EOF.unindent(6) + "\n"
      /* START:cartmain */
      /* Styles for the cart in the main page */

      .cart-title {
        font: 120% bold;
      }

      .item-price, .total-line {
        text-align: right;
      }

      .total-line .total-cell {
        font-weight: bold;
        border-top: 1px solid #595;
      }
      /* END:cartmain */
    EOF
  end
  edit 'app/models/cart.rb' do |data|
    data[/()^end/,1] = "\n" + <<-EOF.unindent(4)
      #START:total_price
      def total_price
        @items.sum { |item| item.price }
      end
      #END:total_price
    EOF
  end
  restart_server unless $R22
  post '/store/add_to_cart/2', {}
  post '/store/add_to_cart/2', {}
  post '/store/add_to_cart/3', {}
end

section 9.1, 'Iteration D1: Moving the Cart' do
  edit 'app/views/store/add_to_cart.html.erb' do |data|
    data[/(<% for .* end %>)/m,1] =
      '<%= render(:partial => "cart_item", :collection => @cart.items) %>'
  end
  edit 'app/views/store/_cart_item.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/()/,1] = <<-EOF.unindent(6)
      <tr>
        <td><%= cart_item.quantity %>&times;</td>
        <td><%=h cart_item.title %></td>
        <td class="item-price"><%= number_to_currency(cart_item.price) %></td>
      </tr>
    EOF
  end
  cmd 'cp app/views/store/add_to_cart.html.erb app/views/store/_cart.html.erb'
  edit 'app/views/store/_cart.html.erb' do |data|
    data.gsub!('@cart','cart')
  end
  edit 'app/views/layouts/store.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/<div id="side">()/,1] = "\n" + <<-'EOF'
      <!-- START_HIGHLIGHT -->
      <div id="cart">
        <%= render(:partial => "cart", :object => @cart) %>
      </div>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'index' do |data|
    data[/()  def index/,1] = "  #START:index\n"
    data[/index\n.*?\n  end\n()/m,1] = "  #END:index\n"
    data[/@products = .*()/,1] = "\n    @cart = find_cart"
  end
  edit 'public/stylesheets/depot.css', 'cartside' do |data|
    data[/().*The error box/,1] = <<-EOF.unindent(6) + "\n"
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
  get '/store'
  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data[/@cart.add_product\(product\)\n()/,1] = <<-EOF.unindent(2)
      #START_HIGHLIGHT
      redirect_to_index
      #END_HIGHLIGHT
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'redirect_to_index' do |data|
    data[/redirect_to_index\(msg()\)/,1] = " = nil"
    data[/flash\[:notice\] = msg()/,1] = " if msg"
  end
  cmd 'rm app/views/store/add_to_cart.html.erb'
  post '/store/add_to_cart/3', {}
end

section 9.2, 'Iteration D2: Creating an AJAX-Based Cart' do
  edit 'app/views/store/index.html.erb', 'form_remote_tag' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub!(':add_to_cart', ':form_remote_tag')
    data[/\n(\s+<%= button_to.*\n)/,1] = <<-EOF.unindent(2)
      <% form_remote_tag :url => { :action => 'add_to_cart', :id => product } do %>
        <%= submit_tag "Add to Cart" %>
      <% end %>
    EOF
  end
  edit 'app/views/layouts/store.html.erb', 'jit' do |data|
    data[/()<html>/,1] = "<!-- START:jit -->\n"
    data[/()<body /,1] = "<!-- END:jit -->\n"
    data[/()<\/head>/,1] = <<-EOF.unindent(4)
      <!-- START_HIGHLIGHT -->
      <%= javascript_include_tag :defaults %>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data[/\n(\s+redirect_to_index\n)/,1] = <<-EOF.unindent(2)
      respond_to do |format|
        format.js
      end
    EOF
  end
  edit 'app/views/store/add_to_cart.js.rjs' do |data|
    data[/()/,1] = 
      'page.replace_html("cart", :partial => "cart", :object => @cart)'
  end
end

section 9.3, 'Iteration D3: Highlighting Changes' do
  edit 'app/models/cart.rb' do |data|
    data[/\n(\s+@items << .*\n)/,1] = <<-EOF
      #START_HIGHLIGHT
      current_item = CartItem.new(product)
      @items << current_item 
      #END_HIGHLIGHT
    EOF
    data[/def add_product.*?()^  end/m,1] = <<-EOF.unindent(2)
      #START_HIGHLIGHT
      current_item
      #END_HIGHLIGHT
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/().*@cart.add_product/,1] = "#START_HIGHLIGHT\n"
    data[/()@cart.add_product/,1] = '@current_item = '
    data[/@cart.add_product.*\n()/,1] = "#END_HIGHLIGHT\n"
  end
  edit 'app/views/store/_cart_item.html.erb' do |data|
    data[/(<tr>\n)/,1] = <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <% if cart_item == @current_item %>
        <tr id="current_item">
      <% else %>
        <tr>
      <% end %>
      <!-- #END_HIGHLIGHT -->
    EOF
  end
  edit 'app/views/store/add_to_cart.js.rjs' do |data|
    data[/.*()/m,1] = "\n\n" + <<-EOF.unindent(6)
      page[:current_item].visual_effect :highlight,
                                        :startcolor => "#88ff88",
                                        :endcolor => "#114411"
    EOF
  end
end

section 9.4, 'Iteration D4: Hide an Empty Cart' do
  edit 'app/views/store/add_to_cart.js.rjs' do |data|
    data[/().*visual_effect/,1] = <<-EOF.unindent(6) + "\n"
      page[:cart].visual_effect :blind_down if @cart.total_items == 1
    EOF
  end
  edit 'app/models/cart.rb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/()^end/,1] = "\n" + <<-EOF.unindent(4)
      #START:total_items
      def total_items
        @items.sum { |item| item.quantity }
      end
      #END:total_items
    EOF
  end
  cmd 'ls -p app'
  cmd 'ls -p app/helpers'
  edit 'app/views/layouts/store.html.erb', 'hidden_div' do |data|
    data[/<div id="cart">.*?(<\/div>)/m,1] = '<% end %>' +
      "\n    <!-- END:hidden_div -->"
    data[/(<div id="cart">)/,1] =
      "<!-- START:hidden_div -->\n      " +
      '<% hidden_div_if(@cart.items.empty?, :id => "cart") do %>'
  end
  edit 'app/helpers/store_helper.rb' do |data|
    data[/()^end/,1] = <<-EOF.unindent(4)
      def hidden_div_if(condition, attributes = {}, &block)
        if condition
          attributes["style"] = "display: none"
        end
        content_tag("div", attributes, &block)
      end
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'empty_cart' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/().*"Your cart is currently empty"/,1] = "#START_HIGHLIGHT\n"
    data[/"Your cart is currently empty".*()/,1] = "\n#END_HIGHLIGHT"
    data[/(\("Your cart is currently empty"\))/,1] = ''
  end
end

section 9.5, 'Iteration D5: Degrading If Javascript Is Disabled' do
  edit 'app/controllers/store_controller.rb', 'add_to_cart' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/^(.*format.js\n)/,1] = <<-EOF
      #START_HIGHLIGHT
      format.js if request.xhr?
      format.html {redirect_to_index}
      #END_HIGHLIGHT
    EOF
  end
  post '/store/empty_cart', {}
  post '/store/add_to_cart/3', {}
end

section 10.1, 'Iteration E1: Capturing an Order' do
  cmd 'ruby script/generate scaffold order name:string address:text ' +
    'email:string pay_type:string'
  cmd 'ruby script/generate scaffold line_item product_id:integer ' +
    'order_id:integer quantity:integer total_price:decimal'
  edit Dir['db/migrate/*_create_orders.rb'].first, 'up' do |data|
    data[/()  def self.up/,1] = "  #START:up\n"
    data[/self.up\n.*?\n  end\n()/m,1] = "  #END:up\n"
    data[/().*pay_type/,1] = "#START_HIGHLIGHT\n"
    data[/t.string :pay_type()/,1] = ", :limit => 10\n#END_HIGHLIGHT"
  end
  edit Dir['db/migrate/*_create_line_items.rb'].first do |data|
    data[/create_table :line_items do \|t\|\n(.*?\n)\n/m,1] = <<-EOF
      #START_HIGHLIGHT
      t.integer :product_id,  :null => false, :options =>
        "CONSTRAINT fk_line_item_products REFERENCES products(id)"
      t.integer :order_id,    :null => false, :options =>
        "CONSTRAINT fk_line_item_orders REFERENCES orders(id)"
      t.integer :quantity,    :null => false
      t.decimal :total_price, :null => false, :precision => 8, :scale => 2
      #END_HIGHLIGHT
    EOF
  end
  cmd 'rake db:migrate'
  cmd 'sqlite3 db/development.sqlite3 .schema'
  edit 'app/models/order.rb', 'has_many' do |data|
    data[/()class Order/,1] = "#START:has_many\n"
    data[/class Order.*\n()/,1] = <<-EOF.unindent(4)
      #END:has_many
      #START:has_many
      has_many :line_items
      #END:has_many
    EOF
    data[/()^end/,1] = "#START:has_many\n"
    data[/^end()/,1] = "\n#END:has_many"
  end
  edit 'app/models/product.rb', 'has_many' do |data|
    data[/()class Product/,1] = "#START:has_many\n"
    data[/class Product.*()/,1] = "\n  has_many :line_items"
    data[/has_many :line_items()/,1] = "\n  # ...\n#END:has_many"
  end
  edit 'app/models/line_item.rb', 'belongs_to' do |data|
    data[/()class LineItem/,1] = "#START:belongs_to\n"
    data[/class LineItem.*()/,1] = "\n" + <<-EOF.unindent(6) + "\n"
        belongs_to :order
        belongs_to :product
      #END:belongs_to
    EOF
    data[/()^end/,1] = "#START:belongs_to\n"
    data[/^end()/,1] = "\n#END:belongs_to"
  end
  edit 'app/views/store/_cart.html.erb' do |data|
    data[/().*Empty cart/,1] = <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <%= button_to \"Checkout\", :action => 'checkout' %>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'checkout' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/().*def empty_cart/,1] = <<-EOF.unindent(4) + "\n"
      #START:checkout
      def checkout
        @cart = find_cart
        if @cart.items.empty?
          redirect_to_index("Your cart is empty")
        else
          @order = Order.new
        end
      end
      #END:checkout
    EOF
  end
  edit 'app/views/store/checkout.html.erb' do |data|
    data[/()/,1] = read('orders/checkout.html.erb')
  end
  edit 'app/models/order.rb', 'select' do |data|
    data[/()class Order.*/,1] = "#START:select\n"
    data[/#END:has_many.*()/,1] = "\n" + <<-EOF.unindent(4)
      PAYMENT_TYPES = [
        #  Displayed       stored in db
        [ "Check",          "check" ],
        [ "Credit card",    "cc" ],
        [ "Purchase order", "po" ]
      ]

      # ...
      #END:select
    EOF
  end
  edit 'public/stylesheets/depot.css', 'form' do |data|
    data[/().*The error box/,1] = <<-EOF.unindent(6) + "\n"
      /* START:form */
      /* Styles for order form */

      .depot-form fieldset {
        background: #efe;
      }

      .depot-form legend {
        color: #dfd;
        background: #141;
        font-family: sans-serif;
        padding: 0.2em 1em;
      }

      .depot-form label {
        width: 5em;
        float: left;
        text-align: right;
        padding-top: 0.2em;
        margin-right: 0.1em;
        display: block;
      }

      .depot-form select, .depot-form textarea, .depot-form input {
        margin-left: 0.5em;
      }

      .depot-form .submit {
        margin-left: 4em;
      }

      .depot-form div {
        margin: 0.5em 0;
      }
      /* END:form */
    EOF
  end
  post '/store/checkout', {}
  post '/store/save_order', {}
  edit 'app/models/order.rb', 'validate' do |data|
    data[/()class Order/,1] = "#START:validate\n"
    data[/() *# \.\.\./,1] = "#END:validate\n"
    data[/#END:select()/,1] = "\n" + <<-EOF.unindent(4)
      #START:validate
      validates_presence_of :name, :address, :email, :pay_type
      validates_inclusion_of :pay_type, :in => 
        PAYMENT_TYPES.map {|disp, value| value}

      # ...
      #END:validate
    EOF
  end
  edit 'app/controllers/store_controller.rb', 'save_order' do |data|
    data[/().*def empty_cart/,1] = <<-EOF.unindent(4) + "\n"
      #START:save_order
      def save_order
        @cart = find_cart
        @order = Order.new(params[:order]) # <label id="code.p.new.order"/>
        @order.add_line_items_from_cart(@cart) # <label id="code.p.append.li"/>
        if @order.save                     # <label id="code.p.save"/>
          session[:cart] = nil
          redirect_to_index("Thank you for your order")
        else
          render :action => 'checkout'
        end
      end
      #END:save_order
    EOF
  end
  edit 'app/models/order.rb' do |data|
    data[/()#START:has_many\nend/,1] = "\n" + <<-EOF.unindent(4)
      #START:add_line_items_from_cart
      def add_line_items_from_cart(cart)
        cart.items.each do |item|
          li = LineItem.from_cart_item(item)
          line_items << li
        end
      end
      #END:add_line_items_from_cart
    EOF
  end
  edit 'app/models/line_item.rb' do |data|
    data[/#END:belongs_to\n\n(\s*)\n#START:belongs_to/,1] = <<-EOF.unindent(4)
      def self.from_cart_item(cart_item)
        li = self.new
        li.product     = cart_item.product
        li.quantity    = cart_item.quantity
        li.total_price = cart_item.price
        li
      end
    EOF
  end
  db "select * from orders"
  db "select * from line_items"
  post '/store/save_order', {}
  post '/store/checkout',
    'order[name]' => 'Dave Thomas',
    'order[address]' => '123 Main St',
    'order[email]' => 'customer@example.com',
    'order[pay_type]' => 'check'
  db "select * from orders"
  db "select * from line_items"
  edit 'app/views/store/add_to_cart.js.rjs' do |data|
    data[/()/,1] = <<-EOF.unindent(6) + "\n"
      #START_HIGHLIGHT
      page.select("div#notice").each { |div| div.hide }
      #END_HIGHLIGHT
    EOF
  end
end

section 11.1, 'Iteration F1: Adding Users' do
  cmd 'ruby script/generate scaffold user name:string hashed_password:string salt:string'
  restart_server
  cmd 'cat ' + Dir['db/migrate/*_create_users.rb'].first
  cmd 'rake db:migrate'
  edit "app/models/user.rb" do |data|
    data[/(.*)/m,1] = read('users/user.rb')
  end
  edit 'app/controllers/users_controller.rb' do |data|
    data[/().*[.:]all/,1] = "#START_HIGHLIGHT\n"
    if $R22
      data[/:all(\))/,1] = ", :order => :name)\n#END_HIGHLIGHT"
    else
      data[/\.all()/,1] = "(:order => :name)\n#END_HIGHLIGHT"
    end
    data.gsub!(/'.*?'/) do |string|
      string.gsub("'",'"').gsub('User ', 'User #{@user.name} ')
    end
    data.gsub!('redirect_to(@user)', "redirect_to(:action=>'index')")
    data[/().*successfully created/,1] = "#START_HIGHLIGHT\n"
    data[/().*successfully updated/,1] = "#START_HIGHLIGHT\n"
    data[/successfully created.*?'index.*?\n()/m,1] = "#END_HIGHLIGHT\n"
    data[/successfully updated.*?'index.*?\n()/m,1] = "#END_HIGHLIGHT\n"
    data[/:created,() :location/,1] = "\n" + (' ' * 28)
    data[/@user.errors,() :status/,1] = "\n" + (' ' * 28)
    data[/@user.errors,() :status/,1] = "\n" + (' ' * 28)
  end
  edit 'app/views/users/index.html.erb' do |data|
    data[/(.*<th>Hashed password.*\n)/,1] = ''
    data[/(.*<th>Salt.*\n)/,1] = ''
    data[/(.*user.hashed_password.*\n)/,1] = ''
    data[/(.*user.salt.*\n)/,1] = ''
    data[/,() :method => :del/,1] = "\n" + (' ' * 39)
  end
  edit "app/views/users/new.html.erb" do |data|
    data[/(.*)/m,1] = read('users/new.html.erb')
  end
  edit 'app/views/layouts/users.html.erb', 'head' do |data|
    data[/()<!DOCTYPE/,1] = "<!-- START:head -->\n"
    data[/'scaffold'()/,1] = ", 'depot'"
    data[/\n().*'scaffold'.*/,1] = "<!-- START_HIGHLIGHT -->\n"
    data[/'scaffold'.*\n()/,1] = "<!-- END_HIGHLIGHT -->\n"
    data[/()<body>/,1] = "<!-- END:head -->\n"
  end
  get '/users'
  post '/users/new',
    'user[name]' => 'dave',
    'user[password]' => 'secret',
    'user[password_confirmation]' => 'secret'
  db 'select * from users'
end

section 11.2, 'Iteration F2: Logging in' do
  cmd 'ruby script/generate controller admin login logout index'
  restart_server
  edit "app/controllers/admin_controller.rb" do |data|
    data[/(.*)/m,1] = read('users/admin_controller.rb')
  end
  edit "app/views/admin/login.html.erb" do |data|
    data[/(.*)/m,1] = read('users/login.html.erb')
  end
  edit "app/views/admin/index.html.erb" do |data|
    data[/(.*)/m,1] = read('users/index.html.erb')
  end
  post '/admin/login',
    'name' => 'dave',
    'password' => 'secret'
end

section 11.3, 'Iteration F3: Limiting Access' do
  edit "app/controllers/#{$APP}.rb" do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/class ApplicationController.*\n()/,1] = <<-EOF.unindent(4)
      #START_HIGHLIGHT
      before_filter :authorize, :except => :login
      #END_HIGHLIGHT
    EOF
    data[/()^end\n/,1] = <<-EOF.unindent(6)
    
      #START_HIGHLIGHT
      protected
        def authorize
          unless User.find_by_id(session[:user_id])
            flash[:notice] = "Please log in"
            redirect_to :controller => 'admin', :action => 'login'
          end
        end
      #END_HIGHLIGHT
    EOF
  end
  edit 'app/controllers/store_controller.rb' do |data|
    data.gsub!(/\s+# <label.*/, '')
  end

  edit "app/controllers/store_controller.rb", 'authorize' do |data|
    data[/()class StoreController/,1] = "#START:authorize\n"
    data[/class StoreController.*\n()/,1] = "#END:authorize\n"
    data[/()^end\n/,1] = <<-EOF.unindent(6)
      #START:authorize
        #...
      protected

        def authorize
        end
    EOF
    data[/^end\n()/,1] = <<-EOF.unindent(6)
      #END:authorize
    EOF
  end
  cmd 'rake db:sessions:clear'

  get '/admin/logout'
  get '/store'
  get '/products'
  post '/admin/login',
    'name' => 'dave',
    'password' => 'secret'
  get '/products'
end

section 11.4, 'Iteration F4: Adding a Sidebar, More Administration' do
  edit "app/controllers/#{$APP}.rb", 'layout' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data[/()class ApplicationController/,1] = "#START:layout\n"
    data[/class ApplicationController.*\n()/,1] = <<-EOF.unindent(4)
      layout "store"
      #...
      #END:layout
    EOF
  end
  get '/admin'
  get '/users'
  edit "app/views/layouts/store.html.erb", 'hidden_div' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! /\n +<% hidden_div_if.*? end %>\s*\n/m do |hidden_div|
      hidden_div.gsub!(/^/, '  ')
      s,e = "<!-- START_HIGHLIGHT -->\n", "<!-- END_HIGHLIGHT -->"
      "\n#{s}      <% if @cart %>\n#{e}#{hidden_div}#{s}      <% end %>\n#{e}\n"
    end
    data[/<div id="side">.*?() *<\/div>/m,1] = "\n" + <<-EOF
      <!-- START_HIGHLIGHT -->
      <% if session[:user_id] %>
        <br />
        <%= link_to 'Orders',   :controller => 'orders' %><br />
        <%= link_to 'Products', :controller => 'products' %><br />
        <%= link_to 'Users',    :controller => 'users'    %><br />
        <br />
        <%= link_to 'Logout', :controller => 'admin', :action => 'logout' %>
      <% end %>
      <!-- END_HIGHLIGHT -->
    EOF
  end
  get '/admin'
  get '/users'
  cmd 'rm app/views/layouts/products.html.erb'
  cmd 'rm app/views/layouts/users.html.erb'
  cmd 'rm app/views/layouts/orders.html.erb'

  get '/users'

  edit "app/models/user.rb" do |data|
    data[/() *private/,1] = <<-EOF.unindent(4)
      #START:after_destroy
      def after_destroy
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
  edit "app/controllers/store_controller.rb", 'find_cart' do |data|
    data[/(  def find_cart.*?\n\  end\n)/m,1] = <<-EOF
      #START:find_cart
      def find_cart
        @cart = (session[:cart] ||= Cart.new)
      end
      #END:find_cart
    EOF
  end
  edit "app/controllers/store_controller.rb", 'before_filter' do |data|
    data.gsub! /.*@cart = find_cart\n/, ''
    data[/class StoreController.*\s#END.*\n()/,1] = <<-EOF
      #START:before_filter
      before_filter :find_cart, :except => :empty_cart
      #END:before_filter
    EOF
  end
  cmd 'echo "Product.new" | ruby script/console'
end

section 12.1, 'Generating the XML Feed' do
  edit 'app/models/product.rb', 'has_many' do |data|
    data[/class Product.*\n()/,1] = <<-EOF.unindent(4)
      #START_HIGHLIGHT
      has_many :orders, :through => :line_items
      #END_HIGHLIGHT
    EOF
  end
  cmd 'ruby script/generate controller info who_bought'
  edit 'app/controllers/info_controller.rb' do |data|
    data[/\n().*def who_bought/,1] = "  #START:who_bought\n"
    data[/\n  end\n()/,1] = "  #END:who_bought\n"
    data[/def who_bought.*\n()/,1] = <<-EOF.unindent(2)
      @product = Product.find(params[:id])
      @orders  = @product.orders
      respond_to do |format|
        format.xml { render :layout => false }
      end
    EOF
    data[/()^end\n/,1] = <<-EOF.unindent(6)
      protected

        def authorize
        end
    EOF
  end
  edit 'app/views/info/who_bought.xml.builder' do |data|
    data << <<-EOF.unindent(6)
      xml.order_list(:for_product => @product.title) do
        for o in @orders
          xml.order do
            xml.name(o.name)
            xml.email(o.email)
          end
        end
      end
    EOF
  end
  cmd 'curl --silent http://localhost:3000/info/who_bought/3'
  restart_server
  cmd 'curl --silent http://localhost:3000/info/who_bought/3'
  db 'select * from products'
  db 'select * from line_items'
  cmd 'curl --silent http://localhost:3000/info/who_bought/3'
  edit 'app/views/info/who_bought.html.erb' do |data|
    data[/(.*)/m,1] = <<-EOF.unindent(6)
      <h3>People Who Bought <%= @product.title %></h3>

      <ul>
        <% for order in @orders  -%>
          <li>
              <%= mail_to order.email, order.name %>
          </li>
        <%  end -%>
      </ul>
    EOF
  end
  edit 'app/controllers/info_controller.rb' do |data|
    data[/respond_to.*\n()/,1] = <<-EOF
      format.html
    EOF
  end
  cmd 'curl --silent -H "Accept: text/html" http://localhost:3000/info/who_bought/3'
  cmd 'curl --silent -H "Accept: application/xml" http://localhost:3000/info/who_bought/3'

  cmd 'cp app/controllers/info_controller.rb ' +
         'app/controllers/info_controller.save'

  edit 'app/controllers/info_controller.rb' do |data|
    data[/format.xml.*()\}/,1] =
      ",\n                   :xml => @product.to_xml(:include => :orders) "
  end

  cmd 'curl --silent http://localhost:3000/info/who_bought/3.xml'

  edit 'app/views/info/who_bought.atom.builder' do |data|
    data << <<-'EOF'.unindent(6)
      atom_feed do |feed|
        feed.title "Who bought #{@product.title}"
        feed.updated @orders.first.created_at
      
        for order in @orders
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
                for item in order.line_items
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
  end

  edit 'app/controllers/info_controller.rb' do |data|
    data.gsub!(/\n.*format.xml.*/) do |stmt|
      stmt.gsub(/xml.*/, 'atom { render :layout => false }') + stmt
    end
  end

  cmd 'curl --silent http://localhost:3000/info/who_bought/3.atom'

  edit 'app/controllers/info_controller.rb' do |data|
    data.gsub!(/\n.*format.xml.*\n.*/) do |stmt|
      stmt + stmt.gsub('xml','json')
    end
  end

  cmd 'curl --silent -H "Accept: application/json" http://localhost:3000/info/who_bought/3'

  cmd 'mv app/controllers/info_controller.save ' +
         'app/controllers/info_controller.rb'

  cmd 'rake doc:app'
  cmd 'rake stats'
end

section 13, 'Task I: Internationalization' do
  post '/store/empty_cart', {}
  cmd "cp #{$DATA}/i18n/initializer.rb config/initializers/i18n.rb"
  restart_server
  edit 'app/views/layouts/store.html.erb', 'i18n' do |data|
    data.gsub! /^\s*<!-- START_HIGHLIGHT -->\n/, ''
    data.gsub! /^\s*<!-- END_HIGHLIGHT -->\s*\n/, ''
    data[/\n()\s+<%= image_tag/,1] = <<-EOF.unindent(4)
      <!-- START:i18n -->
      <% form_tag '', :method => 'GET', :class => 'locale' do %>
        <%= select_tag 'locale', options_for_select(LANGUAGES, I18n.locale),
          :onchange => 'this.form.submit()' %>
        <%= submit_tag 'submit' %>
        <%= javascript_tag "$$('.locale input').each(Element.hide)" %>
      <% end %>
      <!-- END:i18n -->
    EOF
  end
  get '/store?locale=en'
  edit "app/controllers/#{$APP}.rb" do |data|
    # data.gsub! /.*#START:.*\n/, ''
    # data.gsub! /.*#END:.*\n/, ''
    data[/^()class ApplicationController/,1] = "#START:i18n\n"
    data[/^ +before_filter.*?\n()/,1] = <<-EOF.unindent(4)
      before_filter :set_locale
    EOF
    data[/#\.\.\.\n()/,1] = "#END:i18n\n"
    data[/(^protected$)/,1] = "#START:i18n\nprotected\n#END:i18n"
    data[/^()end\n/,1] = "\n" + <<-'EOF'.unindent(6)
      #START:i18n
        def set_locale
          session[:locale] = params[:locale] if params[:locale]
          I18n.locale = session[:locale] || I18n.default_locale

          locale_path = "#{LOCALES_DIRECTORY}#{I18n.locale}.yml"

          unless I18n.load_path.include? locale_path
            I18n.load_path << locale_path
            I18n.backend.send(:init_translations)
          end

        rescue Exception => err
          logger.error err
          flash.now[:notice] = "#{I18n.locale} translation not available"

          I18n.load_path -= [locale_path]
          I18n.locale = session[:locale] = I18n.default_locale
        end
    EOF
    data[/^end\n()/,1] = "#END:i18n\n"
  end
  edit 'public/stylesheets/depot.css', 'i18n' do |data|
    data << "\n" + <<-EOF.unindent(6)
      /* START:i18n */
      .locale {
              float:right;
              padding-top: 0.2em
      }
      /* END:i18n */
    EOF
  end
  restart_server
  get '/store?locale=es'
  edit 'app/views/layouts/store.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! '"Pragmatic Bookshelf"', "I18n.t('layout.title')"
    data.gsub! 'Home', "<%= I18n.t 'layout.side.home' %>"
    data.gsub! 'Questions', "<%= I18n.t 'layout.side.questions' %>"
    data.gsub! 'News', "<%= I18n.t 'layout.side.news' %>"
    data.gsub! 'Contact', "<%= I18n.t 'layout.side.contact' %>"
    data.gsub! /(.*I18n\.t)/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(I18n\.t.*)/, "\\1\n<!-- END_HIGHLIGHT -->"
  end
  cmd "cp -r #{$DATA}/i18n/*.yml config/locales"
  get '/store?locale=es'
  edit 'app/views/store/index.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! 'Your Pragmatic Catalog', "<%= I18n.t 'main.title' %>"
    data.gsub! '"Add to Cart"', "I18n.t('main.button.add')"
    data.gsub! /(.*I18n\.t)/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(I18n\.t.*)/, "\\1\n<!-- END_HIGHLIGHT -->"
    data.gsub! /\{ :action/, '{:action'
    data.gsub! /product \}/, 'product}'
  end
  get '/store?locale=es'
  edit 'app/views/store/_cart.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! 'Your Cart', "<%= I18n.t 'layout.cart.title' %>"
    data.gsub! '"Empty cart"', "I18n.t('layout.cart.button.empty')"
    data.gsub! '"Checkout"', "I18n.t('layout.cart.button.checkout')"
    data.gsub! /(.*I18n\.t)/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(I18n\.t.*)/, "\\1\n<!-- END_HIGHLIGHT -->"
  end
  post '/store/add_to_cart/2', {}
  edit 'app/views/store/checkout.html.erb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! 'Please Enter Your Details', "<%= I18n.t 'checkout.legend' %>"
    data.gsub! '"Name', "I18n.t('checkout.name') + \""
    data.gsub! '"Address', "I18n.t('checkout.address') + \""
    data.gsub! '"E-Mail', "I18n.t('checkout.email') + \""
    data.gsub! '"Pay with', "I18n.t('checkout.pay_type') + \""
    data.gsub! '"Place Order"', "I18n.t('checkout.submit')"
    data.gsub! /(.*I18n\.t)/, "<!-- START_HIGHLIGHT -->\n\\1"
    data.gsub! /(I18n\.t.*)/, "\\1\n<!-- END_HIGHLIGHT -->"
    data.gsub! '"Select a payment method"', "I18n.t('checkout.pay_prompt')"
    data.gsub! /(.*pay_prompt)/, "# START_HIGHLIGHT\n\\1"
    data.gsub! /(pay_prompt.*)/, "\\1\n# END_HIGHLIGHT"
  end
  edit 'app/controllers/store_controller.rb' do |data|
    data.gsub! /.*_HIGHLIGHT.*\n/, ''
    data.gsub! '"Thank you for your order"', "I18n.t('flash.thanks')"
    data.gsub! /(.*I18n\.t)/, "# START_HIGHLIGHT\n\\1"
    data.gsub! /(I18n\.t.*)/, "\\1\n# END_HIGHLIGHT"
  end
  get '/store?locale=es'
  post '/store/add_to_cart/2', {}
  post '/store/checkout', {}
  post '/store/save_order', {}
  post '/store/save_order', 
    'order[name]' => 'Joe User',
    'order[address]' => '123 Main St., Anytown USA',
    'order[email]' => 'juser@hotmail.com',
    'order[pay_type]' => 'check'
  get '/store?locale=en'
end

section 14.1, 'Tests Baked Right In' do
  cmd 'ls -p test'
  cmd 'ls test/unit'
  cmd 'ls test/functional'
end

section 14.2, 'Unit Testing of Models' do
  cmd 'cat test/unit/product_test.rb'
  cmd 'ruby -Itest test/unit/product_test.rb'
  cmd 'rake db:test:prepare'
  cmd 'ruby -Itest test/unit/product_test.rb'
  cmd 'rake test:units'
  edit "test/unit/product_test.rb" do |data|
    data[/(.*)/m,1] = read('test/product_test.rb')
  end
  edit "test/fixtures/products.yml" do |data|
    data[/(.*)/m,1] = read('test/products.yml')
  end
  cmd 'rake test:units'
  edit "test/unit/cart_test.rb" do |data|
    data[/(.*)/m,1] = read('test/cart_test.rb')
  end
  cmd 'ruby -I test test/unit/cart_test.rb'
  edit "test/unit/cart_test1.rb" do |data|
    data[/(.*)/m,1] = read('test/cart_test1.rb')
  end
  cmd 'ruby -I test test/unit/cart_test1.rb'
end

section 14.3, 'Functional Testing of Controllers' do
  edit "app/controllers/#{$APP}.rb", 'auth' do |data|
    data.gsub! /.*#START:.*\n/, ''
    data.gsub! /.*#END:.*\n/, ''
    data.gsub! /.*#\.\.\.*\n/, ''
    data[/^()class ApplicationController/,1] = "#START:auth\n"
    data[/^ +before_filter.*?\n()/,1] = "  #...\n\n#END:auth\n"
    data[/\n(\s*)\n *protected/,1] = "#START:auth\n"
    data[/^end\n()/,1] = "#END:auth\n"
  end
  edit "test/functional/admin_controller_test.rb" do |data|
    data[/(.*)/m,1] = read('test/admin_controller_test.rb')
  end
  edit "test/fixtures/users.yml" do |data|
    data[/(.*)/m,1] = read('test/users.yml')
  end
  cmd 'ruby -I test test/functional/admin_controller_test.rb'
end
  
section 14.4, 'Integration Testing of Applications' do
  cmd 'ruby script/generate integration_test user_stories'
  edit "test/integration/user_stories_test.rb" do |data|
    data[/(.*)/m,1] = read('test/user_stories_test.rb')
  end
  cmd 'ruby -I test test/integration/user_stories_test.rb'
  edit "test/integration/dsl_user_stories_test.rb" do |data|
    data[/(.*)/m,1] = read('test/dsl_user_stories_test.rb')
  end
  cmd 'ruby -I test test/integration/dsl_user_stories_test.rb'
end

section 14.5, 'Performance Testing' do
  cmd 'mkdir test/fixtures/performance/'
  edit "test/fixtures/performance/products.yml" do |data|
    data[/(.*)/m,1] = read('test/performance_products.yml')
  end
  edit "test/performance/order_speed_test.rb" do |data|
    data[/(.*)/m,1] = read('test/order_speed_test.rb')
  end
  cmd 'ruby -I test test/performance/order_speed_test.rb'
  edit "app/models/user.rb" do |data|
    data[/def self.encrypted_password.*?\n()/,1] = <<-EOF.unindent(2)
      100000.times { Math.sin(1)}
    EOF
  end
  encrypt = 'User.encrypted_password("secret", "salt")'
  cmd "ruby script/performance/benchmarker #{encrypt.inspect}"
  cmd "ruby script/performance/profiler #{encrypt.inspect}"
  edit "app/models/user.rb", 'revert' do |data|
    data.gsub!(/^.*Math.sin.*\n/,'')
  end
end

section 15, 'Rails In Depth' do
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
  cmd 'echo "puts $:" | ruby script/console'
end

section 16, 'Active Support' do
  rails 'namelist', :e1
  restart_server
  cmd 'ruby script/generate model person name:string'
  cmd 'rake db:migrate'
  edit 'app/controllers/people_controller.rb' do |data|
    data[/()/,1] = read('namelist/people_controller.rb')
  end
  edit 'app/views/layouts/people.html.erb' do |data|
    data[/()/,1] = read('namelist/people.html.erb')
  end
  cmd 'mkdir app/views/people'
  edit 'app/views/people/index.html.erb' do |data|
    data[/()/,1] = read('namelist/index.html.erb')
  end
  post '/people', 'person[name]' => 'Dave'
  post '/people', 'person[name]' => "G\xc3\xbcnter"
  db "select name,length(name) from people where name like 'G%'"
end

section 17, 'Migration' do
  rails 'migration'
  cmd "cp -rpv #{$BASE}/plugins/* vendor/plugins/"
  restart_server
  cmd 'cp -v -r ../depot/db/* db/'
  cmd 'cp -v -r ../depot/app/models/* app/models/'
  cmd 'ruby script/generate model discount'
  cmd 'ruby script/generate migration add_status_to_user status:string'
  20.upto(37) do |i|
    if i == 33
      cmd 'mkdir db/migrate/dev_data'
      cmd "cp #{$DATA}/migrate/users.yml db/migrate/dev_data"
    else
      cmd "cp -v #{$DATA}/migrate/0#{i}* db/migrate"
    end
    cmd "cp -v #{$DATA}/migrate/migration_helpers.rb lib" if i == 37
    cmd 'rake db:migrate'
    cmd "rm #{Dir['db/migrate/2*'].sort.last}" if [26,32].include?(i)
    cmd 'rake annotate_models'
    cmd 'cat app/models/line_item.rb'
  end
end

section 18, 'Active Record: The Basics' do
  Dir.chdir(File.join($WORK,'migration'))
  cmd 'echo "Order.column_names" | ruby script/console'
  cmd 'echo "Order.columns_hash[\"pay_type\"]" | ruby script/console'
  db "select * from orders limit 1"
  cmd 'echo "Product.find(:first).price_before_type_cast" | ruby script/console'
  cmd 'echo "Product.find(:first).updated_at_before_type_cast" | ruby script/console'
  irb 'e1/ar/new_examples.rb'
  irb 'e1/ar/find_examples.rb'
  irb 'e1/ar/dump_serialize_table.rb'
  irb 'e1/ar/aggregation.rb'
end

section 19, 'ActiveRecord: Relationships Between Tables' do
  Dir.chdir(File.join($WORK,'migration'))
  irb 'e1/ar/associations.rb'
  irb 'e1/ar/sti.rb'
  irb 'e1/ar/polymorphic.rb 1'
  db "select * from articles"
  db "select * from catalog_entries"
  db "delete from catalog_entries"
  irb 'e1/ar/polymorphic.rb 2'
  db "select * from articles"
  db "select * from images"
  db "select * from sounds"
  db "select * from catalog_entries"
  irb 'e1/ar/self_association.rb'
  irb 'e1/ar/acts_as_list.rb'
  irb 'e1/ar/acts_as_tree.rb'
  irb 'e1/ar/one_to_one.rb'
  irb 'e1/ar/counters.rb'
end

section 20, 'ActiveRecord: Object Life Cycle' do
  Dir.chdir(File.join($WORK,'migration'))
  irb 'e1/ar/encrypt.rb'
  db "select * from orders"
  irb 'e1/ar/observer.rb'
  irb 'e1/ar/attributes.rb'
  db "select id, quantity*unit_price from line_items"
  irb 'e1/ar/transactions.rb 1'
  db "select * from accounts"
  irb 'e1/ar/transactions.rb 2'
  db "select * from accounts"
  irb 'e1/ar/transactions.rb 3'
  irb 'e1/ar/transactions.rb 4'
  irb 'e1/ar/transactions.rb 5'
  irb 'e1/ar/optimistic.rb'
end

section 21, 'Action Controller: Routing and URLs' do
  rails 'restful'
  cmd 'ruby script/generate scaffold article title:string summary:text content:text'
  cmd 'rake db:migrate'
  cmd 'rake routes'
  edit 'config/routes.rb', 'comments' do |data|
    data[/()^ActionController::Routing::Routes/,1] = "#START:comments\n"
    data[/()  map.resources :articles/,1] = "  #START_HIGHLIGHT\n"
    data[/map.resources :articles.*\n()/,1] = <<-EOF.unindent(4)
      #END_HIGHLIGHT

      # ...

      #END:comments
    EOF
    data[/()^\s+map.connect/,1] = "#START:comments\n"
    data[/^end()/,1] = "\n#END:comments"
  end
  edit 'app/controllers/articles_controller.rb' do |data|
    data[/:created,() :location/,1] = "\n" + (' ' * 28)
    data[/@article.errors,() :status/,1] = "\n" + (' ' * 28)
    data[/@article.errors,() :status/,1] = "\n" + (' ' * 28)
  end
  edit 'app/views/articles/index.html.erb' do |data|
    data[/,() :method => :del/,1] = "\n" + (' ' * 39)
  end
  edit 'config/routes.rb' do |data|
    data[/map.resources :articles()/,1] = ', :collection => { :recent => :get }'
  end
  cmd 'rake routes'
  edit 'config/routes.rb' do |data|
    data[/map.resources :articles, (.*)/,1] =
      ':member => { :embargo => :put, :release => :put }'
  end
  cmd 'rake routes'
  edit 'config/routes.rb' do |data|
    data[/map.resources :articles, (.*)/,1] = ':new => { :shortform => :post }'
  end
  cmd 'rake routes'
  edit 'config/routes.rb', 'comments' do |data|
    data[/map.resources :articles(, .*\n)/,1] = <<-EOF.unindent(4)
      do |article|
        article.resources :comments
      end
    EOF
  end
  cmd 'rake routes'
  cmd 'ruby script/generate model comment comment:text article_id:integer'
  cmd 'ruby script/generate controller comments new edit update destroy'
  cmd 'rm app/views/comments/destroy.html.erb'
  cmd 'rm app/views/comments/update.html.erb'
  edit 'app/models/article.rb' do |data|
    data[/()^end/,1] = "  has_many :comments\n"
  end
  edit 'app/models/comment.rb' do |data|
    data[/()^end/,1] = "  belongs_to :article\n"
  end
  cmd 'rake db:migrate'
  edit 'app/views/articles/show.html.erb' do |data|
    data[/()^<%= link_to 'Edit'/,1] = <<-EOF.unindent(6)
      <!-- START_HIGHLIGHT -->
      <% unless @article.comments.empty? %>
        <%= render :partial => "/comments/comment",
	           :collection => @article.comments %>
      <% end %>

      <%= link_to "Add comment", new_article_comment_url(@article) %> |
      <!-- END_HIGHLIGHT -->
    EOF
  end
  %w{_comment _form edit new}.each do |file|
    edit "app/views/comments/#{file}.html.erb" do |data|
      data[/(.*)/m,1] = read("comment/#{file}.html.erb")
    end
  end
  edit 'app/controllers/comments_controller.rb' do |data|
    data[/(.*)/m,1] = read("comment/comments_controller.rb")
  end
  rails 'routing', :e1
  cmd 'ruby script/generate controller store index add_to_cart'
  cmd "cp -v #{$DATA}/routing/* config"
  cmd 'mv -v config/*_test.rb test/unit'
  cmd 'rake db:schema:dump'
  cmd 'rake test'
end

section 21.2, 'Routing Requests' do
  Dir.chdir(File.join($WORK, 'depot'))
  irb 'e1/routing/config/routes_for_depot.rb'
  irb 'e1/routing/config/routes_for_blog.rb'
end

section 23.3, 'Helpers for Formatting, Linking, and Pagination' do
  rails 'view', :e1
  cmd "cp -v #{$CODE}/e1/views/app/controllers/*.rb app/controllers"
  cmd "cp -vr #{$CODE}/e1/views/app/views/pager app/views"
  cmd 'ruby script/generate model user name:string'
  restart_server
  cmd 'rake db:migrate'
  cmd 'echo "PagerController.new.populate" | ruby script/console'
  get '/pager/user_list'
  get '/pager/user_list?page=2'
end

section 23.5, 'Forms That Wrap Model Objects' do
  cmd "cp -rpv #{$BASE}/plugins/country_select vendor/plugins/"
  restart_server
  cmd 'ruby script/generate model product title:string description:text ' + 
       'image_url:string price:decimal'
  cmd "cp -v #{$CODE}/e1/views/db/migrate/*products.rb db/migrate/*products.rb"
  cmd "cp -v #{$CODE}/e1/views/app/models/shipping.rb app/models"
  cmd 'ruby script/generate model detail product_id:integer sku:string ' + 
       'manufacturer:string'
  cmd "cp -v #{$CODE}/e1/views/db/migrate/*details.rb db/migrate/*details.rb"
  cmd "cp -v #{$CODE}/e1/views/app/models/detail.rb app/models"
  cmd 'rake db:migrate'
  cmd "cp -vr #{$CODE}/e1/views/app/views/form_for app/views"
  get '/form_for/new'
  cmd "cp -vr #{$CODE}/e1/views/app/views/test app/views"
  get '/test/select'
  cmd "cp -vr #{$CODE}/e1/views/app/views/products app/views"
  get '/products/new'
end

section 23.6, 'Custom Form Builders' do
  cmd "cp -vr #{$CODE}/e1/views/app/helpers/tagged_builder.rb app/helpers"
  cmd "cp -vr #{$CODE}/e1/views/app/views/builder app/views"
  get '/builder/new'
  cmd "cp -vr #{$CODE}/e1/views/app/helpers/builder_helper.rb app/helpers"
  get '/builder/new_with_helper'
  cmd "cp -vr #{$CODE}/e1/views/app/views/array app/views"
  get '/array/edit'
end

section 23.7, 'Working with Nonmodel Fields' do
  get '/test/calculate'
end

section 23.8, 'Uploading Files to Rails Applications' do
  cmd 'ruby script/generate model picture comment:string name:string ' +
       'content_type:string data:binary'
  cmd "cp -v #{$CODE}/e1/views/db/migrate/*pictures.rb db/migrate/*pictures.rb"
  cmd "cp -v #{$CODE}/e1/views/app/models/picture.rb app/models"
  cmd 'rake db:migrate'
  cmd "cp -vr #{$CODE}/e1/views/app/views/upload app/views"
  get '/upload/get'
  # get '/upload/show'
end

section 23.9, 'Layouts and Components' do
  cmd "cp -vr #{$CODE}/e1/views/app/views/partial app/views"
  get '/partial/list'
end

section '23.10', 'Caching, Part Two' do
  cmd 'ruby script/generate model article body:text'
  cmd "cp -v #{$CODE}/e1/views/app/models/article.rb app/models"
  cmd "cp -vr #{$CODE}/e1/views/app/views/blog app/views"
  get '/blog/list'
  cmd "cp -vr #{$CODE}/e1/views/app/views/blog1 app/views"
  get '/blog1/list'
  cmd "cp -vr #{$CODE}/e1/views/app/views/blog2 app/views"
  get '/blog2/list'
end

section 23.11, 'Adding New Templating Systems' do
  Dir.chdir(File.join($WORK,'view'))
  cmd "cp -v #{$CODE}/e1/views/config/initializers/* config/initializers/"
  cmd "cp -v #{$CODE}/e1/views/lib/*_template.rb lib"
  restart_server
  get '/test/example'
  get '/test/date_format'
  get '/test/example1'
end

section 25.1, 'Sending E-mail' do
  rails 'mailer', :e1
  cmd 'ruby script/generate mailer OrderMailer confirm sent'
  code = "#{$CODE}/e1/mailer"
  cmd "cp -vr #{code}/db/migrate db"
  cmd "cp -v #{code}/app/controllers/* app/controllers"
  cmd "cp -v #{code}/app/models/* app/models"
  cmd "cp -vr #{code}/test ."
  cmd "cp -vr #{code}/app/views/order_mailer app/views"
  restart_server
  cmd 'rake db:migrate'
  get '/test/create_order'
  get '/test/ship_order'
  cmd 'rake test'
end

section 26, 'Active Resources' do
  Dir.chdir(File.join($WORK,'depot'))
  restart_server
  rails 'depot_client'
  edit 'app/models/product.rb' do |data|
    data << <<-EOF.unindent(6)
      class Product < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/'
      end
    EOF
  end
  cmd 'echo "Product.find(2).title" | ruby script/console'
  Dir.chdir(File.join($WORK,'depot'))
  edit "app/controllers/#{$APP}.rb", 'auth' do |data|
    data[/unless.*?\)\n(.*?\n)\s+end/m,1] = <<-EOF
      #START_HIGHLIGHT
      if session[:user_id] != :logged_out
        #START:basic
        authenticate_or_request_with_http_basic('Depot') do |username, password|
          user = User.authenticate(username, password)
          session[:user_id] = user.id if user
        end
        #END:basic
      else
        flash[:notice] = "Please log in"
        redirect_to :controller => 'admin', :action => 'login'
      end
      #END_HIGHLIGHT
    EOF
  end
  edit 'app/controllers/admin_controller.rb' do |data|
    data[/().*session\[:user_id\] = nil/,1] = "#START_HIGHLIGHT\n"
    data[/session\[:user_id\] = nil.*()/,1] = "\n#END_HIGHLIGHT"
    data[/session\[:user_id\] = (nil)/,1] = ':logged_out'
  end
  edit 'app/controllers/line_items_controller.rb', 'create' do |data|
    data[/()  def create/,1] = "#START:create\n"
    data[/def create.*?\n  end()/m,1] = "\n#END:create"
    data[/def create\n()/,1] = <<-EOF.unindent(2)
      #START_HIGHLIGHT
      params[:line_item][:order_id] ||= params[:order_id]
      #END_HIGHLIGHT
    EOF
    data[/:created,() :location/,1] = "\n" + (' ' * 28)
    data[/@line_item.errors,() :status/,1] = "\n" + (' ' * 28)
    data[/@line_item.errors,() :status/,1] = "\n" + (' ' * 28)
  end
  edit 'config/routes.rb' do |data|
    data[/map.resources :orders()/,1] = ', :has_many => :line_items'
  end
  restart_server
  Dir.chdir(File.join($WORK,'depot_client'))
  cmd 'echo "Product.find(2).title" | ruby script/console'
  cmd "echo 'p = Product.find(2)\nputs p.price\np.price-=5\np.save' | " +
      "ruby script/console"
  get '/store'
  edit 'app/models/order.rb' do |data|
    data << <<-EOF.unindent(6)
      class Order < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/'
      end
    EOF
  end
  cmd "echo 'Order.find(1).name\nOrder.find(1).line_items\n' | " +
      "ruby script/console"
  edit 'app/models/line_item.rb' do |data|
    data << <<-EOF.unindent(6)
      class LineItem < ActiveResource::Base
        self.site = 'http://dave:secret@localhost:3000/orders/:order_id'
      end
    EOF
  end
  get '/admin/logout'
  post '/admin/login', 'name' => 'dave', 'password' => 'secret'
  get '/orders/1/line_items.xml'
  cmd 'echo "LineItem.find(:all, :params => {:order_id=>1})" |' + 
      'ruby script/console'
  cmd "echo 'li = LineItem.find(:all, :params => {:order_id=>1}).first\n" +
       "puts li.total_price\nli.total_price*=0.8\nli.save\n" +
       "li2 = LineItem.new(:order_id=>1, :product_id=>2, :quantity=>1, " +
       ":total_price=>0.0)\nli2.save' | ruby script/console"
end

##########################################################################

# The following is under the "I ain't too proud" school of programming.
# global variables, repetition, and brute force abounds.
#
# You have been warned.

require 'fileutils'
require 'open3'
require 'net/http'
require 'rubygems'
require 'builder'
require 'stringio'

# verify that port is available for testing
if (Net::HTTP.get_response('localhost','/',3000).code == '200' rescue false)
  STDERR.puts 'local server already running on port 3000'
  exit
end

$BASE = File.expand_path(File.dirname(__FILE__))
$WORK = File.join($BASE,'work')
$DATA = File.join($BASE,'data')
$CODE = File.join($DATA,'code')
$x = Builder::XmlMarkup.new(:indent => 2)
$toc = Builder::XmlMarkup.new(:indent => 2)
$style = Builder::XmlMarkup.new(:indent => 2)

FileUtils.mkdir_p $WORK

class String
  def unindent(n)
    gsub Regexp.new("^#{' '*n}"), ''
  end
end

def read name
  open(File.join($DATA, name)) {|file| file.read}
end

def log type, message
  type = type.to_s.ljust(5).upcase
  STDOUT.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S] #{type} #{message}")
end

def head number, title
  text = "#{number} #{title}"
  log '====>', text

  $x.a(:class => 'toc', :name => "section-#{number}") {$x.h2 text}
  $toc.li {$toc.a text, :href => "#section-#{number}"}
end

def db statement, hilight=[]
  log :db, statement
  $x.pre "sqlite3> #{statement}", :class=>'stdin'
  cmd = "sqlite3 --line db/development.sqlite3 #{statement.inspect}"
  popen3 cmd, hilight
end

def cmd args, hilight=[]
  log :cmd, args
  $x.pre args, :class=>'stdin'
  if args == 'rake db:migrate'
    Dir.chdir 'db/migrate' do
      date = '20080601000000'
      Dir['[0-9]*'].sort_by {|file| file=~/2008/?file:'x'+file}.each do |file|
        file =~ /^([0-9]*)_(.*)$/
        FileUtils.mv file, "#{date}_#{$2}" unless $1 == date.next!
        $x.pre "mv #{file} #{date}_#{$2}"  unless $1 == date
      end
    end
  end
  popen3 args, hilight
end

def popen3 args, hilight=[]
  Open3.popen3(args) do |pin, pout, perr|
    terr = Thread.new do
      $x.pre perr.readline.chomp, :class=>'stderr' until perr.eof?
    end
    pin.close
    until pout.eof?
      line = pout.readline
      if hilight.any? {|pattern| line.include? pattern}
        $x.pre line.chomp, :class=>'hilight'
      elsif line.strip.size == 0
        $x.pre ' ', :class=>'stdout'
      else
        $x.pre line.chomp, :class=>'stdout'
      end
    end
    terr.join
  end
end

def irb file
  $x.pre "irb #{file}", :class=>'stdin'
  log :irb, file
  cmd = "irb -r rubygems --prompt-mode simple #{$CODE}/#{file}"
  Open3.popen3(cmd) do |pin, pout, perr|
    terr = Thread.new do
      $x.pre perr.readline.chomp, :class=>'stderr' until perr.eof?
    end
    pin.close
    prompt = nil
    until pout.eof?
      line = pout.readline
      if line =~ /^([?>]>)\s*#\s*(START|END):/
        prompt = $1
      elsif line =~ /^([?>]>)\s+$/
        $x.pre ' ', :class=>'irb'
        prompt ||= $1
      elsif line =~ /^([?>]>)(.*)\n/
        prompt ||= $1
        $x.pre prompt + $2, :class=>'irb'
	prompt = nil
      elsif line =~ /^\w+(::\w+)*: /
        $x.pre line.chomp, :class=>'stderr'
      elsif line =~ /^\s+from [\/.:].*:\d+:in `\w.*'\s*$/
        $x.pre line.chomp, :class=>'stderr'
      elsif line =~ /\x1b\[\d/
        line.gsub! /\x1b\[4(;\d+)*m(.*?)\x1b\[0m/, '\2'
        line.gsub! /\x1b\[0(;\d+)*m(.*?)\x1b\[0m/, '\2'
        $x.pre line.chomp, :class=>'logger'
      else
        $x.pre line.chomp, :class=>'stdout'
      end
    end
    terr.join
  end
end

def edit filename, tag=nil
  log :edit, filename
  $x.pre "edit #{filename}", :class=>'stdin'

  stale = File.mtime(filename) rescue Time.now-2
  data = open(filename) {|file| file.read} rescue ''
  before = data.split("\n")

  begin
    yield data
    open(filename,'w') {|file| file.write data}
    File.utime(stale+2, stale+2, filename) if File.mtime(filename) <= stale

  rescue Exception => e
    $x.pre :class => 'traceback' do
      STDERR.puts e.inspect
      $x.text! "#{e.inspect}\n"
      e.backtrace.each {|line| $x.text! "  #{line}\n"}
    end
    tag = nil

  ensure
    include = tag.nil?
    hilight = false
    data.split("\n").each do |line|
      if line =~ /START:(\w+)/
        include = true if $1 == tag
      elsif line =~ /END:(\w+)/
        include = false if $1 == tag
      elsif line =~ /START_HIGHLIGHT/
        hilight = true
      elsif line =~ /END_HIGHLIGHT/
        hilight = false
      elsif include
        if hilight or ! before.include?(line)
          $x.pre line, :class=>'hilight'
        elsif line.empty?
          $x.pre ' ', :class=>'stdout'
        else
          $x.pre line, :class=>'stdout'
        end
      end
    end
  end
end

# pluggable XML parser support
begin
  raise LoadError if ARGV.include? 'rexml'
  require 'nokogiri'
  def xhtmlparse(text)
    Nokogiri::HTML(text)
  end
  Comment=Nokogiri::XML::Comment
rescue LoadError
  require 'rexml/document'

  def xhtmlparse(text)
    REXML::Document.new(text)
  end

  class REXML::Element
    def has_attribute? name
      self.attributes.has_key? name
    end

    def at xpath
      self.elements[xpath]
    end

    def search xpath
      self.elements.to_a(xpath)
    end

    def content=(string)
      self.text=string
    end

    def [](index)
      if index.instance_of? String
        self.attributes[index]
      else
        super(index)
      end
    end

    def []=(index, value)
      if index.instance_of? String
        self.attributes[index] = value
      else
        super(index, value)
      end
    end
  end

  module REXML::Node
    def before(node)
      self.parent.insert_before(self, node)
    end

    def serialize
      self.to_s
    end
  end

  # monkey patch for Ruby 1.8.6
  doc = REXML::Document.new '<doc xmlns="ns"><item name="foo"/></doc>'
  if not doc.root.elements["item[@name='foo']"]
    class REXML::Element
      def attribute( name, namespace=nil )
        prefix = nil
        prefix = namespaces.index(namespace) if namespace
        prefix = nil if prefix == 'xmlns'
        attributes.get_attribute( "#{prefix ? prefix + ':' : ''}#{name}" )
      end
    end
  end

  Comment = REXML::Comment
end

def snap response, form={}
  if response.content_type == 'text/plain' or response.content_type =~ /xml/ or
     response.code == '500'
    $x.div :class => 'body' do
      response.body.split("\n").each do |line| 
        $x.pre line.chomp, :class=>'stdout'
      end
    end
    return
  end

  if response.body =~ /<body/
    body = response.body
  else
    body = "<body>#{response.body}</body>"
  end

  begin
    doc = xhtmlparse(body)
  rescue
    body.split("\n").each {|line| $x.pre line.chomp, :class=>'hilight'}
    raise
  end

  title = doc.at('html/head/title').text rescue ''
  body = doc.at('//body')
  doc.search('//link[@rel="stylesheet"]').each do |sheet|
    body.children.first.before(sheet)
  end

  if ! form.empty?
    body.search('//input[@name]').each do |input|
      input['value'] ||= form[input['name']].to_s
    end
    body.search('//textarea[@name]').each do |textarea|
      textarea.text ||= form[textarea['name']].to_s
    end
  end

  %w{ a[@href] form[@action] }.each do |xpath|
    name = xpath[/@(\w+)/,1]
    body.search("//#{xpath}").each do |element|
      next if element[name] =~ /^http:\/\//
      element[name] = URI.join('http://localhost:3000/', element[name]).to_s
    end
  end

  %w{ img[@src] }.each do |xpath|
    name = xpath[/@(\w+)/,1]
    body.search("//#{xpath}").each do |element|
      if element[name][0] == ?/
        element[name] = 'data' + element[name]
      end
    end
  end

  body.search('//textarea').each do |element|
    element.content=''
  end

  attrs = {:class => 'body', :title => title}
  attrs[:id] = body['id'] if body['id']
  $x.div(attrs) do
    body.children.each do |child|
      $x << child.serialize unless child.instance_of?(Comment)
    end
  end
  $x.div :style => "clear: both"
end

def get path
  post path, {}
end

def post path, form
  $x.pre "get #{path}", :class=>'stdin'
  Net::HTTP.start('127.0.0.1', 3000) do |http|
    get = Net::HTTP::Get.new(path)
    get['Cookie'] = $COOKIE if $COOKIE
    response = http.request(get)
    snap response, form
    $COOKIE = response.response['set-cookie'] if response.response['set-cookie']

    if ! form.empty?
      body = xhtmlparse(response.body).at('//body')
      body = xhtmlparse(response.body).root unless body
      xform = body.at('//form[.//input[@name="commit"]]')
      return unless xform
      path = xform.attribute('action').to_s unless
        xform.attribute('action').to_s.empty?
      $x.pre "post #{path}", :class=>'stdin'

      $x.ul do
        form.each do |name, value|
          $x.li "#{name} => #{value}"
        end
      end

      body.search('//input[@type="hidden"]').each do |element|
        form[element['name']] ||= element['value']
      end

      post = Net::HTTP::Post.new(path)
      post.form_data = form
      post['Cookie'] = $COOKIE
      response=http.request(post)
      snap response
    end

    if response.code == '302'
      path = response['Location']
      $x.pre "get #{path}", :class=>'stdin'
      get = Net::HTTP::Get.new(path)
      get['Cookie'] = $COOKIE if $COOKIE
      response = http.request(get)
      snap response
    end
  end
end

# select a version of Rails
if ARGV.first =~ /^_\d[.\d]*_$/
  $rails = "rails #{ARGV.first}"
elsif File.directory?(ARGV.first.to_s)
  $rails = ARGV.first
  $rails = File.join($rails,'rails') if
    File.directory?(File.join($rails,'rails'))
  $rails = File.expand_path($rails)
else
  $rails = 'rails'
end

def which_rails rails
  railties = File.join(rails, 'railties', 'bin', 'rails')
  rails = railties if File.exists?(railties)
  if File.exists?(rails)
    firstline = open(rails) {|file| file.readlines.first}
    rails = "ruby " + rails unless firstline =~ /^#!/
  end
  rails
end

def rails name, app=nil
  Dir.chdir($WORK)
  FileUtils.rm_rf name
  log :rails, name

  # determine how to invoke rails
  rails = which_rails $rails

  $x.pre "#{rails} #{name}", :class=>'stdin'
  popen3 "#{rails} #{name}"

  # make paths seem Mac OSX'ish
  Dir["#{name}/public/dispatch.*"].each do |dispatch|
    code = open(dispatch) {|file| file.read}
    code.sub! /^#!.*/, '#!/opt/local/bin/ruby'
    open(dispatch,'w') {|file| file.write code}
  end

  Dir.chdir(name)
  FileUtils.rm_rf 'public/.htaccess'

  cmd 'rake rails:freeze:edge' if ARGV.include? 'edge'

  if $rails != 'rails' and File.directory?($rails)
    cmd "ln -s #{$rails} vendor/rails"
  end
end

def restart_server
  log :server, 'restart'
  $x.h3 'restart'
  if $server
    Process.kill "INT", $server
    Process.wait($server)
  end

  $server = fork
  if $server
    # wait for server to start
    60.times do
      sleep 0.5
      begin
        break if Net::HTTP.get_response('localhost','/',3000).code == '200'
      rescue Errno::ECONNREFUSED
      end
    end
  else
    begin
      # start server, redirecting stdout to a string
      $stdout = StringIO.open('','w')
      require 'config/boot'
      require 'commands/server'
    rescue 
      STDERR.puts $!
      $!.backtrace.each {|method| STDERR.puts "\tfrom " + method}
    ensure
      Process.exit!
    end
  end
end

def secsplit section
  section.to_s.split('.').map {|n| n.to_i}
end

$x.html :xmlns => 'http://www.w3.org/1999/xhtml' do
  $x.header do
    $x.title 'The Depot Application'
    $x.meta 'http-equiv'=>'text/html; charset=UTF-8'
    $x.style :type => "text/css" do
      $x.text! <<-'EOF'.unindent(2)
        body {background-color: #F5F5DC}
        pre {font-weight: bold; margin: 0; padding: 0}
        pre.stdin {color: #800080; margin-top: 1em; padding: 0}
        pre.irb {color: #800080; padding: 0}
        pre.stdout {color: #000; padding: 0}
        pre.logger {color: #088; padding: 0}
        pre.hilight {color: #000; background-color: #FF0; padding: 0}
        pre.stderr {color: #F00; padding: 0}
        div.body {border-style: solid; border-color: #800080; padding: 0.5em}
        pre.traceback {background:#FDD; border: 4px solid #F00; 
                       font-weight: bold; margin-top: 1em; padding: 0.5em}
        ul.toc {list-style: none}
        ul a {text-decoration: none}
        ul a:hover {text-decoration: underline; color: #000;
                    background-color: #F5F5DC}
        ul a:visited {color: #000}
	h2 {clear: both}
      EOF
    end
  end

  $x.body do
    $x.h1 'The Depot Application'
    $x.h2 'Table of Contents'
    $x.ul :class => 'toc'

    $x.h2 'Development Log'
    cmd which_rails($rails) + ' -v'
    $R22 = (`#{which_rails($rails)} -v` =~ /^Rails 2\.2/)
    $APP = $R22 ? 'application' : 'application_controller'

    cmd 'ruby -v'
    cmd 'gem -v'
  
    e = nil

    # determine which range(s) of steps are to be executed
    ranges = ARGV.grep(/^ \d+(.\d+)? ( (-|\.\.) \d+(.\d+)? )? /x).map do |arg|
      bounds = arg.split(/-|\.\./)
      Range.new(secsplit(bounds.first), secsplit(bounds.last))
    end
    ARGV.push 'partial' unless ranges.empty?

    # optionally save a snapshot
    if ARGV.include? 'restore'
      log :snap, 'restore'
      Dir.chdir $BASE
      FileUtils.rm_rf "work"
      FileUtils.cp_r "snapshot", "work", :preserve => true
      Dir.chdir $WORK
      if File.directory? 'depot'
        Dir.chdir 'depot'
        restart_server
      end
    end

    # run steps
    begin
      $sections.each do |section, title, steps|
	next if !ranges.empty? and 
                !ranges.any? {|range| range.include?(secsplit(section))}
	head section, title
	steps.call
      end
    rescue Exception => e
      $x.pre :class => 'traceback' do
	STDERR.puts e.inspect
	$x.text! "#{e.inspect}\n"
	e.backtrace.each {|line| $x.text! "  #{line}\n"}
      end
    ensure
      if e.class != SystemExit
	# switch back to depot (if necessary)
	if Dir.pwd != File.join($WORK,'depot') or !$server
	  Dir.chdir(File.join($WORK,'depot'))
	  restart_server
	end

	# fetch stylesheets
	begin
	  Net::HTTP.start('127.0.0.1', 3000) do |http|
	    $style.text! http.get('/stylesheets/scaffold.css').body
	    $style.text! http.get('/stylesheets/depot.css').body
	  end
        rescue
        end

        # terminate server
	Process.kill "INT", $server
	Process.wait($server)

        # optionally save a snapshot
        if ARGV.include? 'save'
          log :snap, 'save'
          Dir.chdir $BASE
          FileUtils.rm_rf "snapshot"
          FileUtils.cp_r "work", "snapshot", :preserve => true
        end
      end
    end
  end
end

# output results as HTML, after inserting style and toc information
$x.target![/<style.*?>()/,1] = "\n#{$style.target!.strip.gsub(/^/,' '*6)}\n"
$x.target!.sub! /<ul(.*?)\/>/,
  "<ul\\1>\n#{$toc.target!.gsub(/^/,' '*6)}    </ul>"
$x.target!.gsub! '<strong/>', '<strong></strong>'
log :WRITE, 'makedepot.html'
open("#{$BASE}/makedepot.html",'w') do |file| 
  file.write <<-EOF.unindent(4)
    <!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  EOF
  file.write $x.target!
end

# run tests
log :CHECK, 'makedepot.html'
Dir.chdir $BASE
STDOUT.puts
require 'checkdepot'

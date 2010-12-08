class Cart
  attr_reader :items   # <wtf linkend="wtf.attr.accessor">attr_reader</wtf>
  
  def initialize
    @items = []
  end
  
  def add_product(product)
    @items << product
  end
end

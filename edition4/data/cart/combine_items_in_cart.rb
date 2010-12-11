class CombineItemsInCart < ActiveRecord::Migration

#START:up
  def self.up
    # replace multiple items for a single product in a cart with a single item
    Cart.all.each do |cart|
      # count the number of each product in the cart
      sums = cart.line_items.group(:product_id).sum(:quantity)

      sums.each do |product_id, quantity|
        if quantity > 1
          # remove individual items
          cart.line_items.where(:product_id=>product_id).delete_all

          # replace with a single item
          cart.line_items.create(:product_id=>product_id, :quantity=>quantity)
        end
      end
    end
  end
#END:up

#START:down
  def self.down
    # split items with quantity>1 into multiple items
    LineItem.where("quantity>1").each do |lineitem|
      # add individual items
      lineitem.quantity.times do 
        LineItem.create :cart_id=>lineitem.cart_id,
          :product_id=>lineitem.product_id, :quantity=>1
      end

      # remove original item
      lineitem.destroy
    end
  end
#END:down
end

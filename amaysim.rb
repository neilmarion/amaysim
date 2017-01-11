class ShoppingCart
  attr :items, :promo_codes, :pricing_rules, :total_price, :promo_items

  def initialize(pricing_rules)
    @items = []
    @promo_codes = []
    @promo_items = []
    @pricing_rules = pricing_rules
    @result = {items: [], total_price: 0.00, promo_items: @promo_items}
    @total_price = 0.00
  end

  def add_item(item)
    @items << item
    apply_pricing_rules
  end

  def add_promo_code(promo_code)
    @promo_codes << promo_code
    apply_pricing_rules
  end

  def total_items
    [@items, @promo_items].flatten
  end

  def total_price
    @total_price.round(2)
  end

  private

  def apply_pricing_rules
    @total_price = 0
    @result[:promo_items] = []
    @pricing_rules.each do |pricing_rule|
      @result = pricing_rule.apply(self, @result)
      @promo_items = @result[:promo_items]
      @total_price = @total_price + @result[:total_price]
      @result[:total_price] = 0
    end
  end
end

class PricingRule
  attr :shopping_cart, :rule, :result

  def initialize(rule)
    @rule = rule
  end

  def apply(shopping_cart, result)
    rule.call(shopping_cart, result)
    result
  end
end

class PricingRulesDefinition
  def self.rules
    x_for_y_deal_rule = Proc.new do |shopping_cart, result|
           ult_small_products = shopping_cart.items.select{|item| item.code == "ult_small" }
           result[:total_price] = ult_small_products.inject(0){|sum,e| sum + e.price }
           result[:total_price] = result[:total_price] - (ult_small_products.count / 3) * 24.9

           result[:total_price] = result[:total_price].round(2)
         end

    bulk_5gb_sim_rule = Proc.new do |shopping_cart, result|
          counter = 0
          shopping_cart.items.select{|item| item.code == "ult_large" }.each do |item|
            if item.code == "ult_large"
               counter = counter + 1
             end

            result[:items] << item
            result[:total_price] = result[:total_price] + item.price
             if counter == 5
               result[:total_price] = result[:total_price] - (item.price * 5)
               result[:total_price] = result[:total_price] + (39.9 * 5)
               counter = 0
             end
           end
           result[:total_price] = result[:total_price].round(2)
         end
    free_sim_rule = Proc.new do |shopping_cart, result|
          shopping_cart.items.select{|item| item.code == "ult_medium" }.each do |item|
            result[:promo_items] << Product.new("ult_small", "Unlimited 1GB", 24.90)
            result[:items] << item  
            result[:total_price] = result[:total_price] + item.price
            result[:total_price] = result[:total_price].round(2)
         end
    end

    promo_code_rule = Proc.new do |shopping_cart, result|
          if shopping_cart.promo_codes.include? "I<3AMAYSIM"
            sum = shopping_cart.items.inject(0){|sum,e| sum + e.price }
            #sum = shopping_cart.items.sum(&:price)
            result[:total_price] = sum * 0.90
            result[:total_price] = result[:total_price].round(2)
         end
    end

    [
      PricingRule.new(x_for_y_deal_rule),
      PricingRule.new(bulk_5gb_sim_rule),
      PricingRule.new(free_sim_rule),
      PricingRule.new(promo_code_rule)
    ]
  end
end

class Product
  attr :code, :name, :price

  def initialize(code, name, price)
    @code = code
    @name = name
    @price = price
  end
end

# Testing (Specs)

class ShoppingCartSpec
  # NOTE: Only testing the golden path. I spared testing of individual 
  # units such as testing the validation of the PricingRules class.

  def init_pricing_rules
    @pricing_rules = PricingRulesDefinition.rules
  end

  def init_products
    @ult_small = Product.new("ult_small", "Unlimited 1GB", 24.90)
    @ult_medium = Product.new("ult_medium", "Unlimited 2GB", 29.90)
    @ult_large = Product.new("ult_large", "Unlimited 5GB", 44.90)
    @one_gb = Product.new("1gb", "1 GB Data-pack", 9.90)
  end

  def execute
    init_pricing_rules
    init_products

    test_1
    test_2
    test_3
    test_4
    test_5
  end

  def test_1
    puts "3 x Unlimited 1 GB + 1 Unlimited 5 GB"
    shopping_cart = ShoppingCart.new(@pricing_rules)

    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_large)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_large_products = shopping_cart.total_items.select{|item| item.code == @ult_large.code }

    puts ult_small_products.count == 3
    puts ult_large_products.count == 1
    puts shopping_cart.total_price
    puts shopping_cart.total_price == 94.7
  end

  def test_2
    puts "2 x Unlimited 1 GB + 4 x Unlimited 5 GB"
    shopping_cart = ShoppingCart.new(@pricing_rules)

    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_large_products = shopping_cart.total_items.select{|item| item.code == @ult_large.code }

    puts ult_small_products.count == 2
    puts ult_large_products.count == 4
    puts shopping_cart.total_price
    puts shopping_cart.total_price == 229.4

  end

  def test_3
    puts "1 x Unlimited 1 GB + 2 x Unlimited 2 GB"

    shopping_cart = ShoppingCart.new(@pricing_rules)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_medium)
    shopping_cart.add_item(@ult_medium)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_medium_products = shopping_cart.total_items.select{|item| item.code == @ult_medium.code }
    puts ult_small_products.count == 3

    puts ult_medium_products.count == 2
    puts shopping_cart.total_price == 84.7
  end

  def test_4
    puts "1 x Unlimited 1 GB + 1 x 1 GB Data-pack with promo code"

    shopping_cart = ShoppingCart.new(@pricing_rules)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@one_gb)
    shopping_cart.add_promo_code("I<3AMAYSIM")

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_one_gb_products = shopping_cart.total_items.select{|item| item.code == @one_gb.code }
    puts ult_small_products.count == 1
    puts ult_one_gb_products.count == 1
    puts shopping_cart.total_price
    puts shopping_cart.total_price == 31.32
  end

  def test_5
    puts "2 x Unlimited 1 GB + 4 x Unlimited 5 GB"
    shopping_cart = ShoppingCart.new(@pricing_rules)

    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)
    shopping_cart.add_item(@ult_large)

    ult_small_products = shopping_cart.items.select{|item| item.code == @ult_small.code }
    ult_large_products = shopping_cart.items.select{|item| item.code == @ult_large.code }
    puts ult_small_products.count == 2

    puts ult_large_products.count == 5
    puts shopping_cart.total_price == 249.3

  end
end

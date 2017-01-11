# Usage:
# 1. Define first your products - check line 178
# 2. Define pricing rules - check line 76
# 3. Init your ShoppingCart i.e. sc = ShoppingCart.new(pricing_rules)
# 4. Adding items - sc.add_item(<Product> product)
# 5. Adding promo codes - sc.add_promo_code(<Product> product)
# 6. Getting the total price - sc.total_price
# 7. Getting the expected items - sc.items
#
# NOTE: A little deviation on the exam specifications on naming the methods
# on adding items, adding promo codes and getting the items from the cart
#
# Sorry I have to put everything in one file. Got no time to install ruby in
# my brother's laptop. ;)
#
# Running this file will run the simple tests/specs

class ShoppingCart
  attr :items, :promo_codes, :pricing_rules, :total_price, :promo_items

  def initialize(pricing_rules)
    @items = []
    @promo_codes = []
    @promo_items = []
    @pricing_rules = pricing_rules
    @result = {
      items: [],
      total_price: 0.00,
      promo_items: @promo_items
    }
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

  def update_total_price(total_price)
    @total_price = total_price
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
    # put rules in one class for convenience

    # here we define the rules for non-promo items i.e. items not involved in any promo
    non_promo_items_rule = Proc.new do |shopping_cart, result|
      non_promo_items = shopping_cart.items.select do |item|
        item.code != "ult_small" && item.code != "ult_medium" && item.code != "ult_large"
      end

      result[:total_price] = non_promo_items.inject(0){|sum,item| sum + item.price }
    end

    # here we define the rules for the "ult_small" sims
    x_for_y_deal_rule = Proc.new do |shopping_cart, result|
      ult_small_products = shopping_cart.items.select do |item|
        item.code == "ult_small"
      end

      result[:total_price] = ult_small_products.inject(0){|sum,e| sum + e.price }
      result[:total_price] = (result[:total_price] - (ult_small_products.count / 3) * 24.9).round(2)
    end

    # here we defined the rules for the "ult_large" sims
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

    # here we define the rules for "ult_medium" sims where
    # there is a free "one_gb" sim for every "ult_medium"
    free_sim_rule = Proc.new do |shopping_cart, result|
      shopping_cart.items.select{|item| item.code == "ult_medium" }.each do |item|
        result[:promo_items] << Product.new("1gb", "1 GB Data-pack", 9.90)
        result[:items] << item
        result[:total_price] = result[:total_price] + item.price
        result[:total_price] = result[:total_price].round(2)
      end
    end

    # here we define the 10% less promo code
    # NOTE: accross-the-board discount promo rules must be at the end of the pricing rules list
    promo_code_rule = Proc.new do |shopping_cart, result|
      if shopping_cart.promo_codes.include? "I<3AMAYSIM"
        shopping_cart.update_total_price(shopping_cart.total_price * 0.90)
      end
    end

    [
      PricingRule.new(non_promo_items_rule),
      PricingRule.new(x_for_y_deal_rule),
      PricingRule.new(bulk_5gb_sim_rule),
      PricingRule.new(free_sim_rule),
      PricingRule.new(promo_code_rule),
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

# Unit testing starts here!

# Simple Testing for TDD (Specs)
# A printed "true" means specs passed, otherwise failed

class ShoppingCartSpec
  # NOTE: This is only testing the golden path. I spared testing of individual
  # units such as testing the validation of the PricingRules class or the
  # Product class etc

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
    test_6
  end

  def test_1
    puts "1) 3 x Unlimited 1 GB + 1 Unlimited 5 GB"
    shopping_cart = ShoppingCart.new(@pricing_rules)

    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_large)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_large_products = shopping_cart.total_items.select{|item| item.code == @ult_large.code }

    puts ult_small_products.count == 3
    puts ult_large_products.count == 1
    puts shopping_cart.total_price == 94.7
  end

  def test_2
    puts "2) 2 x Unlimited 1 GB + 4 x Unlimited 5 GB"
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
    puts shopping_cart.total_price == 229.4
  end

  def test_3
    puts "3) 1 x Unlimited 1 GB + 2 x Unlimited 2 GB"

    shopping_cart = ShoppingCart.new(@pricing_rules)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_medium)
    shopping_cart.add_item(@ult_medium)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_medium_products = shopping_cart.total_items.select{|item| item.code == @ult_medium.code }
    ult_one_gb_products = shopping_cart.total_items.select{|item| item.code == @one_gb.code }

    puts ult_small_products.count == 1
    puts ult_medium_products.count == 2
    puts ult_one_gb_products.count == 2
    puts shopping_cart.total_price == 84.7
  end

  def test_4
    puts "4) 1 x Unlimited 1 GB + 1 x 1 GB Data-pack with promo code"

    shopping_cart = ShoppingCart.new(@pricing_rules)
    shopping_cart.add_promo_code("I<3AMAYSIM")
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@one_gb)

    ult_small_products = shopping_cart.total_items.select{|item| item.code == @ult_small.code }
    ult_one_gb_products = shopping_cart.total_items.select{|item| item.code == @one_gb.code }
    puts ult_small_products.count == 1
    puts ult_one_gb_products.count == 1
    puts shopping_cart.total_price == 31.32
  end

  def test_5
    puts "5) 2 x Unlimited 1 GB + 4 x Unlimited 5 GB"
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

  def test_6
    puts "6) 4 x Unlimited 1 GB + 2 x Unlimited 2 GB"
    shopping_cart = ShoppingCart.new(@pricing_rules)

    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_small)
    shopping_cart.add_item(@ult_medium)
    shopping_cart.add_item(@ult_medium)

    ult_small_products = shopping_cart.items.select{|item| item.code == @ult_small.code }
    ult_one_gb_products = shopping_cart.total_items.select{|item| item.code == @one_gb.code }
    ult_medium_products = shopping_cart.total_items.select{|item| item.code == @ult_medium.code }

    puts ult_small_products.count == 4
    puts ult_one_gb_products.count == 2
    puts ult_medium_products.count == 2

    puts shopping_cart.total_price == 134.5

  end
end

# run the tests
ShoppingCartSpec.new.execute

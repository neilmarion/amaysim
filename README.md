## How to run this?

# Setup the env

1. Go to [this online ruby interpreter](https://repl.it/FFm6/6)
2. Click on "run" and wait for the specs to finish
3. Initialize the products. Copy-paste this code into the interpreter's command-line interface:
```
  ult_small = Product.new("ult_small", "Unlimited 1GB", 24.90)
  ult_medium = Product.new("ult_medium", "Unlimited 2GB", 29.90)
  ult_large = Product.new("ult_large", "Unlimited 5GB", 44.90)
  one_gb = Product.new("1gb", "1 GB Data-pack", 9.90)
```
4) Initialize the shopping cart. Copy-paste this as well.
```
  shopping_cart = ShoppingCart.new(PricingRulesDefinition.rules)
```

# Usage

1) Add items
```
  shopping_cart.add_item(ult_small)
```
2 Add promo - This must be done after all the items are added.
```
  shopping_cart.promo_code("I<3AMAYSIM")
```
3) Get total price
```
  shopping_cart.total_price
```
4) Get total items
```
  shopping_cart.total_items
```
5) Get total summary - Prints a readable summary of the shopping cart # can be improved further though
```
  shopping_cart.summary
```

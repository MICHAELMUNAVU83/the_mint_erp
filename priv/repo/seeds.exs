alias TheMint.{Accounts, Products}

for user <- [
      %{email: "admin@gmail.com", password: "password", name: "Admin", role: "admin"},
      %{email: "cashier@gmail.com", password: "password", name: "Cashier", role: "cashier"}
    ],
    is_nil(Accounts.get_user_by_email(user.email)) do
  {:ok, _} = Accounts.create_user(user)
end

IO.puts("✓ Users: admin@gmail.com / password, cashier@gmail.com / password")

products =
  [
    {"Gin",
     [
       {"Gilbey's 750ml", "3500"},
       {"Gordon's Clear 750ml", "4500"},
       {"Gordon's Pink 750ml", "4500"},
       {"Tanqueray Dry 750ml", "5000"},
       {"Tanqueray Sevilla 700ml", "5000"},
       {"Tanqueray No 10 750ml", "6500"}
     ]},
    {"Tequila",
     [
       {"Jose Cuervo Gold 750ml", "5000"},
       {"Jose Cuervo Silver 750ml", "5000"},
       {"Don Julio Blanco 750ml", "12500"},
       {"Don Julio Reposado 750ml", "13000"},
       {"Don Julio Anejo 750ml", "14500"}
     ]},
    {"Whisky",
     [
       {"Jameson 750ml", "5000"},
       {"Jameson Black Barrel 750ml", "7000"},
       {"Johnnie Walker Red 750ml", "4000"},
       {"Johnnie Walker Black 750ml", "6500"},
       {"Johnnie Walker Double Black 750ml", "8000"},
       {"Johnnie Walker Green 750ml", "10000"},
       {"Johnnie Walker Gold 750ml", "11000"},
       {"Johnnie Walker 18yr 750ml", "15000"},
       {"Jack Daniel's 750ml", "6000"},
       {"Singleton 12yr 750ml", "8500"},
       {"Singleton 15yr 750ml", "10000"},
       {"Singleton 18yr 750ml", "12500"},
       {"Glenfiddich 12yr 750ml", "12500"},
       {"Glenfiddich 15yr 750ml", "15000"},
       {"Glenlivet 12yr 750ml", "12000"},
       {"Glenlivet 15yr 750ml", "15000"}
     ]},
    {"Cognac",
     [
       {"Hennessy VS 750ml", "10000"},
       {"Hennessy VSOP 1L", "19500"},
       {"Martell VS 750ml", "9000"},
       {"Martell VSOP 750ml", "15000"},
       {"Martell Blue Swift 700ml", "15000"}
     ]},
    {"Vodka", [{"Smirnoff Red 750ml", "3500"}, {"Absolut 750ml", "3500"}]},
    {"Rum",
     [
       {"Captain Morgan Spiced 750ml", "4000"},
       {"Captain Morgan Gold 750ml", "3500"}
     ]},
    {"Liqueur", [{"Jagermeister 700ml", "5500"}]},
    {"Local Spirits",
     [
       {"KC Lemon & Ginger 750ml", "3000"},
       {"KC Pineapple 750ml", "3000"},
       {"KC Smooth 750ml", "3000"}
     ]},
    {"Soju",
     [
       {"Jinro Strawberry 360ml Bottle", "800"},
       {"Jinro Green Grape 360ml Bottle", "800"},
       {"Jinro Grapefruit 360ml Bottle", "800"},
       {"Jinro Lemon 360ml Bottle", "800"},
       {"Jinro Peach 360ml Bottle", "800"},
       {"Jinro Lychee 360ml Bottle", "800"},
       {"Jinro Plum 360ml Bottle", "800"},
       {"Jinro Blueberry 360ml Bottle", "800"},
       {"Jinro Watermelon 360ml Bottle", "800"},
       {"Jinro Chamisul 360ml Bottle", "800"}
     ]},
    {"Beer",
     [
       {"Tusker Lager 500ml Can", "400"},
       {"Tusker Lite 500ml Can", "400"},
       {"White Cap 500ml Can", "400"},
       {"Balozi 500ml Can", "400"},
       {"Pilsner 500ml Can", "400"},
       {"Tusker Malt 500ml Can", "400"},
       {"Heineken 500ml Can", "400"},
       {"Guinness 500ml Can", "400"}
     ]},
    {"Ciders",
     [
       {"Tusker Cider 500ml Can", "400"},
       {"Smirnoff Guarana 330ml Can", "400"},
       {"Smirnoff Pineapple Punch 330ml Can", "400"},
       {"Smirnoff Black Ice 330ml Can", "400"},
       {"Gordon's Dry & Tonic 330ml Can", "400"},
       {"Gordon's Pink & Tonic 330ml Can", "400"},
       {"Manyatta Pineapple & Mint 330ml Can", "400"},
       {"Kenyan Original 330ml Bottle", "400"},
       {"Hunters Dry 330ml Bottle", "400"},
       {"Hunters Gold 330ml Bottle", "400"},
       {"Savanna 330ml Bottle", "400"}
     ]},
    {"Soft drinks",
     [
       {"Coca-Cola 500ml", "200"},
       {"Sprite 500ml", "200"},
       {"Delmonte Apple 1L", "500"},
       {"Delmonte Mixed Berries 1L", "500"},
       {"Minute Maid Apple", "400"},
       {"Minute Maid Tropical", "400"},
       {"Red Bull", "400"},
       {"Sparkling Water", "300"},
       {"Still Water", "200"},
       {"Schweppes Tonic Water", "200"},
       {"Schweppes Soda Water", "200"},
       {"Monstor Energy", "400"}
     ]},
    {"Jaba Juice",
     [
       {"Jaba Juice - Passion Mojito", "1000"},
       {"Jaba Juice - Pineapple Mint", "1000"},
       {"Jaba Juice - Cocktail", "1000"}
     ]},
    {"Tobacco", [{"Dunhill Double Switch", "600"}, {"Dunhill Single Switch", "600"}]},
    {"Shots",
     [
       {"Jose Cuervo Silver", "500"},
       {"Jose Cuervo Gold", "500"},
       {"Don Julio Reposado", "600"},
       {"Johnnie Walker Black", "500"},
       {"Jameson", "400"},
       {"Smirnoff Vodka", "400"},
       {"Gilbey's", "350"},
       {"Jagermeister", "500"}
     ]},
    {"Cocktails",
     [
       {"Elgon Honey Sour - Whisky Based", "1000"},
       {"Vihiga Hills Fizz - Vodka Based", "900"},
       {"Bull Fighter - KC Based", "800"},
       {"Mumias Mojito - Rum Based", "800"},
       {"Lakeside Fizz - Gin Based", "900"},
       {"Western Sunset - Tequila Based", "1100"},
       {"Mulembe Long Island - Gin, Tequila, Vodka, Rum", "1300"}
     ]},
    {"Mocktails",
     [
       {"Kakamega Sunset", "500"},
       {"Virgin Mojito", "400"},
       {"Island Splash", "500"}
     ]},
    {"Wine",
     [
       {"Rosso Nobile Cioccolata", "3000"},
       {"Rosso Vaniglia Bianco Nobile", "3000"},
       {"Nederburg Cabernet Sauv Red", "3000"},
       {"Nederburg Pinotage", "3000"},
       {"Nederburg Saug Blanc White", "3000"}
     ]}
  ]
  |> Enum.flat_map(fn {category, items} ->
    Enum.map(items, fn {name, price} -> {category, name, price} end)
  end)

existing_products = Products.list_products() |> Map.new(&{&1.sku, &1})

products
|> Enum.with_index(1)
|> Enum.each(fn {{category, name, price}, index} ->
  sku = "MENU-" <> String.pad_leading(Integer.to_string(index), 3, "0")

  attrs = %{
    name: name,
    sku: sku,
    category: category,
    buying_price: "0",
    price: price,
    stock_quantity: 0
  }

  result =
    case existing_products[sku] do
      nil -> Products.create_product(attrs)
      product -> Products.update_product(product, attrs)
    end

  {:ok, _} = result
end)

IO.puts("✓ #{length(products)} products")

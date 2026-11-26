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
    {"Beer",
     [
       {"Tusker Lager 500ml can", "450"},
       {"Tusker Lite 500ml can", "450"},
       {"Tusker Malt 500ml can", "450"},
       {"White Cap Lager 500ml can", "450"},
       {"Guinness 500ml can", "450"},
       {"Balozi 500ml can", "450"},
       {"Pilsner 500ml can", "450"}
     ]},
    {"Cider & RTDs",
     [
       {"Tusker Cider 500ml can", "450"},
       {"Smirnoff Ice Guarana 330ml can", "400"},
       {"Smirnoff Pineapple Punch 330ml can", "400"},
       {"Smirnoff Black Ice 330ml can", "400"},
       {"Gordon's Dry & Tonic 330ml can", "400"},
       {"Gordon's Pink & Tonic 330ml can", "400"},
       {"Manyatta Pineapple & Mint 330ml can", "450"},
       {"Snapp Cider 330ml can", "400"}
     ]},
    {"Whisky",
     [
       {"Johnnie Walker Red 750ml", "4000"},
       {"Johnnie Walker Black 750ml", "7000"},
       {"Johnnie Walker Double Black 750ml", "8500"},
       {"Johnnie Walker Green Label 750ml", "11000"},
       {"Johnnie Walker 18yrs 750ml", "18000"},
       {"The Singleton 12yrs 700ml", "9000"},
       {"The Singleton 15yrs 700ml", "10000"},
       {"The Singleton 18yrs 700ml", "13500"}
     ]},
    {"Vodka", [{"Smirnoff Red 750ml", "3500"}]},
    {"Gin",
     [
       {"Gilbey's 750ml", "2800"},
       {"Gordon's Dry 750ml", "4800"},
       {"Tanqueray London Dry 750ml", "5500"},
       {"Tanqueray No. Ten 750ml", "7000"}
     ]},
    {"Rum", [{"Captain Morgan Gold 750ml", "3500"}]},
    {"Liqueur", [{"KC Lemon & Ginger 750ml", "3000"}]},
    {"Tequila",
     [
       {"Don Julio Blanco 750ml", "13500"},
       {"Don Julio Reposado 750ml", "14500"},
       {"Don Julio Anejo 750ml", "15000"},
       {"Casamigos Blanco 750ml", "12000"},
       {"Casamigos Reposado 750ml", "13000"},
       {"Casamigos Anejo 750ml", "13500"}
     ]},
    {"Mixers, Soda & Water",
     [
       {"Delmonte Apple 1L", "500"},
       {"Delmonte Mixed Berries 1L", "500"},
       {"Coca-Cola 500ml", "200"},
       {"Sprite 500ml", "200"},
       {"Sparkling water", "350"},
       {"Red Bull 250ml", "400"},
       {"Keringet water 1L", "200"}
     ]},
    {"Dunhill", [{"Dunhill Double Switch", "600"}, {"Dunhill Single Switch", "600"}]},
    {"Wine", [{"Frontera Summer Red", "2500"}, {"Frontera Tropical White", "2500"}]},
    {"Cocktails",
     [
       {"Savara Tunyonyo", "1100"},
       {"Mkuria On The Rocks", "1000"},
       {"No Baby Onboard", "900"},
       {"They Killed The Wrong Saddam", "900"},
       {"Alusa Continua", "800"},
       {"Blank Cheque", "1300"}
     ]},
    {"Shots",
     [
       {"Gilbeys - Gin", "300"},
       {"Smirnoff Red - Vodka", "400"},
       {"Johnnie Walker Black", "500"},
       {"Don Julio", "600"}
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

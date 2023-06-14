function compare_by_name( a, b ) {
	if ( a.name < b.name ){
	  return -1;
	}
	if ( a.name > b.name ){
	  return 1;
	}
	return 0;
  }

var other_ingredients = [
	{ 'name': 'yeast', 'hydration': 0, 'price': 0 },
	{ 'name': 'sugar', 'hydration': 0, 'price': 0.000207  },
	{ 'name': 'baking_soda', 'hydration': 0, 'price': 0  },
	{ 'name': 'milk', 'hydration': 87, 'price': 0.00297  },
	{ 'name': 'milk_powder', 'hydration': 0, 'price': 0  },	
	{ 'name': 'lemon_juice', 'hydration': 83, 'price': 0  },	
	{ 'name': 'citric_acid', 'hydration': 0, 'price': 0  },
	{ 'name': 'half_half', 'hydration': 80.5, 'price': 0  },
	{ 'name': 'eggs', 'hydration': 74, 'price': 0.6  },
	{ 'name': 'egg_white', 'hydration': 88, 'price': 0.6  },	
	{ 'name': 'dry_malt', 'hydration': 0, 'price': 0  },
	{ 'name': 'malt_syrup', 'hydration': 20, 'price': 0  },
	{ 'name': 'honey', 'hydration': 17.8, 'price': 0  },
	{ 'name': 'butter', 'hydration': 18, 'price': 0.0325  },
	{ 'name': 'oil', 'hydration': 0, 'price': 0  },
	{ 'name': 'poolish', 'hydration': 50, 'price': 0  }
];


other_ingredients.sort(compare_by_name);

var raw_ingredients = [{ 'name': 'water', 'hydration': 100, 'price': 0  },
	{ 'name': 'levain', 'hydration': 50, 'price': 0  },	
	{ 'name': 'salt', 'hydration': 0, 'price': 0  }
].concat(other_ingredients);

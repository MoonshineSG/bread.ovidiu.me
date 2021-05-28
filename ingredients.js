var raw_ingredients = [
	{ 'name': 'water', 'hydration': 100 },
	{ 'name': 'levain', 'hydration': 50 },
	{ 'name': 'poolish', 'hydration': 50 },	
	{ 'name': 'yeast', 'hydration': 0 },
	{ 'name': 'sugar', 'hydration': 0 },
	{ 'name': 'baking_soda', 'hydration': 0 },
	{ 'name': 'salt', 'hydration': 0 },
	{ 'name': 'milk', 'hydration': 87 },
	{ 'name': 'lemon_juice', 'hydration': 83 },	
	{ 'name': 'half_half', 'hydration': 80.5 },
	{ 'name': 'eggs', 'hydration': 74 },
	{ 'name': 'egg_white', 'hydration': 88 },	
	{ 'name': 'dry_malt', 'hydration': 0 },
	{ 'name': 'malt_syrup', 'hydration': 20 },
	{ 'name': 'honey', 'hydration': 17.8 },
	{ 'name': 'butter', 'hydration': 18 },
	{ 'name': 'oil', 'hydration': 0 }
];

function compare_by_name( a, b ) {
	if ( a.name < b.name ){
	  return -1;
	}
	if ( a.name > b.name ){
	  return 1;
	}
	return 0;
  }

raw_ingredients.sort(compare_by_name);


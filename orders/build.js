require('./chunks')

var Configuration = {
	orders: {
		schema: {
			email: ['varchar(255)', {
				'Email is incorrect': " ~ '^[^@]+@.+\\..+$'"
			}],
			name: 'varchar(255)',

			items_ids: 'integer[]'
		},
		//states: {
		//	//created: {},
		//	with_credit_cards: {
		//		schema: {
		//			'credit_card_number': ['text', {
		//				'Please enter cc': 'is not null'
		//			}]
		//		}
		//	}/*,
		//	with_payments: {
		//		schema: {
		//		}
		//	}*/
		//},
		actions: [
			'delete',
			'insert',
			'patch'
		],
		scopes: [
			'versions',
			'heads',
			'current'
		]//,
		//specs: [
		//	['versioning', {
		//		field: 'email',
		//		invalid1: 'abc',
		//		invalid2: 'abcdefwerbgkaerg@geb',
		//		valid1: 'abc@abc.ru',
		//		valid2: '123@abc.ru',
		//		valid3: 'abc@444.ru',
		//		valid4: '123@abc.ru',
		//		valid5: 'abc@abc.com'
		//	}]
		//]
	},
	items: {
		schema: {
			comment: ['text', {
				'Comment not provided': "is not null and new.comment != '' "
			}],
			order_id: ['integer', {
				'Items has to belong to order': 'is not null'
			}]
		},
		relations: [
			['parent', {
				target: 'order',
				targets: 'orders'
			}]
		],
		actions: [
			'delete',
			'insert',
			'patch'
		],
		scopes: [
			'versions',
			'heads',
			'current'
		]/*,
		specs: [
			'target',
			['versioning', {
				extra_columns: ', order_id',
				extra_values: ', 1',

				field: 'comment',
				invalid1: '',
				invalid2: '',
				valid1: 'abc@abc.ru',
				valid2: '123@abc.ru',
				valid3: 'abc@444.ru',
				valid4: '123@abc.ru',
				valid5: 'abc@abc.com'
			}]
		]*/
	},
	variants: {
		schema: {
			comment: ['text', {
				'Comment not provided': "is not null and new.comment != '' "
			}],
			item_id: ['integer', {
				'Items has to belong to order': 'is not null'
			}]
		},
		relations: [
			['parent', {
				target: 'item',
				targets: 'items'
			}]
		],
		actions: [
			'delete',
			'insert',
			'patch'
		],
		scopes: [
			'versions',
			'heads',
			'current'
		]/*,
		specs: [
			'target',
			['versioning', {
				extra_columns: ', item_id',
				extra_values: ', 1',

				field: 'comment',
				invalid1: '',
				invalid2: '',
				valid1: 'abc@abc.ru',
				valid2: '123@abc.ru',
				valid3: 'abc@444.ru',
				valid4: '123@abc.ru',
				valid5: 'abc@abc.com'
			}]
		]*/
	}/*,
	fullfillments: {
		schema: {
			comment: ['text', {
				'Comment not provided': "is not null and new.comment != '' "
			}],
			order_id: ['integer', {
				'Fullfullment has to belong to order': 'is not null'
			}],
			order_email: {
				text: true,
			}
		},
		relations: [
			['source', {
				target: 'order',
				targets: 'orders'
			}]
		],
		actions: [
			'delete',
			'insert',
			'patch'
		],
		scopes: [
			'versions',
			'heads',
			'current'
		],
		specs: [
			'target',
			['versioning', {
				extra_columns: ', order_id',
				extra_values: ', 1',

				field: 'comment',
				invalid1: '',
				invalid2: '',
				valid1: 'abc@abc.ru',
				valid2: '123@abc.ru',
				valid3: 'abc@444.ru',
				valid4: '123@abc.ru',
				valid5: 'abc@abc.com'
			}]
		]
	}*/
}

var substitute = function(path, name, context, config, content) {
	(context || (context = {})).resources = name
	context.schema = config.schema
	context.resource = name.replace(/s$/, '')
	if (!content)
		var content = Chunks[path + '.sql']
	if (content)
		return content.replace(/(['"]\{[^}]*\}['"])|\{((?:[^{}]|\{(?:[^{}]*)\})+)\}(?!['"])/g, function(m, before, variable) {
			if (before) return before
			before = ''
			var block = variable.match(/^\s*(assert|if)\s*'([^']+)'\s*?,?\s*?([\s\S]+)$/i)
			if (block) {
				block[3] = substitute(path, name, context, config, block[3])
				block[2] = substitute(path, name, context, config, block[2])
			}
			if (block && block[1].toLowerCase() == 'assert') {
				var aggregate = block[3].match(/(max|avg|min)\(([^)]+)\)/i)
				if (aggregate)
					return before + 'DO $$  BEGIN\n' +  
						'	IF NOT ((SELECT ' + aggregate[0] + ' from ' + context.resources + ') ' + block[3].replace(aggregate[0], '') + ') THEN\n' +
						'		RAISE EXCEPTION \'' + block[2] + '\';\n' +
						'	END IF;\n' +
						'END $$;\n'
				else
					return before + 'DO $$  BEGIN\n' +  
						'	IF  (SELECT id from ' + context.resources + ' WHERE ' + block[3] + ' LIMIT 1) is null THEN\n' +
						'		RAISE EXCEPTION \'' + block[2] + '\';\n' +
						'	END IF;\n' +
						'END $$;\n'
			} else if (block && block[1].toLowerCase() == 'if') {
				if (block[2].split('/').reduce(function(config, value) {
					if (config && config.push)
						return config.indexOf(value) > -1
					return config && config[value]
				}, config))
					return before + block[3]
				return before
			} else if (variable.match(/\s/)) {
				var key
				var string = variable.replace(/([a-z]+)\s?/ig, function(name, bit) {
					if (!key) {
						key = bit
						return ''
					}
					return name;
				})
				var r = ''
				for (var k in context[key]) {
					var ignored = false
					var val = [].concat(context[key][k]);
					var row = string.replace(/\$(\d)/g, function(m, number) {
						if (number == 1)
							return k;
						if (number == 2) {
							return val[0];
						}
						if (number == 3 && val.length == 1)
							ignored = true;
						return m
					}) + '\n'
					if (!ignored) {
						if (val[1]) {
							for (var validation in val[1]) {
								r += row.replace(/\$(\d)/g, function(m, number) {
									if (number == 4)
										return validation;
									if (number == 3) {
										return val[1][validation];
									}
								}) + '\n'
							}
						} else {
							r += row;
						}
					}
				}
				return before + r.replace(/,\s*$/, '')
			} else {
				return before + variable.replace(/[a-z0-9_$-]+/gi, function(bit) {
					if (context[bit])
						return context[bit]
					return '';
				})
			}
			return '' + variable
		})
	return ''
}
var merge = function(from, to) {
	switch (typeof from) {
		case 'object':
			if (from.push) {
				return from.concat(to || [])
			} else {
				var f = {}
				for (var property in from)
					f[property] = from[property]
				for (var property in to) {
					if (typeof to[property] == 'object' && to[property] && !to[property].push) {
						f[property] = merge(f[property] || {}, to[property])
					} else {
						f[property] = to[property]
					}
				}
				return f;
			}
			break
	}
	return from;
}

var setup = function(name, object, root) {
	var result = ''
	var after = ''
	for (var property in object) {
		var value = object[property]
		if (value && value.push) {
			result += value.map(function(path) {
				if (path && path.push) {
					var context = Object.create(path[1])
					path = path[0]
				}
				return substitute(property + '/' + path, name, context, object)

			}).join('\n\n')
		} else if (property == 'states') {
			for (var n in value) {
				var obj = merge(object, value[n])
				obj.states = {}
				after += setup(name + '_' + n, obj)
			}
		} else {
			result += substitute(property, name, null, object)
		}
	}
	return result + after
}

for (var property in Configuration) {
	console.log(setup(property, Configuration[property]))
}
console.log(Chunks['helpers.sql']);;
console.log(Chunks['queries.sql']);;
console.log(Chunks['structures.sql']);;
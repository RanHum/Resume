import json
with open('input.txt') as input:
	events = json.load(input)
	orders = {}
	final = []
	for e in events:
		# print(orders)
		id = e['order_id']
		if not orders.get(id, 0):
		# else:
			orders[id] = {}
			orders[id]['items'] = {}
		if orders[id]['items'].get(e['item_id']):
			# print(orders[id]['items'][e['item_id']]['event_id'], e['event_id'])
			if orders[id]['items'][e['item_id']]['event_id'] < e['event_id']:
				orders[id]['items'][e['item_id']]['status'] = e['status']
				orders[id]['items'][e['item_id']]['event_id'] = e['event_id']
				orders[id]['items'][e['item_id']]['count'] = e['count'] - e['return_count']
		else:
			orders[id]['items'][e['item_id']] = {}
			orders[id]['items'][e['item_id']]['status'] = e['status']
			orders[id]['items'][e['item_id']]['event_id'] = e['event_id']
			orders[id]['items'][e['item_id']]['count'] = e['count'] - e['return_count']
		# print(orders)
	for o in orders.keys():
		final.append({'id': o, 'items': []})
		for it in list(orders[o]['items'].keys()):
			item = orders[o]['items'][it]
			# print(item)
			if item['status'] == 'OK' and item['count'] > 0:
				final[-1]['items'].append({'count': item['count'], 'id': it})
		if not len(final[-1]['items']):
			del(final[-1])
	with open('output.txt', 'w') as json_file:
		json.dump(final, json_file)

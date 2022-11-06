import subprocess, json, sys, os, datetime

os.chdir(os.path.dirname(__file__))
argv = sys.argv
argv = [argv[0]] + argv[1].split() + ['']*10

def link2config(link):
	config = json.loads(subprocess.run(['python', '-u', 'vmess2json.py', link], stdout=subprocess.PIPE).stdout)
	c = config['inbounds'][0]
	c['port'] = 8080
	c['protocol'] = 'shadowsocks'
	c['settings'] = {'method': 'aes-128-gcm', 'password': 'password'}
	del(config['routing'])
	del(config['dns'])
	del(config['inbounds'][1])
	del(config['outbounds'][1])
	return config

def config2file(config, filename='config.json'):
	with open(filename, 'w') as json_file:
		json.dump(config, json_file)

def disconnect():
	os.system('taskkill /f /im wv2ray.exe')

def connect():
	disconnect()
	os.startfile('wv2ray')

def askLog(links, dates):
	print('Which server should i choose?')
	for i, link in enumerate(links):
		print(f'[{i}] {dates[i]} {link[:50]}')
	return input()

def getLog(needDates=False):
	links, dates = [], []
	with open('links.log', 'r') as log:
		for line in log.readlines():
			line = line.split()
			links.append(line[2])
			if needDates:
				dates.append(line[0] + ' ' + line[1])
	return links, dates

def getIndex(initial, askFunc, *args):
	choice = initial if initial else askFunc(*args)
	choice = -1 if choice == 'last' or not choice else int(choice)
	return choice

if argv[1] == 'connect':
	if argv[2] == 'log':
		links, dates = getLog(not argv[3])
		choice = getIndex(argv[3], askLog, links, dates)
		config2file(link2config(links[choice]))
	elif argv[2]:
		config2file(link2config(argv[2]))
		with open('links.log', 'a') as log:
			log.write(f'{datetime.datetime.today()}: {argv[2]}\n')
	connect()
elif argv[1] == 'disconnect':
	disconnect()
elif argv[1] == 'convert':
	if argv[2] == 'log':
		assert argv[3], 'Need at least filename!'
		links, dates = getLog(not argv[4])
		choice = getIndex(argv[3] if argv[4] else argv[4], askLog, links, dates)
		config2file(link2config(links[choice]), argv[4] if argv[4] else argv[3])
	else:
		assert argv[3], 'Need filename!'
		config2file(link2config(argv[3]), argv[2])
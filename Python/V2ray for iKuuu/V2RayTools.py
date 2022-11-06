import json, os, sys, datetime, re, requests
from urllib.parse import urlsplit
from base64 import b64encode, b64decode
from typing import Optional, List
import typer
import vmess2json as v2j

app = typer.Typer()
arg = typer.Argument
opt = typer.Option
allow_negs = {'context_settings':{"ignore_unknown_options": True}}

app_path : str
if getattr(sys, 'frozen', False):
	app_path = sys.executable
else:
	app_path = os.path.abspath(__file__)
app_path = os.path.dirname(app_path) + '/'

default_config = 'config.json'
default_template = 'template.json'

@app.command()
def getSSLink(config: Optional[str] = arg(default_config, help='Config filename to extract Shadowsocks credentials from')):
	c = file2config(config)['inbounds'][0]
	creds = f"{c['settings']['method']}:{c['settings']['password']}@localhost:{c['port']}"
	# print('ss://' + creds)
	print('ss://' + b64encode((creds).encode('utf-8')).decode('utf-8').rstrip())

def getSub(url):
	sub_str_list = b64decode(requests.get(url+'&extend=1').content.decode('utf-8')).decode().splitlines()
	remain = json.loads(b64decode(urlsplit(sub_str_list[0]).netloc).decode('utf-8'))['ps']
	return re.sub('\w*：', 'Remaining traffic: ', remain), list(filter(None, sub_str_list))[2:]

def config_add_outs(conf_1, conf_2):
	if conf_1 and conf_2:
		conf_2 = conf_2.get('outbounds', []) if type(conf_2) == dict else conf_2
		for out in conf_2:
			if out['protocol'] != 'freedom' and out['streamSettings'].get('security', '') != 'tls' and out not in conf_1['outbounds']:
				conf_1['outbounds'].append(out)
	return conf_1 or conf_2

def link2config(link, trim=True):
	try:
		config = v2j.vmess2client(v2j.load_TPL("CLIENT"), v2j.parseLink(link))
		return config['outbounds'] if trim else config
	except Exception as e:
		print(e)
		return {}

def path_vars(filename):
	if os.path.isfile(filename):
		return filename
	elif os.path.isfile(app_path + filename):
		return app_path + filename
	return ''

def file2config(filename, trim=False):
	filename_resolved = path_vars(filename)
	if filename_resolved:
		with open(filename_resolved) as file:
			config = json.load(file)
			return config['outbounds'] if trim else config
	print(f'File not found: "{filename}"')
	return {}

def config2file(config, filename):
	with open(filename, 'w') as json_file:
		json.dump(config, json_file)
		return True

def source_feed(sources, context=None):
	isLog = lambda i: type(i) == int or i.lstrip('-+').isnumeric()
	for source in sources:
		if isLog(source):
			line = getLogIndex(int(source), context)
			if line[1]:
				yield from source_feed((re.findall(r': (.+)', line[1])[0],), line[0])
			else:
				print(f'Log index {source} doesn\'t exist, treating as filename')
				yield str(source)
		elif source.startswith(('https://', 'http://')):
			stats, subs = getSub(source)
			print(stats)
			for sub in subs:
				yield sub
		else:
			yield str(source)

@app.command(**allow_negs)
def convert(
		input: List[str] = arg(..., help='Multiple of log indexes, filenames, or links to convert'),
		output: str = opt('stdout', '-o', help='Filename to write to'),
		template: str = opt(default_template, '-t', help='Initial config, blank if inexist')
	):
	config = file2config(template)
	for source in source_feed(input):
		extr = link2config if source.startswith(('vmess://', 'ss://')) else file2config
		config = config_add_outs(config, extr(source, bool(config)))
	if not config or len(config['outbounds']) == 0:
		print('Cannot extract config!')
		return False
	if output == 'return':
		return config
	return (print(config) if output == 'stdout' else config2file(config, output)) or True

def f_log(str):
	with open(app_path + 'links.log', 'a') as log:
		log.write(f'{datetime.datetime.today()}: {str}\n')

def logIter():
	with open(app_path + 'links.log') as log:
		for i, line in enumerate(log):
			yield i, line.rstrip()

def getLogIndex(i, rel=None):
	try:
		if i < 0:
			return [(i, line) for i, line in logIter() if not rel or i < rel][i]
		for i, line in filter(lambda l, i=i: l[0] == i, logIter()):
			return i, line
	except:
		pass
	return (None, '')

@app.command(**allow_negs)
def log(
		trim: int = opt(100, '-t', help='Trim threshold'),
		index: Optional[int] = arg(None, help='Index'),
		begin: int = opt(0, '-b', help='Begin of slice'),
		end: int = opt(None, '-e', help='End of slice')
	):
	if index is None:
		for i, line in [(i, line) for i, line in logIter()][begin:end]:
			print(i, line[:trim])
	else:
		print(*getLogIndex(index))

@app.command()
def disconnect():
	os.system('taskkill /f /im wv2ray.exe')

@app.command(**allow_negs)
def connect(config: Optional[str] = arg(default_config, help='Config filename, "vmess" or "ss" links, subscription link, or log index')):
	result = convert((config,), 'return', default_template) if config != default_config else {}
	disconnect()
	if result:
		f_log(config)
		config2file(result, default_config)
	# os.startfile('wv2ray')
	os.system('v2ray run')
	print('Started V2Ray')

if __name__ == "__main__":
	app()

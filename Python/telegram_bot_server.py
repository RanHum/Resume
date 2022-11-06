#internal
from time import time, sleep
from datetime import datetime
#external
import telepot

Token = '[REDACTED]'
ss_server_url_template = 'chacha20:Ranhum@%s:9000'#'aes-256-cfb:Ranhum@%s:9000'
chats_cfg = 'chats.txt'
ip_history_cfg = 'ip_history.txt'
qr_code_file = 'qr.png'
log_file_cfg = 'bot.log'
log_file = False
backlog = {}
ss_url = False
tele_api_connection = False
network_connect = False
last_update_id = 0
sleep_time = 2
current_ip = ''
last_ip = ''
last_ip_checked = 0
ip_change_pending = False
last_proxy_checked = 0
admins = ['RanHum']
TelegramBot = telepot.Bot(Token)

def set_telepot_socks_proxy(url, username=None, password=None, socksparams={}):
	def dictupdate(source, update):
		source.update(update)
		return source
	from urllib3.contrib.socks import SOCKSProxyManager
	from telepot.api import _default_pool_params, _onetime_pool_params
	telepot.api._onetime_pool_spec = (SOCKSProxyManager, dict(
		proxy_url=url, username=username, password=password, **dictupdate(_onetime_pool_params, socksparams)))
	telepot.api._pools['default'] = SOCKSProxyManager(
		url, username=username, password=password, **dictupdate(_onetime_pool_params, socksparams))

def find_and_set_working_proxy():
	# use system shadowsocks
	#set_telepot_socks_proxy('socks5h://127.0.0.1:1080')
	#return True

	proxy_list = []
	my_params = {'retries': 3, 'timeout': 5}
	with open('proxy_list.txt', 'r+') as proxy_list_file:
		proxy_list = proxy_list_file.readlines()
	while proxy_list:
		proxy = proxy_list.pop(0).strip()
		log('Attempting to connect via ' + proxy + '... ')
		set_telepot_socks_proxy('socks5h://' + proxy, socksparams=my_params)
		if check_tele_api_connection(forced=True, silent=True):
			#log('Success', append_last_line=True)
			proxy_list.insert(0, proxy + '\n')
			break
		#else:
			#log('Fail', append_last_line=True)
	with open('proxy_list.txt', 'w+') as proxy_list_file:
		proxy_list_file.writelines(proxy_list)
	if tele_api_connection:
		log('Server successfully connected to Telegram Bot API')
		return True
	else:
		log('All proxy in the list are dead...', True)
		return False

def check_tele_api_connection(forced=False, silent=False):
	global tele_api_connection#, last_proxy_checked
	#current_time = time()
	if forced: # or current_time - last_proxy_checked > 60:
		#last_proxy_checked = current_time
		try:
			tele_api_connection = bool(TelegramBot.getMe())
		except:
			tele_api_connection = False
			if not silent:
				log('Failed to connect Telegram Bot API - proxy is down?', True)
	return tele_api_connection

def check_network_and_get_current_ip(forced=False):
	global current_ip, network_connect, last_ip_checked, last_ip
	current_time = time()
	if forced or current_time - last_ip_checked > (60 if network_connect else 5):
		last_ip_checked = current_time
		try:
			from requests import get
			#import subprocess, re
			#myip = subprocess.check_output('nslookup myip.opendns.com resolver1.opendns.com').decode('cp1251')
			#current_ip = re.findall(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', myip)[1]
			intermediate_ip = current_ip
			current_ip = get('http://checkip.amazonaws.com').text[:-1]
			network_connect = True
			if intermediate_ip in '0.0.0.0':
				log('Server is online', True)
			if not current_ip in last_ip:
				global ip_change_pending
				log('Server IP has been updated: last = ' + str(last_ip) + ', current = ' + current_ip, True)
				last_ip = current_ip
				ip_change_pending = True
				with open(ip_history_cfg, 'a+') as ip_file:
					ip_file.write(str(datetime.now()) + ': ' + last_ip + ' => ' + current_ip + '\n')
		except:
			network_connect = False
			if not current_ip in '0.0.0.0':
				log('Failed to get current ip - no network connection?', True)
				current_ip = '0.0.0.0'
			check_tele_api_connection(forced=True, silent=True)
	return network_connect

def get_chatid_by_user(user, file = None):
	if not file:
		file = open(chats_cfg)
	for line in file:
		if user in line:
			return int(line.split()[2])
	return 0

def backlog_messages(chat_id, messages):
	global backlog
	if chat_id in backlog:
		backlog[chat_id].extend(messages)
	else:
		backlog[chat_id] = messages

def log(msg, notify_admin=False, append_last_line=False):
	log_msg = str(datetime.now()) + ': ' + str(msg)
	if notify_admin:
		post(get_chatid_by_user('RanHum'), msg)
	if append_last_line:
		#TODO
		log_file.seek(log_file.tell() - 2, 0)
		#sys.stdout.write(f'\033[F')
		#sys.stdout.write('\033[%iG%s' % (100, msg))
		#sys.stdout.flush()
	print(log_msg)
	log_file.write(log_msg + '\n')
	log_file.flush()

def update_ss_creds(ip, update_qr=True):
	from base64 import b64encode
	global ss_url
	ss_url = 'ss://' + b64encode((ss_server_url_template % ip).encode('utf-8')).decode('utf-8').rstrip()
	if update_qr:
		from pyqrcode import create
		create(ss_url).png(qr_code_file, scale=15)

def check_bot_updates():
	global last_update_id
	try:
		updates = TelegramBot.getUpdates(offset=last_update_id+1,timeout=1)
	except:
		check_tele_api_connection(forced=True)
		return False
	if updates:
		for update in updates:
			if 'message' in update:
				msg = update['message']
				if 'text' in msg:
					command = msg['text']
					if '/start' in command:
						register_new_user_and_welcome(msg)
					elif '/update' in command and last_update_id: # no need to update several times on launch
						log(msg['chat']['username'] + ' requested to update server creds')
						check_network_and_get_current_ip(forced=True)
						if ip_change_pending:
							post(msg['chat']['id'], 'Thank ya, IP indeed has been changed recently!')
						else:
							post(msg['chat']['id'], ['image:' + qr_code_file, 'Update requested but wasn\'t needed!\nIf you don\'t like QR code above, import URL below', ss_url])
					elif msg['chat']['username'] in admins:
						if last_update_id: # only for commands for already running server
							if '/stop' in command or '/restart' in command:
								try:
									TelegramBot.getUpdates(offset=update['update_id']+1)
								except:
									log('Failed to sync to server while shutting down - shutdown anyway')
								shutdown(restart='/restart' in command)
						if '/keys' in command:
							log(msg['chat']['username'] + ' requested keyboard')
							send_keyboard(get_chatid_by_user('RanHum'))
			else:
				log('Received unknown bot update:\n' + update, True)
		last_update_id = updates[-1]['update_id']
	elif not last_update_id:
		last_update_id = 1 # init state if no updates since stopped
	return False

def send_keyboard(chat_id):
	keyboard = {'keyboard': [['/stop', '/restart'], ['/update']], 'resize_keyboard': True, 'one_time_keyboard': True}
	post(chat_id, 'Take a keyboard for ya!', reply_keyboard=keyboard)

def register_new_user_and_welcome(msg):
	with open(chats_cfg, 'r+') as chats_file:
		chat = msg['chat']
		if chat['id'] != get_chatid_by_user(chat['username'], chats_file):
			log('Registering user ' + chat['username'], True)
			chats_file.write(str(datetime.now()) + ': ' + str(chat['id']) + ' ' + chat['username'] + '\n')
			post(chat['id'], ['image:' + qr_code_file, 'Hello there, sweetie! Here is a server for ya!\nIf you don\'t like QR code above, import this URL:\n\n%s' % ss_url])

def post(chat_id, messages, reply_keyboard=None):
	#print(messages)
	if type(messages) == str:
		messages = [messages]
	if not tele_api_connection:
		backlog_messages(chat_id, messages)
		return False
	while messages:
		msg = messages.pop(0)
		try:
			if 'image:' in msg:
				TelegramBot.sendPhoto(chat_id, open(msg[6:], 'rb'), reply_markup=reply_keyboard)
			else:
				TelegramBot.sendMessage(chat_id, msg, parse_mode='Markdown', reply_markup=reply_keyboard)
		except:
			messages.insert(0,msg)
			backlog_messages(chat_id, messages)
			check_tele_api_connection(forced=True)
			return False
	return True

def post_backlog():
	global backlog
	for chat_id in list(backlog.keys()):
		chat_backlog = backlog.pop(chat_id)
		if not post(chat_id, chat_backlog):
			log('Failed to send backlog')
			return False
	return True

def broadcast_server_creds():
	messages = ['image:' + qr_code_file, 'IP updated!\nIf you don\'t like QR code above, import URL below', ss_url]
	log('Broadcasting new IP started')
	for line in open(chats_cfg):
		log('Sending new IP to ' + line.split()[3])
		chat_id = int(line.split()[2])
		post(chat_id, messages)
	log('Broadcasting new IP ended')

def init_file_if_needed(filename, init_str, log_msg):
	import os
	if not os.path.isfile(filename):
		log(log_msg)
		with open(filename, 'w+') as file:
			file.write(init_str)

def init():
	import os
	global log_file
	log_file = open(log_file_cfg, 'a+')
	log('Initialisation started')
	#accounts
	init_file_if_needed(chats_cfg, '', 'Creating new accounts file')
	#ip history
	global last_ip
	init_file_if_needed(ip_history_cfg, str(datetime.now()) + ': None => None\n', 'Creating new ip history file')
	with open(ip_history_cfg) as ip_file:
		last_ip = ip_file.readlines()[-1].split()[4]
	log('Last used ip was ' + last_ip)
	#last known ss creds
	update_ss_creds(last_ip, update_qr=not os.path.isfile(qr_code_file))
	log('Initialisation finished')

def shutdown(restart=False):
	import sys, os
	if restart:
		log('Server is restarting', True)
		log_file.close()
		os.execv(sys.executable, ['python'] + sys.argv)
	else:
		log('Server is shutting down', True)
		log_file.close()
		sys.exit(0)

def main():
	global ip_change_pending
	init()
	while True:
		try:
			if check_network_and_get_current_ip():
				if ip_change_pending:
					update_ss_creds(current_ip)
					broadcast_server_creds()
					ip_change_pending = False
				if check_tele_api_connection():
					if backlog:
						if not post_backlog():
							continue
					check_bot_updates()
				else:
					find_and_set_working_proxy()
			sleep(sleep_time)
		except KeyboardInterrupt:
			shutdown(restart=True)
		except:
			from traceback import print_exc
			print_exc(file=log_file)

if __name__ == '__main__':
	main()

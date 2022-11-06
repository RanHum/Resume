import re, requests, zipfile, os, datetime
pac = requests.get("https://antizapret.prostovpn.org/proxy.pac")
with open('pac_new.txt','w') as file:
	for line in pac.iter_lines():
		line = line.decode('utf-8')
		if "return" in line:
			line = re.sub(r'return ".{10,}";', r'return __PROXY__;', re.sub(r'return "DIRECT";', r'return "DIRECT;";', line))
		file.write(line)
		file.write('\n')
new_name = 'pac ' + str(datetime.date.today()) + '.txt'
os.replace('pac.txt', new_name)
os.replace('pac_new.txt', 'pac.txt')
with zipfile.ZipFile('pac.zip', 'a') as myzip:
    myzip.write(new_name)
os.remove(new_name)
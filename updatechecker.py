from bs4 import BeautifulSoup
import requests
import json

f = open('drivers.json')
jsondata = json.load(f)
lastver = jsondata['win']['x86_64']['drivers'][-1]['version']
#print("Available version is "+ lastver)

r = requests.get("https://www.nvidia.com/content/rss/geforce/news/index.php")
rssfeed = r.content.decode()
parsedrss = BeautifulSoup(rssfeed, "xml")
links = parsedrss.find_all('link')

for link in links:
    url = link.text
    if('game-ready-driver' in url):
        #print(url)
        r = requests.get(url)
        urlsource = BeautifulSoup(r.text, 'html.parser')
        sourcelinks = urlsource.find_all('a')
        
        for slink in sourcelinks:
            actual = slink.get('href')
            if('download.nvidia.com' in format(actual)):
                #print(format(actual))
                ver = format(actual).split('/')[4]
                #print("Latest version is " + ver)
        break

print('SAME_VER') if (lastver==ver) else print(ver)

f.close()

seen = set()

a = open('people_1.txt', 'r')
b = open('people_2.txt', 'r')
file = open('csvfile.csv', 'w')

for line in a:
    tmp = line.split('	')
    coverted = ''
    for item in tmp:
        item = item.lower()
        item = item.replace('-', '')
        item = item.replace('no.', '')
        item = item.replace('#', '')
        item = item.replace(' ', '')
        coverted += item
    if coverted not in seen:
        seen.add(coverted)
        file.write(line)

for line in b:
    if "FirstName" in line:
        continue
    tmp = line.split('	')
    coverted = ''
    for item in tmp:
        item = item.lower()
        item = item.replace('-', '')
        item = item.replace('no.', '')
        item = item.replace('#', '')
        item = item.replace(' ', '')
        coverted += item
    if coverted not in seen:
        seen.add(coverted)
        file.write(line)

a.close()
b.close()
file.close()


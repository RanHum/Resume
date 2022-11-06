notes = []
lines = {}
cur = {}
linesforwrite = []
nums = set('1234567890.')
bools = ['True','False']
taglist = {}

def cutline(s):
    comments = ['--','//']
    for com in comments:
        if com in s:
            s = s[:s.index(com)]
    return s.strip()

def Typed(s):
    if set(s)<=nums:
        if '.' in s:
            return float(s)
        else:
            return int(s)
    elif s in bools:
        return bool(s)
    else:
        return s

def Init(file=None):
    file = file or 'diary.txt'
    f = open(file, 'r')
    active = 0
    for s in f:
        s = cutline(s)
        if s:
            if '@' in s:
                if '<@' in s:
                    active += 2
                elif '!@' in s:
                    active += 1
                elif '>@' in s:
                    active -= 2
                s = s[s.rindex('@')+1:]
                notes.append({'name':s,'active':active,'descr':''})
                if '!@' in s:
                    active -= 1
            elif '##' in s:
                global taglist
                taglist = dict(enumerate(map(cutline,s[2:].split())))
            elif '#' in s:
                s = s[1:].split()
                notes[-1]['tags'] = {taglist.get(i,i-len(taglist)):s[i] for i in range(len(s))}
            elif '$$' in s:
                sets = map(cutline,s[2:].split('='))
                cur[sets[0]] = Typed(sets[1])
            elif '$' in s:
                linesforwrite.append(s)
                l,s = map(cutline,s[1:].split(':'))
                s = set(map(cutline,s.split(',')))
                lines[l] = s if l not in lines else lines[l]|s
                l = set([l])
                for i in s:
                    lines[i] = l if i not in lines else lines[i]|l
            else:
                notes[-1]['descr'] += s
    f.close()
    cur['notes'] = notes

def WriteFile(file=None):
    file = file or 'diary.txt'
    f = open(file, 'w')
    active = 0
    del cur['notes']
    f.write('$$'+'\n$$'.join(['%s = %s'%tuple(x) for x in cur.iteritems()])+'\n')
    cur['notes'] = notes
    f.write('\n'.join(linesforwrite))
    f.write('\n##'+' '.join([taglist[x] for x in range(len(taglist))])+'\n\n')
    for note in notes:
        na = note['active']
        if (na%2) == 1:
            s = '!@'
        else:
            if na > active:
                s = '<@'
            elif na < active:
                s = '>@'
            else:
                s = '@'
        f.write(s+note['name']+'\n'+note['descr']+'\n#'+\
        ' '.join([note['tags'][taglist.get(i,i-len(taglist))] for i in range(len(note['tags']))])+'\n')
        active = note['active']
    f.close()

def FindLines(keys,maxlevel):
    keys = set(keys)
    levelin = keys
    levelout = set()
    for i in range(maxlevel):
        for key in levelin:
            levelout = levelout|lines[key]
        levelin = levelout - levelin - keys
        keys |= levelout
    return keys

def FindNotesKW(keys):
    res = []
    for note in cur['notes']:
        if note['active']==0:
            for key in keys:
                if key in note['tags'].itervalues() or key in note['name']:
                    res.append(note)
                    break
    return res

def PrNote(note):
    s = '@ '+note['name']+'\n'+note['descr']+'\n'
    if cur['print_tags']:
        s += '# '+', '.join([note['tags'][taglist.get(i,i-len(taglist))]\
        if taglist.get(i,i-len(taglist))<=nums else taglist.get(i,i-len(taglist))+\
        ': '+note['tags'][taglist.get(i,i-len(taglist))] for i in range(len(note['tags']))])
    return s

def Proceed(s):
    def select()
    s = s.split(None,1)
    if s[0] == 'set':
        s = s[1].split(None,1)
        cur[s[0]] = Typed(s[1])
        return '$ '+s[0]+' = '+str(cur[s[0]])
    elif s[0] == 'change':
        s = s[1].split(None,1)
        nslice = map(Type,s[1].split(':'))
        nslice[0] = nslice[0] if nslice[0] else 0
        nslice[1] = nslice[1] if nslice[1] else -1
        cur['notes'] = cur['notes'][nslice[0]:nslice[1]]
        
    elif s[0] == 'select':
        cur['notes'] = notes if s[1]=='all' else cur['notes']
    elif s[0] == 'print':
        return '$ '+s[1]+' = '+str(cur[s[1]])
    elif s[0] == 'find':
        words = FindLines(s[1].split(),cur['maxlevel'])
        notes1 = FindNotesKW(words)
        cur['notes'] = notes1
        notes1 = map(lambda x: str(x[0])+' '+x[1],enumerate(map(PrNote,notes1)))
        return '\n\n'.join(notes1)

def Main():
    Init()
    s = ''
    while s.lower() != 'exit':
        if s:
            res = Proceed(s)
            if res:
                print(res)
        s = cutline(raw_input(cur['hello']))
    WriteFile()
    print('Exit...')

Main()
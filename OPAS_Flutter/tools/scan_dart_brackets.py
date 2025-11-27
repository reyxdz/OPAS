from pathlib import Path
p=Path('lib/features/seller_panel/screens/product_listing_screen.dart')
s=p.read_text()
counts={'(':0,')':0,'{':0,'}':0,'[':0,']':0}
for ch in s:
    if ch in counts:
        counts[ch]+=1
print('Totals:', counts)

# track line-by-line
line=1
c_open={'(':0,'{':0,'[':0}
for ln in s.splitlines(True):
    for ch in ln:
        if ch in c_open:
            c_open[ch]+=1
        elif ch==')':
            c_open['(']-=1
        elif ch=='}':
            c_open['{']-=1
        elif ch==']':
            c_open['[']-=1
    if any(v<0 for v in c_open.values()):
        print('Negative balance at line', line, 'counts', c_open)
        break
    line+=1
else:
    print('No negative balance; final balances:', c_open)

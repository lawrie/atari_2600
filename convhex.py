import binascii
import sys
i = 0
filename = sys.argv[1] + '.bin'
with open(filename, 'rb') as f:
    content = f.read()
    for x in content:
        print(binascii.hexlify(x))
        i += 1
        if i == 4096:
            break

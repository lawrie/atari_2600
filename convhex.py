import binascii
i = 0
filename = 'test.bin'
with open(filename, 'rb') as f:
    content = f.read()
    for x in content:
        print(binascii.hexlify(x))
        i += 1
        if i == 255:
            break

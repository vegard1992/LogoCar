def asm2ramcodes_edit(mc, off = 0):
    fpath = "servotest.bin"


    l = '\tsignal ram: ram_type := ({0}, others => x"FF");'
    f = '{0} => x"{1}"'

    ram = []

    fill2 = lambda x: "0"*(2-len(x))+x

    for i, b in zip(range(len(mc)), mc):
        H = fill2(hex(b)[2:].upper())
        nl = f.format(i+off, H)
        ram.append(nl)

    init = l.format(", ".join(ram))

    to_path = fpath.split(".")[0]+".pastemeinvivado"
    with open(to_path, "w+") as f:
        f.write(init)


def servo_test_1():
    mc = [[int("F0", 16), int("DF", 16), int("E0", 16), int("DF", 16)][i%4] for i in range(20*4)]
    print(mc)
    asm2ramcodes_edit(mc, off = 2)


if __name__ == "__main__":
    servo_test_1()
    
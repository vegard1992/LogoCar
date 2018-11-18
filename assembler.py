
import struct

# ezpz code to assemble regular turtle commands

def assemble_turtle_line(tl):
    keyw2asm = {
        "forward": "11010000",
        "left": "10101010",
        "right": "01010101",
        "backward": "00101111"
    }

    fill2 = lambda x: "0"*(2-len(x))+x

    s = tl.split(" ")
    if len(s) >= 2:
        keyw, data = s
        b1 = int(keyw2asm[keyw], 2)
        b2 = int(data)
        h1 = fill2(hex(b1)[2:].upper())
        h2 = fill2(hex(b2)[2:].upper())
        h = h1 + " " + h2
    else:
        pass

    return h

def assemble_turtle(fpath):
    with open(fpath, "r") as f:
        lines = f.readlines()

    h = []

    for l in lines:
        asm_line = assemble_turtle_line(l)
        h.append(asm_line)

    out = bytes()
    out = out.fromhex(" ".join(h))

    to_path = fpath.split(".")[0]+".bin"

    with open(to_path, "w+b") as f:
        f.write(out)

def asm2ramcodes(fpath, off = 0):
    with open(fpath, "rb") as f:
        mc = f.read()

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



# actual assembler code; takes legit assembler code as input
# and assembles to a .bin file runnable by our target machine

# https://forums.xilinx.com/t5/Spartan-Family-FPGAs/Initializing-Block-RAM-with-External-Data-File/td-p/229193
# https://forums.xilinx.com/t5/Embedded-Development-Tools/RAM-initialization-post-build-in-Vivado/td-p/443318
# https://www.xilinx.com/support/answers/63041.html

def assemble_for_logocar(fpath):
    pass


if __name__ == "__main__":
    assemble_turtle("car_test.turtle")
    asm2ramcodes("car_test.bin", off = 2)
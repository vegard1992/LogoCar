import lsystems
import assembler

std_translation = "\
(F -> forward {1}),\
 (+ -> right {0}),\
  (- -> left {0}),\
   ([ -> record),\
    (] -> unwind),\
     (G -> forward {1})\
     "

def compile_lsystem(fpath):
    with open(fpath, "r") as f:
        lines = f.readlines()

    d = {
        "variables": None,
        "constants": None,
        "ignore": None,
        "seed": None,
        "rules": None,
        "iterations": None,
        "angle": None,
        "steps": None
    }

    for l in lines:
        if "=" not in l:
            continue
        name, value = l.split("=")
        name = name.rstrip(" ")
        value = value.lstrip(" ").rstrip("\n").lstrip('"').rstrip('"')

        d[name] = value

    expanded = lsystems.lsys_expand_n(
        d["variables"], 
        d["constants"],
        d["rules"],
        d["ignore"],
        d["seed"],
        int(d["iterations"])
    )
    

    translation = std_translation.format(d["angle"], d["steps"])
    turtle_commands = lsystems.lsys_to_turtle(d["variables"], d["constants"], expanded, translation)

    no_extn = fpath.split(".")[0]

    to_path = no_extn+".turtle"

    with open(to_path, "w+") as f:
        f.write("\n".join(turtle_commands))

    assembler.assemble_turtle(no_extn+".turtle")
    assembler.asm2ramcodes(no_extn+".bin", off = 2)

# try to copy+paste output of .turtle file here;
# https://www.calormen.com/jslogo/

if __name__ == "__main__":
    compile_lsystem("sierpenski.lsys")
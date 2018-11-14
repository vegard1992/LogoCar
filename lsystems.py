
class Rule:
    def __init__(self, s, ignore):
        self.context_left = ""
        self.context_right = ""
        self.variable = ""
        self.to = ""

        self.make(s, ignore)

    def clean(self, s):
        seps = "\t", " "
        for sep in seps:
            sep2 = sep * 2
            sep1 = sep
            sep0 = ""
            while sep2 in s:
                s = s.replace(sep2, sep1)
            while sep1 in s:
                s = s.replace(sep1, sep0)

        s = s.lstrip("(").rstrip(")")

        return s

    def make(self, s, ignore):
        s = self.clean(s)
        i = self.clean(ignore)

        rf, rt = s.split("->")

        rest = rf
        if "<" in rest:
            self.context_left, rest = rest.split("<")
        if ">" in rest:
            rest, self.context_right = rest.split(">")

        self.ignore = list(i)

        self.left = [self.context_left] + self.ignore
        self.right = [self.context_right] + self.ignore

        self.variable = rest

        self.to = rt

    def get_left(self, i, j, seed):
        l = len(self.context_left)
        n = i - l
        while 0 <= n:
            x = seed[n:n+l]
            if x in self.ignore:
                n = n - 1
            else:
                break
        else:
            return None

        return x

    def get_right(self, i, j, seed):
        l = len(self.context_left)
        n = i + l + 1
        while 0 <= n:
            x = seed[n:n+l]
            if x in self.ignore:
                n = n + 1
            else:
                break
        else:
            return None

        return x

    def do(self, i, j, seed):
        # old:
        """
        for l, r in zip(self.left, self.right):
            to_left = i-len(l)
            to_right = i+len(r)
            if 0 <= to_left and to_right < len(seed) and \
                seed[to_left:i] == l and \
                seed[i+1:to_right] == r:
                return self.to
        else:
            return j
        """

        left_char = self.get_left(i, j, seed)
        right_char = self.get_right(i, j, seed)

        if  (left_char in (None, self.context_left)) and \
            (right_char in (None, self.context_right)):
            return self.to

        return j


class Rules:
    def __init__(self, rules, ignore):
        self.rules = {}
        self.make(rules, ignore)

    def add_rule(self, r_obj):
        if r_obj.variable not in self.rules:
            self.rules[r_obj.variable] = []

        self.rules[r_obj.variable].append(r_obj)

    def make(self, rules, ignore):
        for r in rules.split(","):
            robj = Rule(r, ignore)
            self.add_rule(robj)

    def get_rules_for(self, j):
        if j in self.rules:
            return self.rules[j]
        else:
            return None

def interpret_rules(rules, ignore):
    return Rules(rules, ignore)

def apply_rule(i, j, rules, seed):
    rules = rules.get_rules_for(j)
    if rules != None:
        for rule in rules:
            done = rule.do(i, j, seed)
            if done == j:
                continue
            result = done
            break
        else:
            result = j
    else:
        result = j
    return result

def expand_one(variables, constants, rules, seed):
    return "".join([apply_rule(i, j, rules, seed) for i, j in zip(list(range(len(seed))), seed)])

def lsys_expand_n(variables, constants, rules, ignore, seed, iterations):
    interp_rules = interpret_rules(rules, ignore)
    for i in range(iterations):
        seed = expand_one(variables, constants, interp_rules, seed)

    return seed

def lsys_gen_translation(variables, constants, translation):
    vars_consts = variables.split(" ") + constants.split(" ")
    r = Rules(translation, "")
    tr_ = {k: r.get_rules_for(k)[0].do(0, k, "abc") for k in vars_consts if k in r.rules}
    translation_rules = {k: tr_[k].replace("forward", "forward ").replace("right", "right ").replace("left", "left ").
    replace("backward", "backward ") \
    for k in tr_.keys()}
    return translation_rules
    
def reverse_commands(commands):
    t = {
        "left" : "right",
        "right" : "left",
        "forward" : "backward",
        "backward" : "forward"
    }
    reverse = []
    for l in reversed(commands):
        c, v = l.split(" ")
        rt = t[c]
        rc = "{0} {1}".format(rt, v)
        reverse.append(rc)
    
    return reverse

def get_closing_unwind(turtle_commands, at):
    count = 0
    i = 0
    while True:
        c = turtle_commands[at:][i]
        if c == "record":
            count += 1
        elif c == "unwind":
            count -= 1
        
        if count == 0:
            break

        i += 1

    return i + at

def merge_commands(tc, nc, i, ci):
    return tc[:i] + nc + tc[ci+1:]

def recursion_pass(turtle_commands, n = 0):
    recorded = []
    i = 0
    while i < len(turtle_commands):
        c = turtle_commands[i]
        if c == "record":
            closing_unwind = get_closing_unwind(turtle_commands, i)
            excerpt = turtle_commands[i+1:closing_unwind]
            if excerpt == []:
                turtle_commands = turtle_commands[:i] + turtle_commands[i+2:]
            else:
                new_commands = recursion_pass(excerpt, n = n + 1)
                turtle_commands = merge_commands(turtle_commands, new_commands, i, closing_unwind)
                i += len(new_commands)
        else:
            recorded.append(c)
            i += 1

    if n != 0:
        return turtle_commands + reverse_commands(recorded)
    else:
        return turtle_commands

def lsys_to_turtle(variables, constants, seed, translation):
    translation_rules = lsys_gen_translation(variables, constants, translation)
    turtle_commands = [translation_rules[s] for s in seed if s in translation_rules]

    turtle_commands = recursion_pass(turtle_commands)

    return turtle_commands

def turtle_draw(turtle_commands):
    import turtle

    t = turtle.Turtle()
    t.speed(10)
    t._tracer(0, 0)

    turtle_to_python_turtle = {
        "forward": t.forward,
        "right": t.right,
        "left": t.left,
        "backward": t.backward
    }

    for c in turtle_commands:
        tc, v = c.split(" ")
        tc_py = turtle_to_python_turtle[tc]
        v_i = float(v)
        tc_py(v_i)

    
    t._update()
    turtle.done()


def test1():
    variables = "F G"
    constants = "+ -"
    seed = "F-G-G"
    ignore = ""
    rules = "(F -> F-G+F+G-F), (G -> GG)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 3)

    translation = "(F -> forward 5), (G -> forward 5), (+ -> right 120), (- -> left 120)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    turtle_draw(turtle_commands)

def test2():
    variables = "F"
    constants = "+ -"
    seed = "F"
    ignore = ""
    rules = "(F -> F+F-F-F+F)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 6)

    translation = "(F -> forward 5), (+ -> right 90), (- -> left 90)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    turtle_draw(turtle_commands)

def test3():
    variables = "X Y"
    constants = "F - +"
    seed = "FX"
    ignore = "F"
    rules = "(X -> X+YF+), (Y -> -FX-Y)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 12)

    translation = "(F -> forward 5), (+ -> right 90), (- -> left 90)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    turtle_draw(turtle_commands)

def test4():
    variables = "X F"
    constants = "+ - [ ]"
    seed = "X"
    ignore = ""
    rules = "(X -> F+[[X]-X]-F[-FX]+X), (F -> FF)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 6)

    translation = "(F -> backward 2), (+ -> right 25), (- -> left 25), ([ -> record), (] -> unwind)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    turtle_draw(turtle_commands)

def test5():
    variables = "0 1 + -"
    constants = "F [ ]"
    seed = "F0F1F1"
    ignore = "F + -"
    rules = "(0<0>0 -> 1), (0<0>1 -> 0), (0<1>0 -> 0), (0<1>1 -> 1F1), \
             (1<0>0 -> 1), (1<0>1 -> 1[+F1F1]), (1<1>0 -> 1), (1<1>1 -> 0), \
             (+ -> -), (- -> +)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 24)
    print(result)
    
    translation = "(F -> forward 6), (+ -> right 25.75), (- -> left 25.75), ([ -> record), (] -> unwind)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    turtle_draw(turtle_commands)

def test6():
    variables = "F"
    constants = "+ - [ ]"
    seed = "F"
    ignore = ""
    rules = "(F -> F[+FF][-FF]F[-F][+F]F)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 4)

    translation = "(F -> forward 8), (+ -> right 35), (- -> left 35), ([ -> record), (] -> unwind)"
    turtle_commands1 = lsys_to_turtle(variables, constants, result, translation)

    translation = "(F -> backward 8), (+ -> right 35), (- -> left 35), ([ -> record), (] -> unwind)"
    turtle_commands2 = lsys_to_turtle(variables, constants, result, translation)

    turtle_commands = turtle_commands1 + turtle_commands2

    turtle_draw(turtle_commands)

def test7():
    variables = "X F Y"
    constants = "+ - [ ]"
    seed = "F"
    ignore = ""
    rules = "(X -> +FY), (F -> FF-[XY]+[XY]), (Y -> -FX)"

    result = lsys_expand_n(variables, constants, rules, ignore, seed, 5)

    translation = "(F -> forward 5), (+ -> right 35), (- -> left 33), ([ -> record), (] -> unwind)"
    turtle_commands = lsys_to_turtle(variables, constants, result, translation)

    print(len(turtle_commands))

    turtle_draw(turtle_commands)


if __name__ == "__main__":
    #test1()
    #test2()
    test1()

# multiple contexts for variables! - works or no? i dont think so, but table it for now?
# -- there are still a lot of cool l systems that don't need a context-sensitive description
# translation is kinda slow! oh well, probably good enough.

# links:
# http://paulbourke.net/fractals/lsys/
# http://algorithmicbotany.org/papers/abop/abop-ch1.pdf

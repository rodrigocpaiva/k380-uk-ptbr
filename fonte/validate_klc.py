#!/usr/bin/env python3
"""validate_klc.py: valida UKPTINT.klc e simula as teclas mortas.

Uso: python validate_klc.py [caminho.klc]
Saida 0 quando tudo passa, 1 quando algo falha.
"""
import re
import sys
from pathlib import Path

SECTIONS = {
    "KBD", "COPYRIGHT", "COMPANY", "LOCALENAME", "LOCALEID", "VERSION",
    "ATTRIBUTES", "SHIFTSTATE", "LAYOUT", "DEADKEY", "LIGATURE", "KEYNAME",
    "KEYNAME_EXT", "KEYNAME_DEAD", "DESCRIPTIONS", "LANGUAGENAMES", "ENDKBD",
}
VALUE_RE = re.compile(r"-1|[0-9a-f]{4}@?")

failures = 0


def report(ok, label):
    global failures
    if not ok:
        failures += 1
    print(f"{'PASS' if ok else 'FAIL'}  {label}")


def strip_comment(line):
    i = line.find("//")
    return line if i < 0 else line[:i]


def parse_value(v):
    """'-1' -> None; 'xxxx' -> (char, False); 'xxxx@' -> (char, True)."""
    if v == "-1":
        return None
    return chr(int(v.rstrip("@"), 16)), v.endswith("@")


# ---------------------------------------------------------------- estrutura
def check_structure(path):
    raw = Path(path).read_bytes()
    report(raw[:2] == b"\xff\xfe", "BOM UTF-16 LE")
    text = raw[2:].decode("utf-16-le")
    lone_lf = re.search(r"(?<!\r)\n", text) is not None
    lone_cr = re.search(r"\r(?!\n)", text) is not None
    report(not lone_lf and not lone_cr, "Quebras de linha CRLF")

    shiftstates, layout, deadkeys, keyname_dead = [], {}, {}, set()
    vks, kbd_name = {}, None
    section, current_dead = None, None
    layout_ok, values_ok = True, True

    for n, line in enumerate(text.split("\r\n"), 1):
        fields = strip_comment(line).split()
        if not fields:
            continue
        head = fields[0]
        if head in SECTIONS:
            section = head
            if head == "KBD":
                kbd_name = fields[1] if len(fields) > 1 else ""
            elif head == "DEADKEY":
                current_dead = fields[1]
                deadkeys[current_dead] = {}
            continue
        if section == "SHIFTSTATE":
            shiftstates.append(int(head))
        elif section == "LAYOUT":
            if len(fields) != 8:
                layout_ok = False
                print(f"      linha {n}: {len(fields)} campos em vez de 8")
                continue
            sc, vk, cap, *vals = fields
            if sc in layout:
                report(False, f"SC duplicado: {sc} (linha {n})")
            if vk in vks:
                report(False, f"VK duplicado: {vk} em {vks[vk]} e {sc}")
            vks[vk] = sc
            for v in vals:
                if not VALUE_RE.fullmatch(v):
                    values_ok = False
                    print(f"      linha {n}: valor fora do formato: {v}")
            layout[sc] = {"vk": vk, "cap": cap,
                          "cols": dict(zip(shiftstates, vals))}
        elif section == "DEADKEY":
            deadkeys[current_dead][fields[0]] = fields[1]
        elif section == "KEYNAME_DEAD":
            keyname_dead.add(head)

    report(kbd_name is not None and 0 < len(kbd_name) <= 8,
           f"Nome KBD com no maximo 8 caracteres ({kbd_name})")
    report(shiftstates == [0, 1, 2, 6, 7], f"SHIFTSTATE 0 1 2 6 7 ({shiftstates})")
    report(layout_ok, "8 campos em toda linha do LAYOUT")
    report(values_ok, "Valores do LAYOUT em hex minusculo de 4 digitos ou -1")
    report(len(layout) == len(set(layout)), f"SC sem duplicata ({len(layout)} teclas)")

    used_dead = {v.rstrip("@") for k in layout.values()
                 for v in k["cols"].values() if v.endswith("@")}
    for d in sorted(used_dead):
        report(d in deadkeys, f"Tecla morta {d} tem DEADKEY")
        report(d in keyname_dead, f"Tecla morta {d} tem KEYNAME_DEAD")
        report("0020" in deadkeys.get(d, {}), f"Tecla morta {d} tem saida com espaco")
        report(d not in deadkeys.get(d, {}), f"Tecla morta {d} sem auto-mapeamento")
    for d in sorted(set(deadkeys) - used_dead):
        report(False, f"DEADKEY {d} sem tecla no LAYOUT")
    return layout, deadkeys


# --------------------------------------------------------------- simulador
ISO, APOS, HASH, TOP, SPACE = "56", "28", "2b", "29", "39"
LETTER_SC = dict(zip("QWERTYUIOPASDFGHJKLZXCVBNM",
                     "10 11 12 13 14 15 16 17 18 19 1e 1f 20 21 22 23 24 25 26 "
                     "2c 2d 2e 2f 30 31 32".split()))
DIGIT_SC = {str(d): f"{d + 1:02x}" for d in range(1, 10)}
DIGIT_SC["0"] = "0b"


def key(sc, shift=False, altgr=False):
    return sc, (7 if shift else 6) if altgr else (1 if shift else 0)


def letter(ch, altgr=False):
    return key(LETTER_SC[ch.upper()], shift=ch.isupper(), altgr=altgr)


def type_keys(layout, deadkeys, strokes):
    """Simula o Windows: morta + caractere da tabela = composto;
    morta + caractere fora da tabela = os dois caracteres."""
    out, pending = "", None
    for sc, state in strokes:
        v = parse_value(layout[sc]["cols"].get(state, "-1"))
        if v is None:
            continue
        ch, dead = v
        if pending is None:
            if dead:
                pending = ch
            else:
                out += ch
            continue
        table = deadkeys[f"{ord(pending):04x}"]
        composed = table.get(f"{ord(ch):04x}")
        out += chr(int(composed, 16)) if composed else pending + ch
        pending = None
    return out + (pending or "")


def run_tests(layout, deadkeys):
    iso, s_iso = key(ISO), key(ISO, shift=True)
    apos, sp = key(APOS), key(SPACE)
    six = key(DIGIT_SC["6"], shift=True)
    tests = [
        ("' + a", [apos, letter("a")], "á"),
        ("' + E", [apos, letter("E")], "É"),
        ("' + c", [apos, letter("c")], "ç"),
        ("' + C", [apos, letter("C")], "Ç"),
        ("' + espaco", [apos, sp], "'"),
        ("' + s", [apos, letter("s")], "'s"),
        ("' + '", [apos, apos], "''"),
        ("ISO + a", [iso, letter("a")], "à"),
        ("ISO + A", [iso, letter("A")], "À"),
        ("ISO + espaco", [iso, sp], "`"),
        ("ISO + ISO", [iso, iso], "``"),
        ("ISO + x", [iso, letter("x")], "`x"),
        ("ISO ISO ISO + j (Markdown)", [iso, iso, iso, letter("j")], "```j"),
        ("Shift+ISO + a", [s_iso, letter("a")], "ã"),
        ("Shift+ISO + O", [s_iso, letter("O")], "Õ"),
        ("Shift+ISO + n", [s_iso, letter("n")], "ñ"),
        ("Shift+ISO + espaco", [s_iso, sp], "~"),
        ("Shift+6 + e", [six, letter("e")], "ê"),
        ("Shift+6 + O", [six, letter("O")], "Ô"),
        ("Shift+6 + espaco", [six, sp], "^"),
        ("Shift+6 + 2", [six, key(DIGIT_SC["2"])], "^2"),
        ("Tecla # (3a a direita do L)", [key(HASH)], "\\"),
        ("Shift + tecla #", [key(HASH, shift=True)], "|"),
        ("Shift+2", [key(DIGIT_SC["2"], shift=True)], "@"),
        ("Shift+'", [key(APOS, shift=True)], '"'),
        ("Shift+3", [key(DIGIT_SC["3"], shift=True)], "#"),
        ("AltGr+3", [key(DIGIT_SC["3"], altgr=True)], "£"),
        ("AltGr+2", [key(DIGIT_SC["2"], altgr=True)], "€"),
        ("AltGr+4", [key(DIGIT_SC["4"], altgr=True)], "€"),
        ("AltGr+C", [letter("c", altgr=True)], "ç"),
        ("AltGr+Shift+C", [letter("C", altgr=True)], "Ç"),
        ("AltGr+E", [letter("e", altgr=True)], "é"),
        ("Tecla acima do Tab", [key(TOP)], "§"),
        ("Shift + tecla acima do Tab", [key(TOP, shift=True)], "±"),
    ]
    for label, strokes, expected in tests:
        got = type_keys(layout, deadkeys, strokes)
        report(got == expected, f"{label} = {expected!r}" +
               ("" if got == expected else f" (obtido {got!r})"))


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    path = sys.argv[1] if len(sys.argv) > 1 else Path(__file__).with_name("UKPTINT.klc")
    print(f"Arquivo: {path}\n\n== Estrutura ==")
    layout, deadkeys = check_structure(path)
    print("\n== Simulador ==")
    run_tests(layout, deadkeys)
    print(f"\n{'OK: tudo passou' if failures == 0 else f'{failures} falha(s)'}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()

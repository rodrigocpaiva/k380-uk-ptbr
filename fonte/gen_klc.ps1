# gen_klc.ps1
# Gera UKPTINT.klc (fonte do Microsoft Keyboard Layout Creator 1.4) para o
# Logitech K380 UK: base "Reino Unido", pontuacao pelas legendas Mac (lado
# direito das teclas) e teclas mortas para o portugues do Brasil.
# Saida: UTF-16 LE com BOM e quebras CRLF (exigencia do MSKLC).
#
# Uso: powershell -ExecutionPolicy Bypass -File .\gen_klc.ps1

# ---- Constantes (troque aqui) ---------------------------------------------
$KBD_NAME   = 'UKPTINT'                  # no maximo 8 caracteres
$KBD_DESC   = 'UK Intl PT-BR (acentos)'
$COPYRIGHT  = '(c) 2026'
$COMPANY    = 'Personal'
$LOCALENAME = 'pt-BR'
$LOCALEID   = '00000416'
$VERSION    = '1.0'
$LANG_ID    = '0416'
$LANG_NAME  = 'Portuguese (Brazil)'
# Alternativa: registrar o layout sob o idioma Ingles (Reino Unido).
# $LOCALENAME = 'en-GB'
# $LOCALEID   = '00000809'
# $LANG_ID    = '0809'
# $LANG_NAME  = 'English (United Kingdom)'
$OUT_FILE   = Join-Path $PSScriptRoot "$KBD_NAME.klc"
# ---------------------------------------------------------------------------

# Teclas nao letras: SC VK Cap c0 c1 c2 c6 c7 (c6 = AltGr, c7 = Shift+AltGr)
$nonLetters = @(
    '29 OEM_8      0 00a7  00b1  -1   00a6 00ac'   # acima do Tab: legenda Mac
    '02 1          0 0031  0021  -1   -1   -1'
    '03 2          0 0032  0040  -1   20ac -1'     # Shift+2 = @ (Mac), AltGr = euro
    '04 3          0 0033  0023  -1   00a3 -1'     # Shift+3 = #, AltGr = libra
    '05 4          0 0034  0024  -1   20ac -1'
    '06 5          0 0035  0025  -1   -1   -1'
    '07 6          0 0036  005e@ -1   -1   -1'     # circunflexo morto
    '08 7          0 0037  0026  -1   -1   -1'
    '09 8          0 0038  002a  -1   -1   -1'
    '0a 9          0 0039  0028  -1   -1   -1'
    '0b 0          0 0030  0029  -1   -1   -1'
    '0c OEM_MINUS  0 002d  005f  -1   -1   -1'
    '0d OEM_PLUS   0 003d  002b  -1   -1   -1'
    '1a OEM_4      0 005b  007b  001b -1   -1'
    '1b OEM_6      0 005d  007d  001d -1   -1'
    '27 OEM_1      0 003b  003a  -1   -1   -1'
    '28 OEM_3      0 0027@ 0022  -1   -1   -1'     # apostrofo morto (agudo e cedilha), Shift = aspas
    '2b OEM_7      0 005c  007c  001c -1   -1'     # 3a a direita do L: \ e |
    '56 OEM_5      0 0060@ 007e@ -1   -1   -1'     # ISO: crase e til mortos
    '33 OEM_COMMA  0 002c  003c  -1   -1   -1'
    '34 OEM_PERIOD 0 002e  003e  -1   -1   -1'
    '35 OEM_2      0 002f  003f  -1   -1   -1'
    '39 SPACE      0 0020  0020  0020 -1   -1'
    '53 DECIMAL    0 002e  002e  -1   -1   -1'
)

$letterSc = [ordered]@{
    Q='10'; W='11'; E='12'; R='13'; T='14'; Y='15'; U='16'; I='17'; O='18'; P='19'
    A='1e'; S='1f'; D='20'; F='21'; G='22'; H='23'; J='24'; K='25'; L='26'
    Z='2c'; X='2d'; C='2e'; V='2f'; B='30'; N='31'; M='32'
}

# AltGr nas letras: minuscula, maiuscula
$altGrLetters = @{
    A=@('00e1','00c1'); E=@('00e9','00c9'); I=@('00ed','00cd')
    O=@('00f3','00d3'); U=@('00fa','00da'); C=@('00e7','00c7')
}

# Teclas mortas, sem auto-mapeamento: morta + caractere fora da tabela
# emite os dois caracteres (comportamento igual ao do Mac).
$deadKeys = [ordered]@{
    '0027' = @{ Name = 'APOSTROPHE'; Map = [ordered]@{
        '0061'='00e1'; '0065'='00e9'; '0069'='00ed'; '006f'='00f3'; '0075'='00fa'
        '0041'='00c1'; '0045'='00c9'; '0049'='00cd'; '004f'='00d3'; '0055'='00da'
        '0063'='00e7'; '0043'='00c7'; '0020'='0027' } }
    '0060' = @{ Name = 'GRAVE ACCENT'; Map = [ordered]@{
        '0061'='00e0'; '0065'='00e8'; '0069'='00ec'; '006f'='00f2'; '0075'='00f9'
        '0041'='00c0'; '0045'='00c8'; '0049'='00cc'; '004f'='00d2'; '0055'='00d9'
        '0020'='0060' } }
    '007e' = @{ Name = 'TILDE'; Map = [ordered]@{
        '0061'='00e3'; '006f'='00f5'; '006e'='00f1'
        '0041'='00c3'; '004f'='00d5'; '004e'='00d1'
        '0020'='007e' } }
    '005e' = @{ Name = 'CIRCUMFLEX ACCENT'; Map = [ordered]@{
        '0061'='00e2'; '0065'='00ea'; '0069'='00ee'; '006f'='00f4'; '0075'='00fb'
        '0041'='00c2'; '0045'='00ca'; '0049'='00ce'; '004f'='00d4'; '0055'='00db'
        '0020'='005e' } }
}

$keyNames = @(
    '01 Esc', '0e Backspace', '0f Tab', '1c Enter', '1d Ctrl', '2a Shift',
    '36 "Right Shift"', '37 "Num *"', '38 Alt', '39 Space', '3a "Caps Lock"',
    '3b F1', '3c F2', '3d F3', '3e F4', '3f F5', '40 F6', '41 F7', '42 F8',
    '43 F9', '44 F10', '45 Pause', '46 "Scroll Lock"', '47 "Num 7"',
    '48 "Num 8"', '49 "Num 9"', '4a "Num -"', '4b "Num 4"', '4c "Num 5"',
    '4d "Num 6"', '4e "Num +"', '4f "Num 1"', '50 "Num 2"', '51 "Num 3"',
    '52 "Num 0"', '53 "Num Del"', '54 "Sys Req"', '57 F11', '58 F12',
    '7c F13', '7d F14', '7e F15', '7f F16', '80 F17', '81 F18', '82 F19',
    '83 F20', '84 F21', '85 F22', '86 F23', '87 F24'
)
$keyNamesExt = @(
    '1c "Num Enter"', '1d "Right Ctrl"', '35 "Num /"', '37 "Prnt Scrn"',
    '38 "Right Alt"', '45 "Num Lock"', '46 Break', '47 Home', '48 Up',
    '49 "Page Up"', '4b Left', '4d Right', '4f End', '50 Down',
    '51 "Page Down"', '52 Insert', '53 Delete', '54 <00>', '56 Help',
    '5b "Left Windows"', '5c "Right Windows"', '5d Application'
)

# Comentarios so com letras e digitos: aspas, apostrofo e barra invertida
# nos comentarios confundem o leitor da interface do MSKLC.
function Show-Char([string]$v) {
    if ($v -eq '-1') { return 'none' }
    $code = [Convert]::ToInt32($v.TrimEnd('@'), 16)
    if ($code -lt 0x20) { return ('U+{0:X4}' -f $code) }
    if ([char]::IsLetterOrDigit([char]$code)) { $s = [string][char]$code }
    else { $s = 'U+{0:X4}' -f $code }
    if ($v.EndsWith('@')) { $s += ' dead' }
    return $s
}

function Format-Row([string[]]$f) {
    $comment = ($f[3..7] | ForEach-Object { Show-Char $_ }) -join ', '
    return (($f -join "`t") + "`t// " + $comment)
}

if ($KBD_NAME.Length -gt 8) { throw "KBD_NAME com mais de 8 caracteres: $KBD_NAME" }

$out = New-Object System.Collections.Generic.List[string]
$out.Add("KBD`t$KBD_NAME`t`"$KBD_DESC`"")
$out.Add('')
$out.Add("COPYRIGHT`t`"$COPYRIGHT`"")
$out.Add('')
$out.Add("COMPANY`t`"$COMPANY`"")
$out.Add('')
$out.Add("LOCALENAME`t`"$LOCALENAME`"")
$out.Add('')
$out.Add("LOCALEID`t`"$LOCALEID`"")
$out.Add('')
$out.Add("VERSION`t$VERSION")
$out.Add('')
$out.Add('SHIFTSTATE')
$out.Add('')
$out.Add("0`t//Column 4")
$out.Add("1`t//Column 5 : Shift")
$out.Add("2`t//Column 6 :       Ctrl")
$out.Add("6`t//Column 7 :       Ctrl Alt")
$out.Add("7`t//Column 8 : Shift Ctrl Alt")
$out.Add('')
$out.Add("LAYOUT`t`t// an extra at sign at the end is a dead key")
$out.Add('')
$out.Add("//SC`tVK_`tCap`t0`t1`t2`t6`t7")
$out.Add("//--`t----`t----`t----`t----`t----`t----`t----")
$out.Add('')

$rows = @()
foreach ($line in $nonLetters) {
    $rows += ,($line -split '\s+')
}
foreach ($letter in $letterSc.Keys) {
    $lower = '{0:x4}' -f [int][char]$letter.ToLower()
    $upper = '{0:x4}' -f [int][char]$letter
    $ctrl  = '-1'   # Ctrl+letra o Windows gera sozinho; o MSKLC avisa se for definido
    if ($altGrLetters.ContainsKey($letter)) {
        $ag = $altGrLetters[$letter]
        $rows += ,@($letterSc[$letter], $letter, '5', $lower, $upper, $ctrl, $ag[0], $ag[1])
    } else {
        $rows += ,@($letterSc[$letter], $letter, '1', $lower, $upper, $ctrl, '-1', '-1')
    }
}
$rows = $rows | Sort-Object { [Convert]::ToInt32($_[0], 16) }
foreach ($r in $rows) { $out.Add((Format-Row $r)) }
$out.Add('')

foreach ($dk in $deadKeys.Keys) {
    $out.Add('')
    $out.Add("DEADKEY`t$dk")
    $out.Add('')
    $map = $deadKeys[$dk].Map
    foreach ($in in $map.Keys) {
        $o = $map[$in]
        $inShow = Show-Char $in
        $out.Add("$in`t$o`t// $inShow to $(Show-Char $o)")
    }
}
$out.Add('')

$out.Add('KEYNAME')
$out.Add('')
foreach ($k in $keyNames) { $p = $k -split ' ', 2; $out.Add("$($p[0])`t$($p[1])") }
$out.Add('')
$out.Add('KEYNAME_EXT')
$out.Add('')
foreach ($k in $keyNamesExt) { $p = $k -split ' ', 2; $out.Add("$($p[0])`t$($p[1])") }
$out.Add('')
$out.Add('KEYNAME_DEAD')
$out.Add('')
foreach ($dk in $deadKeys.Keys) { $out.Add("$dk`t`"$($deadKeys[$dk].Name)`"") }
$out.Add('')
# MSKLC grava DESCRIPTIONS e LANGUAGENAMES sem aspas (aspas virariam parte do nome)
$out.Add('DESCRIPTIONS')
$out.Add('')
$out.Add("$LANG_ID`t$KBD_DESC")
$out.Add('')
$out.Add('LANGUAGENAMES')
$out.Add('')
$out.Add("$LANG_ID`t$LANG_NAME")
$out.Add('')
$out.Add('ENDKBD')
$out.Add('')

$text  = ($out -join "`r`n")
$bytes = [byte[]](0xFF, 0xFE) + [System.Text.Encoding]::Unicode.GetBytes($text)
[System.IO.File]::WriteAllBytes($OUT_FILE, $bytes)
Write-Host "Gerado: $OUT_FILE ($($bytes.Length) bytes)"

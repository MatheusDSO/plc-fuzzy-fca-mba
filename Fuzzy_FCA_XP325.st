// =========================================================================
// ALGORITMO FUZZY TIPO-1 - ABORDAGEM FCA (FUNCTION COMPUTATION APPROACH)
// Hardware: CLP Altus Nexto XP325 (ARM 32-bit com FPU)
// Software: MasterTool IEC XE (CODESYS) - Norma IEC 61131-3 Structured Text
// Autores: Matheus dos Santos Oliveira e Prof. Dr. Willian R. B. M. Nunes
// =========================================================================

// ====== VARIAVEIS GLOBAIS E DE PROCESSO ====== //
{attribute 'qualified_only'}
VAR_GLOBAL
    rInputSpeed     : REAL := 0.0; // Entrada: Velocidade do veiculo (0 a 180 km/h)
    rInputMass      : REAL := 0.0; // Entrada: Massa do veiculo (0 a 2.4 ton)
    rOutputPressure : REAL := 0.0; // Saida: Pressao de frenagem (0 a 1.0 atm)
END_VAR

// ====== FUNCAO PARA PERTINENCIA TRIANGULAR ====== //
FUNCTION FUZZY_TRIAN : REAL
VAR_INPUT
    a : REAL; // Inicio da base do triangulo
    m : REAL; // Pico do triangulo
    b : REAL; // Fim da base do triangulo
    x : REAL; // Valor de entrada (velocidade ou massa)
END_VAR

IF x > a AND x < m THEN
    FUZZY_TRIAN := (x - a) / (m - a);
ELSIF x = m THEN
    FUZZY_TRIAN := 1.0;
ELSIF x > m AND x < b THEN
    FUZZY_TRIAN := (b - x) / (b - m);
ELSE
    FUZZY_TRIAN := 0.0;
END_IF;

// ====== FUNCAO PARA PERTINENCIA TRAPEZOIDAL ASCENDENTE ====== //
FUNCTION FUZZY_TRAP_ASC : REAL
VAR_INPUT
    a : REAL; // Inicio da rampa de subida
    m : REAL; // Inicio do patamar superior
    b : REAL; // Fim do patamar superior
    x : REAL; // Valor de entrada
END_VAR

IF x <= a THEN
    FUZZY_TRAP_ASC := 0.0;
ELSIF x > a AND x < m THEN
    FUZZY_TRAP_ASC := (x - a) / (m - a);
ELSIF x >= m AND x <= b THEN
    FUZZY_TRAP_ASC := 1.0;
ELSE
    FUZZY_TRAP_ASC := 0.0;
END_IF;

// ====== FUNCAO PARA PERTINENCIA TRAPEZOIDAL DESCENDENTE ====== //
FUNCTION FUZZY_TRAP_DESC : REAL
VAR_INPUT
    a : REAL; // Inicio do patamar superior
    m : REAL; // Fim do patamar superior
    b : REAL; // Fim da rampa de descida
    x : REAL; // Valor de entrada
END_VAR

IF x >= a AND x <= m THEN
    FUZZY_TRAP_DESC := 1.0;
ELSIF x > m AND x < b THEN
    FUZZY_TRAP_DESC := (b - x) / (b - m);
ELSE
    FUZZY_TRAP_DESC := 0.0;
END_IF;

// ====== PROGRAMA PRINCIPAL (UserPrg) ====== //
PROGRAM UserPrg
VAR
    nSpeed : REAL := 0.0;
    nMass  : REAL := 0.0;
    // Graus de Pertinencia
    uS : ARRAY [0..4] OF REAL;
    uM : ARRAY [0..4] OF REAL;
    // Pesos das Regras
    wVL, wL, wM, wH, wVH : REAL;
    // Defuzzificacao (COA)
    nNumerator, nDenominator : LREAL;
    rPos : REAL;
    i    : INT;
    mu_p : REAL;
END_VAR

// 1. RECEBE AS VARIAVEIS GLOBAIS
nSpeed := Global_Fuzzy.rInputSpeed;
nMass  := Global_Fuzzy.rInputMass;

// 2. FUZZIFICACAO (Calculo em Ponto Flutuante em Tempo Real)
uS[0] := FUZZY_TRAP_DESC(0.0, 30.0, 60.0, nSpeed);
uS[1] := FUZZY_TRIAN(30.0, 60.0, 90.0, nSpeed);
uS[2] := FUZZY_TRIAN(60.0, 90.0, 120.0, nSpeed);
uS[3] := FUZZY_TRIAN(90.0, 120.0, 150.0, nSpeed);
uS[4] := FUZZY_TRAP_ASC(120.0, 150.0, 180.0, nSpeed);

uM[0] := FUZZY_TRAP_DESC(0.0, 0.4, 0.8, nMass);
uM[1] := FUZZY_TRIAN(0.4, 0.8, 1.2, nMass);
uM[2] := FUZZY_TRIAN(0.8, 1.2, 1.6, nMass);
uM[3] := FUZZY_TRIAN(1.2, 1.6, 2.0, nMass);
uM[4] := FUZZY_TRAP_ASC(1.6, 2.0, 2.4, nMass);

// 3. INFERENCIA DE MAMDANI (25 Regras - Operadores MIN e MAX)
wVL := 0.0; wL := 0.0; wM := 0.0; wH := 0.0; wVH := 0.0;

// Regras para Massa VERY SMALL (uM[0])
wVL := MAX(wVL, MIN(uS[0], uM[0]));
wVL := MAX(wVL, MIN(uS[1], uM[0]));
wL  := MAX(wL,  MIN(uS[2], uM[0]));
wM  := MAX(wM,  MIN(uS[3], uM[0]));
wH  := MAX(wH,  MIN(uS[4], uM[0]));

// Regras para Massa SMALL (uM[1])
wVL := MAX(wVL, MIN(uS[0], uM[1]));
wVL := MAX(wVL, MIN(uS[1], uM[1]));
wM  := MAX(wM,  MIN(uS[2], uM[1]));
wM  := MAX(wM,  MIN(uS[3], uM[1]));
wH  := MAX(wH,  MIN(uS[4], uM[1]));

// Regras para Massa MEDIUM (uM[2])
wVL := MAX(wVL, MIN(uS[0], uM[2]));
wL  := MAX(wL,  MIN(uS[1], uM[2]));
wM  := MAX(wM,  MIN(uS[2], uM[2]));
wH  := MAX(wH,  MIN(uS[3], uM[2]));
wVH := MAX(wVH, MIN(uS[4], uM[2]));

// Regras para Massa LARGE (uM[3])
wL  := MAX(wL,  MIN(uS[0], uM[3]));
wL  := MAX(wL,  MIN(uS[1], uM[3]));
wH  := MAX(wH,  MIN(uS[2], uM[3]));
wVH := MAX(wVH, MIN(uS[3], uM[3]));
wVH := MAX(wVH, MIN(uS[4], uM[3]));

// Regras para Massa VERY LARGE (uM[4])
wL  := MAX(wL,  MIN(uS[0], uM[4]));
wM  := MAX(wM,  MIN(uS[1], uM[4]));
wH  := MAX(wH,  MIN(uS[2], uM[4]));
wVH := MAX(wVH, MIN(uS[3], uM[4]));
wVH := MAX(wVH, MIN(uS[4], uM[4]));

// 4. DEFUZZIFICACAO COA (101 pontos no universo de 0.0 a 1.0 atm)
nNumerator   := 0.0;
nDenominator := 0.0;

FOR i := 0 TO 100 DO
    rPos := INT_TO_REAL(i) / 100.0;
    
    mu_p := MIN(wVL, FUZZY_TRAP_DESC(0.0, 0.166, 0.333, rPos));
    mu_p := MAX(mu_p, MIN(wL,  FUZZY_TRIAN(0.166, 0.333, 0.500, rPos)));
    mu_p := MAX(mu_p, MIN(wM,  FUZZY_TRIAN(0.333, 0.500, 0.667, rPos)));
    mu_p := MAX(mu_p, MIN(wH,  FUZZY_TRIAN(0.500, 0.667, 0.833, rPos)));
    mu_p := MAX(mu_p, MIN(wVH, FUZZY_TRAP_ASC(0.667, 0.833, 1.000, rPos)));
    
    IF mu_p > 0.0 THEN
        nNumerator   := nNumerator + (REAL_TO_LREAL(mu_p) * REAL_TO_LREAL(rPos));
        nDenominator := nDenominator + REAL_TO_LREAL(mu_p);
    END_IF;
END_FOR;

IF nDenominator > 0.0 THEN
    Global_Fuzzy.rOutputPressure := LREAL_TO_REAL(nNumerator / nDenominator);
ELSE
    Global_Fuzzy.rOutputPressure := 0.0;
END_IF;

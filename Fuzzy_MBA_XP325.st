// =========================================================================
// ALGORITMO FUZZY TIPO-1 - ABORDAGEM MBA (MEMORY BASED APPROACH)
// Hardware: CLP Altus Nexto XP325 (ARM 32-bit)
// Software: MasterTool IEC XE (CODESYS) - Norma IEC 61131-3 Structured Text
// Autores: Matheus dos Santos Oliveira e Prof. Dr. Willian R. B. M. Nunes
// =========================================================================

// ====== VARIAVEIS GLOBAIS E DE PROCESSO ====== //
{attribute 'qualified_only'}
VAR_GLOBAL
    rInputSpeed     : REAL := 0.0;
    rInputMass      : REAL := 0.0;
    rOutputPressure : REAL := 0.0;
END_VAR

// ====== TABELAS DE CONSULTA (LOOKUP TABLES - GVL_MBA) ====== //
VAR_GLOBAL
    LUT_Speed    : ARRAY [0..4] OF ARRAY [0..1000] OF INT;
    LUT_Mass     : ARRAY [0..4] OF ARRAY [0..1000] OF INT;
    bInitialized : BOOL := FALSE;
END_VAR

// ====== FUNCOES EM PONTO FIXO (ESCALA 0 A 1000) ====== //
FUNCTION FUZZY_TRIAN : INT
VAR_INPUT
    a, m, b, x : INT;
END_VAR

IF x > a AND x < m THEN
    FUZZY_TRIAN := REAL_TO_INT(((INT_TO_REAL(x - a)) * 1000.0) / INT_TO_REAL(m - a));
ELSIF x = m THEN
    FUZZY_TRIAN := 1000;
ELSIF x > m AND x < b THEN
    FUZZY_TRIAN := REAL_TO_INT(((INT_TO_REAL(b - x)) * 1000.0) / INT_TO_REAL(b - m));
ELSE
    FUZZY_TRIAN := 0;
END_IF;

FUNCTION FUZZY_TRAP_ASC : INT
VAR_INPUT
    a, m, b, x : INT;
END_VAR

IF x <= a THEN
    FUZZY_TRAP_ASC := 0;
ELSIF x > a AND x < m THEN
    FUZZY_TRAP_ASC := REAL_TO_INT(((INT_TO_REAL(x - a)) * 1000.0) / INT_TO_REAL(m - a));
ELSIF x >= m AND x <= b THEN
    FUZZY_TRAP_ASC := 1000;
ELSE
    FUZZY_TRAP_ASC := 0;
END_IF;

FUNCTION FUZZY_TRAP_DESC : INT
VAR_INPUT
    a, m, b, x : INT;
END_VAR

IF x >= a AND x <= m THEN
    FUZZY_TRAP_DESC := 1000;
ELSIF x > m AND x < b THEN
    FUZZY_TRAP_DESC := REAL_TO_INT(((INT_TO_REAL(b - x)) * 1000.0) / INT_TO_REAL(b - m));
ELSE
    FUZZY_TRAP_DESC := 0;
END_IF;

// ====== ROTINA DE INICIALIZACAO DAS TABELAS (EXECUTADA NO PRIMEIRO SCAN) ====== //
PROGRAM Init_MBA
VAR
    i : INT;
END_VAR

IF NOT GVL_MBA.bInitialized THEN
    FOR i := 0 TO 1000 DO
        // Preenche tabelas de Velocidade
        GVL_MBA.LUT_Speed[0][i] := FUZZY_TRAP_DESC(0, 166, 333, i);
        GVL_MBA.LUT_Speed[1][i] := FUZZY_TRIAN(166, 333, 500, i);
        GVL_MBA.LUT_Speed[2][i] := FUZZY_TRIAN(333, 500, 666, i);
        GVL_MBA.LUT_Speed[3][i] := FUZZY_TRIAN(500, 666, 833, i);
        GVL_MBA.LUT_Speed[4][i] := FUZZY_TRAP_ASC(666, 833, 1000, i);
        
        // Preenche tabelas de Massa
        GVL_MBA.LUT_Mass[0][i] := FUZZY_TRAP_DESC(0, 166, 333, i);
        GVL_MBA.LUT_Mass[1][i] := FUZZY_TRIAN(166, 333, 500, i);
        GVL_MBA.LUT_Mass[2][i] := FUZZY_TRIAN(333, 500, 666, i);
        GVL_MBA.LUT_Mass[3][i] := FUZZY_TRIAN(500, 666, 833, i);
        GVL_MBA.LUT_Mass[4][i] := FUZZY_TRAP_ASC(666, 833, 1000, i);
    END_FOR;
    GVL_MBA.bInitialized := TRUE;
END_IF;

// ====== PROGRAMA PRINCIPAL (UserPrg) ====== //
PROGRAM UserPrg
VAR
    nSpeed, nMass : INT;
    uS, uM : ARRAY [0..4] OF INT;
    wVL, wL, wM, wH, wVH : INT;
    nNumerator, nDenominator : LREAL;
    i, mu_p, nCOA, nStartLoop, nEndLoop : INT;
END_VAR

// 1. Garante a inicializacao das tabelas
Init_MBA();

// 2. Normaliza as entradas fisicas para escala inteira (0 a 1000)
nSpeed := REAL_TO_INT(Global_Fuzzy.rInputSpeed * (1000.0 / 180.0));
nMass  := REAL_TO_INT(Global_Fuzzy.rInputMass  * (1000.0 / 2.4));

// 3. FUZZIFICACAO MBA (Consulta direta em memoria RAM - O(1))
uS[0] := GVL_MBA.LUT_Speed[0][nSpeed];
uS[1] := GVL_MBA.LUT_Speed[1][nSpeed];
uS[2] := GVL_MBA.LUT_Speed[2][nSpeed];
uS[3] := GVL_MBA.LUT_Speed[3][nSpeed];
uS[4] := GVL_MBA.LUT_Speed[4][nSpeed];

uM[0] := GVL_MBA.LUT_Mass[0][nMass];
uM[1] := GVL_MBA.LUT_Mass[1][nMass];
uM[2] := GVL_MBA.LUT_Mass[2][nMass];
uM[3] := GVL_MBA.LUT_Mass[3][nMass];
uM[4] := GVL_MBA.LUT_Mass[4][nMass];

// 4. INFERENCIA DE MAMDANI (Ponto Fixo)
wVL := 0; wL := 0; wM := 0; wH := 0; wVH := 0;

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

// 5. DEFUZZIFICACAO COA (Centro de Area - 101 pontos de passo 10)
nNumerator   := 0.0;
nDenominator := 0.0;
nStartLoop   := 0;
nEndLoop     := 1000;

FOR i := nStartLoop TO nEndLoop BY 10 DO
    mu_p := MIN(wVL, FUZZY_TRAP_DESC(0, 166, 333, i));
    mu_p := MAX(mu_p, MIN(wL,  FUZZY_TRIAN(166, 333, 500, i)));
    mu_p := MAX(mu_p, MIN(wM,  FUZZY_TRIAN(333, 500, 666, i)));
    mu_p := MAX(mu_p, MIN(wH,  FUZZY_TRIAN(500, 666, 833, i)));
    mu_p := MAX(mu_p, MIN(wVH, FUZZY_TRAP_ASC(666, 833, 1000, i)));
    
    IF mu_p > 0 THEN
        nNumerator   := nNumerator + (INT_TO_LREAL(mu_p) * INT_TO_LREAL(i));
        nDenominator := nDenominator + INT_TO_LREAL(mu_p);
    END_IF;
END_FOR;

IF nDenominator > 0.0 THEN
    nCOA := LREAL_TO_INT(nNumerator / nDenominator);
    Global_Fuzzy.rOutputPressure := INT_TO_REAL(nCOA) / 1000.0;
END_IF;

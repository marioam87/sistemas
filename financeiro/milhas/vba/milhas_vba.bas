Attribute VB_Name = "mod_milhas"
Option Explicit

' ============================================================
' MILHAS v3 - mod_milhas
' INSTALACAO:
'   1. Salvar milhas_novo.xlsx como .xlsm
'   2. VBEditor > File > Import File > milhas_vba.bas
'   3. Executar:  Setup   (constroi anual + botoes + auto-update)
'   4. Salvar .xlsm
' ============================================================

Private Const WS_DADOS   As String = "dados"
Private Const WS_ANUAL   As String = "anual"
Private Const WS_ESTOQUE As String = "estoque"
Private Const TABELA_NM  As String = "Tabela1"
Private Const ANO_CEL    As String = "B1"

' Layout da aba anual (espelhado em SetupAnual)
Private Const FLUX_COL As Long = 1   ' A: Fluxo Mensal de Caixa
Private Const PRST_COL As Long = 6   ' F: Prestacoes (VBA preenche)
Private Const HIST_COL As Long = 11  ' K: Historico Anual
Private Const HDR_ROW  As Long = 7   ' linha de sub-headers
Private Const DATA_ROW As Long = 8   ' primeira linha de dados

' ============================================================
' CORES (Long = RGB)
' ============================================================
Private Function AzEsc()  As Long: AzEsc  = RGB(27,  58, 107): End Function
Private Function AzMed()  As Long: AzMed  = RGB(44,  62,  80): End Function
Private Function AzMed2() As Long: AzMed2 = RGB(26,  82, 118): End Function
Private Function Verde()  As Long: Verde  = RGB(26, 122,  74): End Function
Private Function VdEsc()  As Long: VdEsc  = RGB(44,  95,  46): End Function
Private Function Verm()   As Long: Verm   = RGB(192, 57,  43): End Function
Private Function AzCl()   As Long: AzCl   = RGB(235,245, 251): End Function
Private Function CiCl()   As Long: CiCl   = RGB(242,244, 248): End Function
Private Function VdCl()   As Long: VdCl   = RGB(240,255, 244): End Function
Private Function VmCl()   As Long: VmCl   = RGB(253,236, 234): End Function
Private Function Amar()   As Long: Amar   = RGB(255,253, 231): End Function

' ============================================================
' UTILITARIOS
' ============================================================
Private Function UltLin(ws As Worksheet, Optional col As Long = 1) As Long
    UltLin = ws.Cells(ws.Rows.Count, col).End(xlUp).Row
End Function

Private Sub Borda(rng As Range)
    With rng.Borders
        .LineStyle = xlContinuous
        .Weight    = xlThin
        .Color     = RGB(189, 195, 199)
    End With
End Sub

Private Sub EstH(rng As Range, bg As Long, Optional fg As Long = -1, _
                 Optional sz As Integer = 11)
    If fg = -1 Then fg = RGB(255, 255, 255)
    With rng
        .Interior.Color         = bg
        .Font.Color             = fg
        .Font.Bold              = True
        .Font.Name              = "Arial"
        .Font.Size              = sz
        .HorizontalAlignment    = xlCenter
        .VerticalAlignment      = xlCenter
        .WrapText               = True
    End With
    Call Borda(rng)
End Sub

Private Sub EstV(rng As Range, Optional fmt As String = "#,##0", _
                 Optional fg As Long = 0, Optional bg As Long = -1, _
                 Optional bold As Boolean = False)
    With rng
        .NumberFormat        = fmt
        .Font.Name           = "Arial"
        .Font.Size           = 11
        .Font.Color          = fg
        .Font.Bold           = bold
        .HorizontalAlignment = xlRight
        .VerticalAlignment   = xlCenter
    End With
    If bg >= 0 Then rng.Interior.Color = bg
    Call Borda(rng)
End Sub

' ============================================================
' 0. SETUP MASTER — executar UMA VEZ apos importar o .bas
' ============================================================
Public Sub Setup()
    Application.ScreenUpdating = False
    Call SetupAnual
    Call SetupButtons
    Call SetupWorksheetEvent
    Application.ScreenUpdating = True
    MsgBox "Configuracao concluida! Salve o arquivo como .xlsm.", vbInformation, "Milhas"
End Sub

' ============================================================
' 1. DEFINIR NAMED RANGES (redefine se ja existirem)
' ============================================================
Private Sub DefinirNamedRanges()
    With ThisWorkbook.Names
        On Error Resume Next
        .Item("DadosPAG").Delete
        .Item("DadosTIPO").Delete
        .Item("DadosVAL").Delete
        On Error GoTo 0
        .Add "DadosPAG",  "=dados!$B$2:INDEX(dados!$B:$B,COUNTA(dados!$B:$B))"
        .Add "DadosTIPO", "=dados!$E$2:INDEX(dados!$E:$E,COUNTA(dados!$E:$E))"
        .Add "DadosVAL",  "=dados!$C$2:INDEX(dados!$C:$C,COUNTA(dados!$C:$C))"
    End With
End Sub

' ============================================================
' 2. SETUP ANUAL — constroi toda a aba anual do zero
' ============================================================
Public Sub SetupAnual()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets(WS_ANUAL)

    Application.ScreenUpdating = False
    ws.Cells.Clear
    ws.Cells.UnMerge

    ' Formatacao base: Arial 12 centralizado em toda a aba
    ws.Cells.Font.Name            = "Arial"
    ws.Cells.Font.Size            = 12
    ws.Cells.HorizontalAlignment  = xlCenter
    ws.Cells.VerticalAlignment    = xlCenter

    ' Altura padrao para todas as linhas (1-100)
    Dim r As Long
    For r = 1 To 100
        ws.Rows(r).RowHeight = 16
    Next r

    Dim i As Long
    Dim anoAtual As Integer
    anoAtual = Year(Now)

    ' ── Linha 1: controles de ano ─────────────────────────────────
    '  A1 = "ANO:"  |  B1 = ano  |  D1 = <ANT  |  E1 = SEG>
    '  G1:H1 = Atualizar Dados  |  J1:K1 = Atualizar Prestacoes
    ws.Cells(1, 1).Value = "ANO:"
    Call EstH(ws.Cells(1, 1), AzEsc(), , 10)

    With ws.Cells(1, 2)
        .Value           = anoAtual
        .NumberFormat    = "0"
        .Font.Name       = "Arial"
        .Font.Size       = 12
        .Font.Bold       = True
        .Font.Color      = AzEsc()
        .Interior.Color  = Amar()
        .HorizontalAlignment = xlCenter
        .VerticalAlignment   = xlCenter
        Call Borda(ws.Cells(1, 2))
    End With

    ' Placeholders dos botoes (VBA sobrepoe shapes clicaveis)
    ' D1: < ANO ANT.
    ws.Cells(1, 4).Value = "< ANO ANT."
    Call EstH(ws.Cells(1, 4), AzEsc(), , 10)
    ' E1: ANO SEG. >
    ws.Cells(1, 5).Value = "ANO SEG. >"
    Call EstH(ws.Cells(1, 5), AzEsc(), , 10)
    ' G1:H1: Atualizar Dados
    ws.Range(ws.Cells(1, 7), ws.Cells(1, 8)).Merge
    ws.Cells(1, 7).Value = "Atualizar Dados"
    Dim rAD As Range: Set rAD = ws.Range(ws.Cells(1, 7), ws.Cells(1, 8))
    Dim cAD As Long:  cAD = Verde()
    Call EstH(rAD, cAD, , 10)
    ' J1:K1: Atualizar Prestacoes
    ws.Range(ws.Cells(1, 10), ws.Cells(1, 11)).Merge
    ws.Cells(1, 10).Value = "Atualizar Prestacoes"
    Dim rAP As Range: Set rAP = ws.Range(ws.Cells(1, 10), ws.Cells(1, 11))
    Dim cAP As Long:  cAP = AzMed2()
    Call EstH(rAP, cAP, , 10)

    ' ── Linhas 2-3: 5 KPI cards (A-O, 3 colunas cada) ────────────
    '  A-C: TOTAL ENTRADAS   D-F: TOTAL SAIDAS   G-I: RESULTADO
    '  J-L: ESTOQUE          M-O: SALDO APOS VENDA
    Dim kpiCols(4)   As Long:   kpiCols(0)=1:  kpiCols(1)=4:  kpiCols(2)=7:  kpiCols(3)=10: kpiCols(4)=13
    Dim kpiBgs(4)    As Long
    kpiBgs(0)=AzEsc(): kpiBgs(1)=Verm(): kpiBgs(2)=AzMed(): kpiBgs(3)=AzMed2(): kpiBgs(4)=VdEsc()
    Dim kpiTits(4)   As String
    kpiTits(0)="TOTAL ENTRADAS": kpiTits(1)="TOTAL SAIDAS": kpiTits(2)="RESULTADO DO PERIODO"
    kpiTits(3)="VALOR DO ESTOQUE": kpiTits(4)="SALDO APOS VENDA DO ESTOQUE"
    Dim kpiFmls(4)  As String
    kpiFmls(0) = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""ENTRADA"",Tabela1[PAGAMENTO],"">=""&DATE($B$1,1,1),Tabela1[PAGAMENTO],""<=""&DATE($B$1,12,31))"
    kpiFmls(1) = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""SAIDA"",Tabela1[PAGAMENTO],"">=""&DATE($B$1,1,1),Tabela1[PAGAMENTO],""<=""&DATE($B$1,12,31))"
    kpiFmls(2) = "=A4-D4"
    kpiFmls(3) = "=estoque!M13"
    kpiFmls(4) = "=estoque!M13-SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""SAIDA"",Tabela1[PAGAMENTO],"">""&EOMONTH(TODAY(),0))"
    Dim kpiFgs(4) As Long
    kpiFgs(0)=Verde(): kpiFgs(1)=Verm(): kpiFgs(2)=AzMed(): kpiFgs(3)=AzMed2(): kpiFgs(4)=Verde()
    Dim kpiBgV(4) As Long
    kpiBgV(0)=AzCl(): kpiBgV(1)=VmCl(): kpiBgV(2)=CiCl(): kpiBgV(3)=AzCl(): kpiBgV(4)=VdCl()

    Dim kFmt As String: kFmt = "R$ #,##0;[Red]R$ -#,##0"
    For i = 0 To 4
        Dim c1 As Long: c1 = kpiCols(i)
        ' Header row 2
        ws.Range(ws.Cells(3, c1), ws.Cells(3, c1+2)).Merge
        Call EstH(ws.Range(ws.Cells(3, c1), ws.Cells(3, c1+2)), kpiBgs(i), , 9)
        ws.Cells(3, c1).Value = kpiTits(i)
        ' Value row 4
        ws.Range(ws.Cells(4, c1), ws.Cells(4, c1+2)).Merge
        Dim kv As Range: Set kv = ws.Cells(4, c1)
        kv.Formula          = kpiFmls(i)
        kv.NumberFormat     = kFmt
        kv.Font.Name        = "Arial"
        kv.Font.Size        = 12
        kv.Font.Bold        = True
        kv.Font.Color       = kpiFgs(i)
        kv.Interior.Color   = kpiBgV(i)
        kv.HorizontalAlignment = xlCenter
        kv.VerticalAlignment   = xlCenter
        Call Borda(ws.Range(ws.Cells(4, c1), ws.Cells(4, c1+2)))
    Next i
    ws.Rows(2).RowHeight = 16   ' linha em branco
    ws.Rows(3).RowHeight = 16
    ws.Rows(4).RowHeight = 16

    ' ── Linha 5: spacer ───────────────────────────────────────────
    ws.Rows(5).RowHeight = 16

    ' ── Linha 5: titulos das tres tabelas ─────────────────────────
    ws.Range(ws.Cells(6, FLUX_COL), ws.Cells(6, FLUX_COL+3)).Merge
    Call EstH(ws.Range(ws.Cells(6, FLUX_COL), ws.Cells(6, FLUX_COL+3)), AzMed(), , 10)
    ws.Cells(6, FLUX_COL).Value = "FLUXO MENSAL DE CAIXA"

    ws.Range(ws.Cells(6, PRST_COL), ws.Cells(6, PRST_COL+3)).Merge
    Call EstH(ws.Range(ws.Cells(6, PRST_COL), ws.Cells(6, PRST_COL+3)), AzEsc(), , 10)
    ws.Cells(6, PRST_COL).Value = "PRESTACOES"

    ws.Range(ws.Cells(6, HIST_COL), ws.Cells(6, HIST_COL+3)).Merge
    Call EstH(ws.Range(ws.Cells(6, HIST_COL), ws.Cells(6, HIST_COL+3)), AzMed(), , 10)
    ws.Cells(6, HIST_COL).Value = "HISTORICO ANUAL"
    ws.Rows(6).RowHeight = 16

    ' ── Linha 7: sub-headers ──────────────────────────────────────
    Dim hdrGrps(2, 3) As Variant
    ' Fluxo
    hdrGrps(0, 0) = FLUX_COL: hdrGrps(0, 1) = "MES":       hdrGrps(0, 2) = AzMed():  hdrGrps(0, 3) = "MES"
    ' (re-usando array por grupo)
    Dim grpCols(2) As Long:   grpCols(0) = FLUX_COL: grpCols(1) = PRST_COL: grpCols(2) = HIST_COL
    Dim grpLbl0(2) As String: grpLbl0(0) = "MES": grpLbl0(1) = "MES": grpLbl0(2) = "ANO"

    Dim g As Integer
    For g = 0 To 2
        Dim gc As Long: gc = grpCols(g)
        Call EstH(ws.Cells(HDR_ROW, gc),   AzMed(),  , 9): ws.Cells(HDR_ROW, gc).Value   = grpLbl0(g)
        Call EstH(ws.Cells(HDR_ROW, gc+1), VdEsc(),  , 9): ws.Cells(HDR_ROW, gc+1).Value = "ENTRADAS"
        Call EstH(ws.Cells(HDR_ROW, gc+2), Verm(),   , 9): ws.Cells(HDR_ROW, gc+2).Value = "SAIDAS"
        Call EstH(ws.Cells(HDR_ROW, gc+3), AzMed(),  , 9): ws.Cells(HDR_ROW, gc+3).Value = "RESULTADO"
    Next g
    ws.Rows(HDR_ROW).RowHeight = 16

    ' ── Linhas 7-18: Fluxo Mensal de Caixa (12 meses) ────────────
    Dim mAbrev(12) As String
    mAbrev(1)="Jan": mAbrev(2)="Fev": mAbrev(3)="Mar": mAbrev(4)="Abr"
    mAbrev(5)="Mai": mAbrev(6)="Jun": mAbrev(7)="Jul": mAbrev(8)="Ago"
    mAbrev(9)="Set": mAbrev(10)="Out": mAbrev(11)="Nov": mAbrev(12)="Dez"

    Dim mi As Long, rr As Long
    For mi = 1 To 12
        rr  = DATA_ROW + mi - 1

        ' MES
        With ws.Cells(rr, FLUX_COL)
            .Value               = mAbrev(mi)
            .Font.Name           = "Arial"
            .Font.Size           = 11
            .Font.Bold           = True
            .Font.Color          = AzEsc()
            .HorizontalAlignment = xlCenter
            .VerticalAlignment   = xlCenter
            If mi Mod 2 = 1 Then .Interior.Color = AzCl() Else .Interior.Color = RGB(255,255,255)
            Call Borda(ws.Cells(rr, FLUX_COL))
        End With
        ' ENTRADAS
        ws.Cells(rr, FLUX_COL+1).Formula = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""ENTRADA"",Tabela1[PAGAMENTO],"">=""&DATE($B$1," & mi & ",1),Tabela1[PAGAMENTO],""<=""&EOMONTH(DATE($B$1," & mi & ",1),0))"
        Call EstV(ws.Cells(rr, FLUX_COL+1), "#,##0", 0, IIf(mi Mod 2 = 1, VdCl(), RGB(255,255,255)))
        ' SAIDAS
        ws.Cells(rr, FLUX_COL+2).Formula = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""SAIDA"",Tabela1[PAGAMENTO],"">=""&DATE($B$1," & mi & ",1),Tabela1[PAGAMENTO],""<=""&EOMONTH(DATE($B$1," & mi & ",1),0))"
        Call EstV(ws.Cells(rr, FLUX_COL+2), "#,##0", 0, IIf(mi Mod 2 = 1, VmCl(), RGB(255,255,255)))
        ' RESULTADO
        ws.Cells(rr, FLUX_COL+3).Formula = "=B" & rr & "-C" & rr
        Call EstV(ws.Cells(rr, FLUX_COL+3), "#,##0", 0, IIf(mi Mod 2 = 1, CiCl(), RGB(255,255,255)))
        ws.Rows(rr).RowHeight = 16
    Next mi

    ' ── Linha 19: Total Fluxo ──────────────────────────────────────
    Dim totRow As Long: totRow = DATA_ROW + 12
    ws.Cells(totRow, FLUX_COL).Value = "TOTAL"
    Call EstH(ws.Cells(totRow, FLUX_COL), AzEsc(), , 10)

    ws.Cells(totRow, FLUX_COL+1).Formula = "=SUM(B" & DATA_ROW & ":B" & (totRow-1) & ")"
    Call EstV(ws.Cells(totRow, FLUX_COL+1), "#,##0", 0, AzCl(), True)
    ws.Cells(totRow, FLUX_COL+2).Formula = "=SUM(C" & DATA_ROW & ":C" & (totRow-1) & ")"
    Call EstV(ws.Cells(totRow, FLUX_COL+2), "#,##0", 0, VmCl(), True)
    ws.Cells(totRow, FLUX_COL+3).Formula = "=B" & totRow & "-C" & totRow
    Call EstV(ws.Cells(totRow, FLUX_COL+3), "#,##0", 0, CiCl(), True)
    ws.Rows(totRow).RowHeight = 16

    ' ── Historico Anual (cols K-N, mesmas linhas do Fluxo) ─────────
    Dim wsD As Worksheet: Set wsD = ThisWorkbook.Sheets(WS_DADOS)
    Dim lastD As Long:    lastD = UltLin(wsD, 2)
    Dim yrArr(100) As Long, yrCnt As Long: yrCnt = 0
    Dim k As Long, yr As Long, found As Boolean

    For k = 2 To lastD
        If IsDate(wsD.Cells(k, 2).Value) Then
            yr = Year(CDate(wsD.Cells(k, 2).Value))
            found = False
            Dim j As Long
            For j = 0 To yrCnt - 1
                If yrArr(j) = yr Then found = True: Exit For
            Next j
            If Not found And yrCnt < 100 Then
                yrArr(yrCnt) = yr: yrCnt = yrCnt + 1
            End If
        End If
    Next k

    ' Bubble sort anos
    Dim tmp As Long
    For i = 0 To yrCnt - 2
        For j = i + 1 To yrCnt - 1
            If yrArr(j) < yrArr(i) Then
                tmp = yrArr(i): yrArr(i) = yrArr(j): yrArr(j) = tmp
            End If
        Next j
    Next i

    For i = 0 To yrCnt - 1
        rr = DATA_ROW + i
        yr = yrArr(i)

        With ws.Cells(rr, HIST_COL)
            .Value               = yr
            .NumberFormat        = "0"
            .Font.Name           = "Arial"
            .Font.Size           = 11
            .Font.Bold           = True
            .Font.Color          = AzEsc()
            .HorizontalAlignment = xlCenter
            .VerticalAlignment   = xlCenter
            If i Mod 2 = 0 Then .Interior.Color = RGB(248,249,250) Else .Interior.Color = RGB(255,255,255)
            Call Borda(ws.Cells(rr, HIST_COL))
        End With

        ws.Cells(rr, HIST_COL+1).Formula = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""ENTRADA"",Tabela1[PAGAMENTO],"">=""&DATE(K" & rr & ",1,1),Tabela1[PAGAMENTO],""<=""&DATE(K" & rr & ",12,31))"
        Call EstV(ws.Cells(rr, HIST_COL+1), "#,##0", 0, IIf(i Mod 2 = 0, VdCl(), RGB(255,255,255)))

        ws.Cells(rr, HIST_COL+2).Formula = "=SUMIFS(Tabela1[VALOR BRUTO],Tabela1[TIPO],""SAIDA"",Tabela1[PAGAMENTO],"">=""&DATE(K" & rr & ",1,1),Tabela1[PAGAMENTO],""<=""&DATE(K" & rr & ",12,31))"
        Call EstV(ws.Cells(rr, HIST_COL+2), "#,##0", 0, IIf(i Mod 2 = 0, VmCl(), RGB(255,255,255)))

        ws.Cells(rr, HIST_COL+3).Formula = "=L" & rr & "-M" & rr
        Call EstV(ws.Cells(rr, HIST_COL+3), "#,##0", 0, IIf(i Mod 2 = 0, CiCl(), RGB(255,255,255)))
        ws.Rows(rr).RowHeight = 16
    Next i

    ' Total Historico
    Dim hTot As Long: hTot = DATA_ROW + yrCnt
    ws.Cells(hTot, HIST_COL).Value = "TOTAL"
    Call EstH(ws.Cells(hTot, HIST_COL), AzEsc(), , 10)
    ws.Cells(hTot, HIST_COL+1).Formula = "=SUM(L" & DATA_ROW & ":L" & (hTot-1) & ")"
    Call EstV(ws.Cells(hTot, HIST_COL+1), "#,##0", 0, AzCl(), True)
    ws.Cells(hTot, HIST_COL+2).Formula = "=SUM(M" & DATA_ROW & ":M" & (hTot-1) & ")"
    Call EstV(ws.Cells(hTot, HIST_COL+2), "#,##0", 0, VmCl(), True)
    ws.Cells(hTot, HIST_COL+3).Formula = "=L" & hTot & "-M" & hTot
    Call EstV(ws.Cells(hTot, HIST_COL+3), "#,##0", 0, CiCl(), True)
    ws.Rows(hTot).RowHeight = 16

    ' ── Larguras de coluna ─────────────────────────────────────────
    ws.Columns.ColumnWidth = 12   ' todas as colunas ~89px

    ws.Range("A2").Select
    On Error Resume Next
    ActiveWindow.FreezePanes = False
    ws.Range("A2").Select
    ActiveWindow.FreezePanes = True
    On Error GoTo 0

    ' Preencher Prestacoes
    Call AtualizarPrestacoes

    Application.ScreenUpdating = True
End Sub

' ============================================================
' 3. ATUALIZAR DADOS
' ============================================================
Public Sub AtualizarDados()
    Application.StatusBar      = "Atualizando..."
    Application.ScreenUpdating = False
    Application.CalculateFullRebuild
    Call AtualizarPrestacoes
    Application.ScreenUpdating = True
    Application.StatusBar      = False
    MsgBox "Dados atualizados!", vbInformation, "Milhas"
End Sub

' ============================================================
' 4. NAVEGACAO DE ANO
' ============================================================
Public Sub AnoAnterior()
    With ThisWorkbook.Sheets(WS_ANUAL)
        .Range(ANO_CEL).Value = .Range(ANO_CEL).Value - 1
    End With
    Application.CalculateFullRebuild
    Call AtualizarPrestacoes
End Sub

Public Sub AnoProximo()
    With ThisWorkbook.Sheets(WS_ANUAL)
        .Range(ANO_CEL).Value = .Range(ANO_CEL).Value + 1
    End With
    Application.CalculateFullRebuild
    Call AtualizarPrestacoes
End Sub

' ============================================================
' 5. ATUALIZAR PRESTACOES
'    Preenche PRST_COL (F) a partir de DATA_ROW (7)
'    com meses >= mes atual, agrupados por ano/mes
'    Usa arrays paralelos (compativel Mac + Windows)
' ============================================================
Public Sub AtualizarPrestacoes()
    Dim wsA As Worksheet: Set wsA = ThisWorkbook.Sheets(WS_ANUAL)
    Dim wsD As Worksheet: Set wsD = ThisWorkbook.Sheets(WS_DADOS)

    Dim currM As Integer: currM = Month(Now)
    Dim currY As Integer: currY = Year(Now)
    Dim thisKey As String: thisKey = Format(Now, "YYYY/MM")

    ' Limpar area de prestacoes
    Dim lastR As Long
    lastR = wsA.Cells(wsA.Rows.Count, PRST_COL).End(xlUp).Row
    If lastR >= DATA_ROW Then
        wsA.Range(wsA.Cells(DATA_ROW, PRST_COL), _
                  wsA.Cells(lastR + 1, PRST_COL + 3)).Clear
    End If

    Dim lastD As Long: lastD = UltLin(wsD, 2)
    If lastD < 2 Then Exit Sub

    Application.StatusBar = "Lendo prestacoes..."
    Dim arrPag  As Variant: arrPag  = wsD.Range(wsD.Cells(2,2), wsD.Cells(lastD,2)).Value
    Dim arrTipo As Variant: arrTipo = wsD.Range(wsD.Cells(2,5), wsD.Cells(lastD,5)).Value
    Dim arrVal  As Variant: arrVal  = wsD.Range(wsD.Cells(2,3), wsD.Cells(lastD,3)).Value

    Const MAX_MK As Long = 300
    Dim mkKeys(MAX_MK) As String
    Dim mkEnt(MAX_MK)  As Double
    Dim mkSai(MAX_MK)  As Double
    Dim mkCnt As Long: mkCnt = 0

    Dim ii As Long, mk As String, dt As Date, tp As String, vl As Double
    Dim fi As Long, fnd As Boolean

    For ii = 1 To UBound(arrPag, 1)
        If Not IsEmpty(arrPag(ii, 1)) And IsDate(arrPag(ii, 1)) Then
            dt = CDate(arrPag(ii, 1))
            If (Year(dt) * 12 + Month(dt)) >= (currY * 12 + currM) Then
                mk = Format(dt, "YYYY/MM")
                tp = Trim(UCase(CStr(arrTipo(ii, 1))))
                vl = 0: If IsNumeric(arrVal(ii, 1)) Then vl = Abs(CDbl(arrVal(ii, 1)))

                fnd = False
                For fi = 0 To mkCnt - 1
                    If mkKeys(fi) = mk Then fnd = True: Exit For
                Next fi
                If Not fnd Then
                    If mkCnt > MAX_MK Then GoTo SkipRec
                    mkKeys(mkCnt) = mk: fi = mkCnt: mkCnt = mkCnt + 1
                End If

                If tp = "ENTRADA" Then mkEnt(fi) = mkEnt(fi) + vl
                If tp = "SAIDA"   Then mkSai(fi) = mkSai(fi) + vl
            End If
        End If
SkipRec:
    Next ii

    If mkCnt = 0 Then Application.StatusBar = False: Exit Sub

    ' Ordenar por data (bubble sort sobre "YYYY/MM")
    Dim tK As String, tE As Double, tS As Double
    For ii = 0 To mkCnt - 2
        For fi = ii + 1 To mkCnt - 1
            If mkKeys(fi) < mkKeys(ii) Then
                tK = mkKeys(ii): mkKeys(ii) = mkKeys(fi): mkKeys(fi) = tK
                tE = mkEnt(ii):  mkEnt(ii)  = mkEnt(fi):  mkEnt(fi)  = tE
                tS = mkSai(ii):  mkSai(ii)  = mkSai(fi):  mkSai(fi)  = tS
            End If
        Next fi
    Next ii

    ' Escrever na planilha
    Application.ScreenUpdating = False
    Dim rr As Long:       rr = DATA_ROW
    Dim totSai As Double: totSai = 0
    Dim fmtN   As String: fmtN = "#,##0;[Red]-#,##0"
    Dim kY As Integer, kM As Integer
    Dim rowRng As Range

    For ii = 0 To mkCnt - 1
        mk = mkKeys(ii)
        kY = CInt(Left(mk, 4)): kM = CInt(Right(mk, 2))

        Set rowRng = wsA.Range(wsA.Cells(rr, PRST_COL), wsA.Cells(rr, PRST_COL+3))

        wsA.Cells(rr, PRST_COL).Value        = DateSerial(kY, kM, 1)
        wsA.Cells(rr, PRST_COL).NumberFormat = "MMM/YY"
        wsA.Cells(rr, PRST_COL).HorizontalAlignment = xlCenter

        wsA.Cells(rr, PRST_COL+1).Value = mkEnt(ii)
        wsA.Cells(rr, PRST_COL+2).Value = mkSai(ii)
        wsA.Cells(rr, PRST_COL+3).Value = mkEnt(ii) - mkSai(ii)
        wsA.Cells(rr, PRST_COL+1).NumberFormat = fmtN
        wsA.Cells(rr, PRST_COL+2).NumberFormat = fmtN
        wsA.Cells(rr, PRST_COL+3).NumberFormat = fmtN

        rowRng.Font.Name = "Arial": rowRng.Font.Size = 11: rowRng.Font.Bold = False
        If mk = thisKey Then
            rowRng.Interior.Color = Amar()
            rowRng.Font.Bold = True
        Else
            Dim bgM As Long, bgE As Long, bgS As Long, bgR As Long
            If ii Mod 2 = 0 Then
                bgM = AzCl(): bgE = VdCl(): bgS = VmCl(): bgR = CiCl()
            Else
                bgM = RGB(255,255,255): bgE = RGB(255,255,255)
                bgS = RGB(255,255,255): bgR = RGB(255,255,255)
            End If
            wsA.Cells(rr, PRST_COL).Interior.Color   = bgM
            wsA.Cells(rr, PRST_COL+1).Interior.Color = bgE
            wsA.Cells(rr, PRST_COL+2).Interior.Color = bgS
            wsA.Cells(rr, PRST_COL+3).Interior.Color = bgR
        End If
        Call Borda(rowRng)

        If mk <> thisKey Then totSai = totSai + mkSai(ii)
        rr = rr + 1
    Next ii

    ' Linha TOTAL (soma Saidas excluindo mes atual)
    Set rowRng = wsA.Range(wsA.Cells(rr, PRST_COL), wsA.Cells(rr, PRST_COL+3))
    wsA.Cells(rr, PRST_COL).Value   = "TOTAL"
    wsA.Cells(rr, PRST_COL+1).Value = ""
    wsA.Cells(rr, PRST_COL+2).Value = totSai
    wsA.Cells(rr, PRST_COL+3).Value = -totSai
    wsA.Cells(rr, PRST_COL+2).NumberFormat = fmtN
    wsA.Cells(rr, PRST_COL+3).NumberFormat = fmtN
    rowRng.Interior.Color  = AzEsc()
    rowRng.Font.Color      = RGB(255, 255, 255)
    rowRng.Font.Bold       = True
    rowRng.Font.Name       = "Arial"
    rowRng.Font.Size       = 11
    Call Borda(rowRng)

    Application.ScreenUpdating = True
    Application.StatusBar = False
End Sub

' ============================================================
' 6. UTILITARIOS DA ABA DADOS
' ============================================================
Public Sub LimparFiltros()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets(WS_DADOS)
    If ws.AutoFilterMode Then ws.AutoFilterMode = False
    On Error Resume Next
    ws.ListObjects(TABELA_NM).Range.AutoFilter
    On Error GoTo 0
    MsgBox "Filtros removidos.", vbInformation, "Milhas"
End Sub

Public Sub ValidarDados()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets(WS_DADOS)
    Dim lastR As Long: lastR = UltLin(ws)
    Dim erros As String: erros = "": Dim cnt As Long: cnt = 0
    Dim ii As Long, tp As String

    For ii = 2 To lastR
        If IsEmpty(ws.Cells(ii, 1)) And IsEmpty(ws.Cells(ii, 3)) Then GoTo SkipV
        If Not IsDate(ws.Cells(ii, 1).Value) Then
            erros = erros & "Linha " & ii & ": DIA invalido" & vbCrLf: cnt = cnt + 1
        End If
        If Not IsNumeric(ws.Cells(ii, 3).Value) Or CDbl(ws.Cells(ii, 3).Value) <= 0 Then
            erros = erros & "Linha " & ii & ": VALOR BRUTO invalido" & vbCrLf: cnt = cnt + 1
        End If
        tp = UCase(Trim(CStr(ws.Cells(ii, 5).Value)))
        If tp <> "ENTRADA" And tp <> "SAIDA" Then
            erros = erros & "Linha " & ii & ": TIPO invalido (" & tp & ")" & vbCrLf: cnt = cnt + 1
        End If
        If cnt > 50 Then erros = erros & "... (limitado a 50 erros)": Exit For
SkipV:
    Next ii

    If cnt = 0 Then
        MsgBox "Nenhum erro encontrado! (" & (lastR-1) & " linhas verificadas.)", vbInformation, "Milhas"
    Else
        MsgBox cnt & " erro(s):" & vbCrLf & vbCrLf & erros, vbExclamation, "Milhas - Erros"
    End If
End Sub

Public Sub OrdenarDados()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets(WS_DADOS)
    Dim lastR As Long: lastR = UltLin(ws)
    With ws.Sort
        .SortFields.Clear
        .SortFields.Add Key:=ws.Columns(1), Order:=xlAscending
        .SortFields.Add Key:=ws.Columns(2), Order:=xlAscending
        .SetRange ws.Range("A2:N" & lastR)
        .Header = xlNo
        .Apply
    End With
    MsgBox "Dados ordenados por DIA e PAGAMENTO.", vbInformation, "Milhas"
End Sub

' ============================================================
' 7. SETUP BUTTONS
' ============================================================
Public Sub SetupButtons()
    Call SetupButtonsDados
    Call SetupButtonsAnual
End Sub

Private Sub SetupButtonsDados()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets(WS_DADOS)
    Dim shp As Shape
    For Each shp In ws.Shapes
        If shp.Type = msoAutoShape Or shp.Type = 1 Then shp.Delete
    Next shp

    Dim s As Long: s = UltLin(ws) + 3
    Call CriarBtn(ws, ws.Cells(s,     16), "Limpar Filtros",   "LimparFiltros",  "1B3A6B", 2)
    Call CriarBtn(ws, ws.Cells(s + 3, 16), "Validar Dados",    "ValidarDados",   "1A7A4A", 2)
    Call CriarBtn(ws, ws.Cells(s + 6, 16), "Ordenar por Data", "OrdenarDados",   "2C3E50", 2)
End Sub

Private Sub SetupButtonsAnual()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets(WS_ANUAL)
    Dim shp As Shape
    For Each shp In ws.Shapes
        shp.Delete
    Next shp

    Call CriarBtn(ws, ws.Cells(1, 4),  "< ANO ANT.",           "AnoAnterior",         "1B3A6B", 1)
    Call CriarBtn(ws, ws.Cells(1, 5),  "ANO SEG. >",           "AnoProximo",          "1B3A6B", 1)
    Call CriarBtn(ws, ws.Cells(1, 7),  "Atualizar Dados",      "AtualizarDados",      "1A7A4A", 2)
    Call CriarBtn(ws, ws.Cells(1, 10), "Atualizar Prestacoes", "AtualizarPrestacoes", "1A5276", 2)
End Sub

Private Sub CriarBtn(ws As Worksheet, cel As Range, lbl As String, _
                     macro As String, corHex As String, Optional span As Integer = 1)
    Dim totalW As Double: totalW = 0
    Dim ci As Integer
    For ci = 0 To span - 1
        totalW = totalW + ws.Cells(cel.Row, cel.Column + ci).Width
    Next ci

    Dim shp As Shape
    Set shp = ws.Shapes.AddShape(5, cel.Left, cel.Top, totalW, cel.RowHeight)

    Dim r As Long: r = CLng("&H" & Left(corHex, 2))
    Dim g As Long: g = CLng("&H" & Mid(corHex, 3, 2))
    Dim b As Long: b = CLng("&H" & Right(corHex, 2))

    With shp
        .Fill.ForeColor.RGB = RGB(r, g, b)
        .Line.Visible       = msoFalse
        With .TextFrame2.TextRange
            .Text = lbl
            With .Font
                .Name  = "Arial"
                .Size  = 10
                .Bold  = msoTrue
                .Fill.ForeColor.RGB = RGB(255, 255, 255)
            End With
            .ParagraphFormat.Alignment = msoAlignCenter
        End With
        .TextFrame2.VerticalAnchor = msoAnchorMiddle
        .OnAction = "'" & ThisWorkbook.Name & "'!mod_milhas." & macro
    End With
End Sub

' ============================================================
' 8. SETUP WORKSHEET EVENT (auto-update ao abrir aba anual)
' ============================================================
Public Sub SetupWorksheetEvent()
    On Error GoTo FallBack
    Dim vbComp As Object
    Set vbComp = ThisWorkbook.VBProject.VBComponents(WS_ANUAL)
    Dim cm As Object: Set cm = vbComp.CodeModule

    Dim n As Long: n = cm.CountOfLines
    If n > 0 Then
        If InStr(cm.Lines(1, n), "Worksheet_Activate") > 0 Then
            MsgBox "Evento ja configurado.", vbInformation, "Milhas"
            Exit Sub
        End If
    End If

    cm.InsertLines 1, "Private Sub Worksheet_Activate()"
    cm.InsertLines 2, "    Call mod_milhas.AtualizarPrestacoes"
    cm.InsertLines 3, "End Sub"
    cm.InsertLines 4, ""
    MsgBox "Auto-update configurado!", vbInformation, "Milhas"
    Exit Sub

FallBack:
    MsgBox "Configuracao manual necessaria:" & vbCrLf & vbCrLf & _
           "1. VBEditor > clicar 2x em 'anual'" & vbCrLf & _
           "2. Colar o codigo:" & vbCrLf & vbCrLf & _
           "Private Sub Worksheet_Activate()" & vbCrLf & _
           "    Call mod_milhas.AtualizarPrestacoes" & vbCrLf & _
           "End Sub", vbInformation, "Milhas - Instrucoes Manuais"
End Sub

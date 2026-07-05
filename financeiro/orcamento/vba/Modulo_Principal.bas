Option Explicit

' ---- helper: find key in array, return index or -1 ----

' ---- normaliza string para comparacao: substitui chars acentuados por base ----
Private Function AsciiKey(s As String) As String
    Dim i As Long, c As Long, r As String
    r = ""
    For i = 1 To Len(s)
        c = AscW(Mid(s, i, 1))
        Select Case c
            Case 224, 225, 226, 227, 228, 229: r = r & "a"
            Case 231: r = r & "c"
            Case 232, 233, 234, 235: r = r & "e"
            Case 236, 237, 238, 239: r = r & "i"
            Case 241: r = r & "n"
            Case 242, 243, 244, 245, 246: r = r & "o"
            Case 249, 250, 251, 252: r = r & "u"
            Case 192, 193, 194, 195, 196, 197: r = r & "A"
            Case 199: r = r & "C"
            Case 200, 201, 202, 203: r = r & "E"
            Case 211, 212, 213, 214: r = r & "O"
            Case Else: r = r & Mid(s, i, 1)
        End Select
    Next i
    AsciiKey = r
End Function

Private Function FindKey(arr() As String, n As Long, k As String) As Long
    Dim x As Long
    For x = 0 To n - 1
        If arr(x) = k Then FindKey = x: Exit Function
    Next x
    FindKey = -1
End Function

' ---- busca em array base 1 (1..n); retorna indice ou -1 ----
Private Function FindKey1(arr() As String, n As Long, k As String) As Long
    Dim x As Long
    For x = 1 To n
        If arr(x) = k Then FindKey1 = x: Exit Function
    Next x
    FindKey1 = -1
End Function

' ---- lookup rapido em Collection (Mac+Windows): retorna o indice guardado
'      na chave k, ou 0 se a chave nao existe. Substitui Scripting.Dictionary,
'      que so existe no Windows. ----
Private Function ColIndex(col As Collection, k As String) As Long
    On Error Resume Next
    ColIndex = col.Item(k)      ' se a chave nao existe, gera erro e ColIndex fica 0
    On Error GoTo 0
End Function

' ---- apply formatting to a data row cell range ----
Private Sub FmtRow(ws As Worksheet, r As Long, _
    cStart As Long, cEnd As Long, bgClr As Long, _
    catClr As Long, catCol As Long, valCol As Long)
    Dim c As Long
    For c = cStart To cEnd
        With ws.Cells(r, c)
            .Interior.Color = bgClr
            .Font.Name = "Arial"
            .Font.Size = 11
            .HorizontalAlignment = xlCenter
            .VerticalAlignment = xlCenter
            With .Borders
                .LineStyle = xlContinuous
                .Weight = xlThin
                .Color = RGB(0, 0, 0)
            End With
            If c = catCol Then
                .Font.Color = catClr
                .Font.Bold = True
            ElseIf c = valCol Then
                .Font.Color = catClr
                .Font.Bold = True
                .NumberFormat = "#,##0"
            Else
                .Font.Color = RGB(100, 116, 139)
                .Font.Bold = False
            End If
        End With
    Next c
End Sub

Sub GerarDashboard()
    Dim wsDados As Worksheet, wsMensal As Worksheet, wb As Workbook
    Set wb = ThisWorkbook
    On Error Resume Next
    Set wsDados = wb.Sheets("Dados")
    Set wsMensal = wb.Sheets("Mensal")
    On Error GoTo 0
    If wsDados Is Nothing Then MsgBox "Aba Dados nao encontrada!", vbCritical: Exit Sub
    If wsMensal Is Nothing Then MsgBox "Aba Mensal nao encontrada!", vbCritical: Exit Sub

    ' garante que a coluna N (auxiliar) da Recorrente esteja alinhada com o
    ' tamanho atual da tabela antes de calcular qualquer coisa que dependa
    ' dela (tabela Prestacoes em Mensal!P:Q usa 'Recorrente'!N2:N48)
    Call SincronizarColunaN

    Dim m As String
    m = InputBox("Digite o mes no formato YYYY-MM (ex: 2025-06):", "Gerar Dashboard", Format(Now(), "YYYY-MM"))
    If m = "" Then Exit Sub

    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Dim calcPrev As XlCalculation: calcPrev = Application.Calculation
    Application.Calculation = xlCalculationManual

    ' ---- arrays for Receitas ----
    Dim recKeys() As String, recVals() As Double
    Dim nRec As Long: nRec = 0
    ReDim recKeys(0): ReDim recVals(0)

    ' ---- arrays for Despesas ----
    Dim despKeys() As String, despVals() As Double
    Dim nDesp As Long: nDesp = 0
    ReDim despKeys(0): ReDim despVals(0)

    ' ---- arrays for Cartao ----
    Dim cartKeys() As String, cartVals() As Double
    Dim cartPags() As String, cartRess() As String, cartStas() As String
    Dim nCart As Long: nCart = 0
    ReDim cartKeys(0): ReDim cartVals(0)
    ReDim cartPags(0): ReDim cartRess(0): ReDim cartStas(0)

    Dim lastRow As Long
    lastRow = wsDados.Cells(wsDados.Rows.Count, 1).End(xlUp).Row

    ' ---- leitura em bloco: carrega A2:J(last) num array (1x acesso ao Excel) ----
    Dim d As Variant
    If lastRow >= 2 Then
        d = wsDados.Range(wsDados.Cells(2, 1), wsDados.Cells(lastRow, 10)).Value
    End If

    Dim i As Long, idx As Long
    For i = 1 To lastRow - 1
        Dim anoMes As String
        anoMes = CStr(d(i, 1))
        If anoMes <> m Then GoTo NextRow

        Dim tipo As String, cat As String, sub_ As String
        Dim valor As Double, pag As String, res As String, sta As String
        tipo = CStr(d(i, 3))
        cat = CStr(d(i, 4))
        sub_ = CStr(d(i, 5))
        valor = Val(d(i, 7) & "")
        pag = CStr(d(i, 8))
        res = CStr(d(i, 9))
        sta = CStr(d(i, 10))

        Dim key As String: key = cat & "|" & sub_

        If tipo = "Receitas" And sub_ <> "Contrato" Then
            idx = FindKey(recKeys, nRec, key)
            If idx = -1 Then
                ReDim Preserve recKeys(nRec): ReDim Preserve recVals(nRec)
                recKeys(nRec) = key: recVals(nRec) = 0: idx = nRec: nRec = nRec + 1
            End If
            recVals(idx) = recVals(idx) + valor

        ElseIf tipo = "Despesas" Then
            ' despesas da Pri ficam FORA da tabela de despesas e do placar
            If res = "Pri" Then GoTo SoCartao
            ' TODA despesa entra na tabela DESPESAS (independente da forma de pagamento)
            idx = FindKey(despKeys, nDesp, key)
            If idx = -1 Then
                ReDim Preserve despKeys(nDesp): ReDim Preserve despVals(nDesp)
                despKeys(nDesp) = key: despVals(nDesp) = 0: idx = nDesp: nDesp = nDesp + 1
            End If
            despVals(idx) = despVals(idx) + Abs(valor)
SoCartao:
            ' Cartao "A pagar" TAMBEM entra na tabela CARTAO (apenas referencia de transferencia)
            If pag <> "Pagamento" And pag <> "" And sta = "A pagar" Then
                Dim keyCart As String: keyCart = cat & "|" & sub_ & "|" & res & "|" & pag
                idx = FindKey(cartKeys, nCart, keyCart)
                If idx = -1 Then
                    ReDim Preserve cartKeys(nCart): ReDim Preserve cartVals(nCart)
                    ReDim Preserve cartPags(nCart): ReDim Preserve cartRess(nCart): ReDim Preserve cartStas(nCart)
                    cartKeys(nCart) = keyCart: cartVals(nCart) = 0: idx = nCart: nCart = nCart + 1
                End If
                cartVals(idx) = cartVals(idx) + Abs(valor)
                cartPags(idx) = pag: cartRess(idx) = res: cartStas(idx) = sta
            End If
        End If
NextRow:
    Next i

    ' ---- bubble sort (alphabetical by key) ----
    Dim j As Long, tmpS As String, tmpD As Double
    For i = 0 To nRec - 2
        For j = 0 To nRec - 2 - i
            If recKeys(j) > recKeys(j + 1) Then
                tmpS = recKeys(j): recKeys(j) = recKeys(j + 1): recKeys(j + 1) = tmpS
                tmpD = recVals(j): recVals(j) = recVals(j + 1): recVals(j + 1) = tmpD
            End If
        Next j
    Next i
    For i = 0 To nDesp - 2
        For j = 0 To nDesp - 2 - i
            If despKeys(j) > despKeys(j + 1) Then
                tmpS = despKeys(j): despKeys(j) = despKeys(j + 1): despKeys(j + 1) = tmpS
                tmpD = despVals(j): despVals(j) = despVals(j + 1): despVals(j + 1) = tmpD
            End If
        Next j
    Next i
    Dim tmpS2 As String, tmpS3 As String, tmpS4 As String
    For i = 0 To nCart - 2
        For j = 0 To nCart - 2 - i
            If cartKeys(j) > cartKeys(j + 1) Then
                tmpS = cartKeys(j): cartKeys(j) = cartKeys(j + 1): cartKeys(j + 1) = tmpS
                tmpD = cartVals(j): cartVals(j) = cartVals(j + 1): cartVals(j + 1) = tmpD
                tmpS2 = cartPags(j): cartPags(j) = cartPags(j + 1): cartPags(j + 1) = tmpS2
                tmpS3 = cartRess(j): cartRess(j) = cartRess(j + 1): cartRess(j + 1) = tmpS3
                tmpS4 = cartStas(j): cartStas(j) = cartStas(j + 1): cartStas(j + 1) = tmpS4
            End If
        Next j
    Next i

    ' ---- totals ----
    Dim totalRec As Double, totalDesp As Double, totalCart As Double
    For i = 0 To nRec - 1: totalRec = totalRec + recVals(i): Next i
    For i = 0 To nDesp - 1: totalDesp = totalDesp + despVals(i): Next i


    ' ---- clear Mensal rows 8+: wipe ALL formatting then reapply via FmtRow ----
    ' Use max last row across all section columns to avoid leaving stale rows from previous runs
    Dim lastA As Long, lastE As Long, lastI As Long, lastDataRow As Long
    lastA = wsMensal.Cells(wsMensal.Rows.Count, 1).End(xlUp).Row
    lastE = wsMensal.Cells(wsMensal.Rows.Count, 5).End(xlUp).Row
    lastI = wsMensal.Cells(wsMensal.Rows.Count, 9).End(xlUp).Row
    lastDataRow = lastA
    If lastE > lastDataRow Then lastDataRow = lastE
    If lastI > lastDataRow Then lastDataRow = lastI
    If lastDataRow < 8 Then lastDataRow = 8
    Dim clearEnd As Long: clearEnd = lastDataRow + 5
    ' limpa apenas as colunas A:N (area do dashboard mensal);
    ' colunas P em diante (tabela Prestacoes e auxiliares em S) ficam intactas
    With wsMensal.Range("A8:N" & clearEnd)
        .UnMerge
        .ClearFormats
        .ClearContents
    End With
    wsMensal.Rows("8:" & clearEnd).Hidden = False

    ' ---- header & KPIs ----
    wsMensal.Cells(1, 1).Value = "Dashboard Financeiro - " & m
    wsMensal.Cells(4, 1).Value = totalRec
    wsMensal.Cells(4, 5).Value = totalDesp
    wsMensal.Cells(4, 9).Value = totalRec - totalDesp
    wsMensal.Cells(4, 1).NumberFormat = "#,##0.00"
    wsMensal.Cells(4, 5).NumberFormat = "#,##0.00"
    wsMensal.Cells(4, 9).NumberFormat = "#,##0.00"

    ' ---- borders + centering on static header rows (3-4 KPIs, 6-7 section titles) ----
    Dim hRanges(8) As String, hIdx As Integer
    hRanges(0) = "A3:C4": hRanges(1) = "E3:G4": hRanges(2) = "I3:K4"
    hRanges(3) = "A6:C6": hRanges(4) = "E6:G6": hRanges(5) = "I6:N6"
    hRanges(6) = "A7:C7": hRanges(7) = "E7:G7": hRanges(8) = "I7:N7"
    For hIdx = 0 To 8
        With wsMensal.Range(hRanges(hIdx))
            .HorizontalAlignment = xlCenter
            .VerticalAlignment = xlCenter
            With .Borders
                .LineStyle = xlContinuous
                .Weight = xlThin
                .Color = RGB(0, 0, 0)
            End With
        End With
    Next hIdx

    ' ---- colors ----
    Dim cGDark As Long, cGLight As Long
    Dim cRDark As Long, cRLight As Long
    Dim cBDark As Long, cBLight As Long
    Dim cWhite As Long
    cGDark = RGB(5, 150, 105)
    cGLight = RGB(236, 253, 245)
    cRDark = RGB(225, 29, 72)
    cRLight = RGB(255, 241, 242)
    cBDark = RGB(37, 99, 235)
    cBLight = RGB(239, 246, 255)
    cWhite = RGB(255, 255, 255)

    ' ---- write RECEITAS (cols A=1, B=2, C=3) ----
    Dim startRow As Long: startRow = 8
    Dim r As Long, parts() As String, bg As Long

    For i = 0 To nRec - 1
        r = startRow + i
        bg = IIf(i Mod 2 = 0, cWhite, cGLight)
        parts = Split(recKeys(i), "|")
        wsMensal.Cells(r, 1).Value = parts(0)
        If UBound(parts) >= 1 Then wsMensal.Cells(r, 2).Value = parts(1)
        wsMensal.Cells(r, 3).Value = recVals(i)
        wsMensal.Rows(r).RowHeight = 20
        Call FmtRow(wsMensal, r, 1, 3, bg, cGDark, 1, 3)
    Next i
    r = startRow + nRec
    wsMensal.Cells(r, 1).Value = "TOTAL RECEITAS"
    wsMensal.Cells(r, 3).Value = totalRec
    wsMensal.Rows(r).RowHeight = 20
    With wsMensal.Range(wsMensal.Cells(r, 1), wsMensal.Cells(r, 3))
        .Interior.Color = cGDark
        .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
    wsMensal.Cells(r, 3).NumberFormat = "#,##0"

    ' ---- write DESPESAS (cols E=5, F=6, G=7) ----
    For i = 0 To nDesp - 1
        r = startRow + i
        bg = IIf(i Mod 2 = 0, cWhite, cRLight)
        parts = Split(despKeys(i), "|")
        wsMensal.Cells(r, 5).Value = parts(0)
        If UBound(parts) >= 1 Then wsMensal.Cells(r, 6).Value = parts(1)
        wsMensal.Cells(r, 7).Value = despVals(i)
        wsMensal.Rows(r).RowHeight = 20
        Call FmtRow(wsMensal, r, 5, 7, bg, cRDark, 5, 7)
    Next i
    r = startRow + nDesp
    wsMensal.Cells(r, 5).Value = "TOTAL DESPESAS"
    wsMensal.Cells(r, 7).Value = totalDesp
    wsMensal.Rows(r).RowHeight = 20
    With wsMensal.Range(wsMensal.Cells(r, 5), wsMensal.Cells(r, 7))
        .Interior.Color = cRDark
        .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
    wsMensal.Cells(r, 7).NumberFormat = "#,##0"

    ' =====================================================================
    ' TABELAS DE CARTAO em cascata (cols I..N) - APENAS REFERENCIA:
    ' os valores destas tabelas NAO entram no calculo geral de despesas
    ' (ja constam na tabela DESPESAS), evitando duplicidade de dados.
    ' Ordem: CARTAO, NUBANK, C6, CARTAO - PRI, PRI
    ' (paleta azul, pulando uma linha entre as tabelas)
    ' =====================================================================
    Dim rC As Long
    rC = RenderCart(wsMensal, startRow, "CARTAO", "Total Cartao", "PAG_CARTAO", False, _
        cartKeys, cartVals, cartPags, cartRess, cartStas, nCart, cBDark, cBLight, cWhite)
    rC = RenderCart(wsMensal, rC, "NUBANK", "Total Nubank", "PAG_NUBANK", True, _
        cartKeys, cartVals, cartPags, cartRess, cartStas, nCart, cBDark, cBLight, cWhite)
    rC = RenderCart(wsMensal, rC, "C6", "Total C6", "PAG_C6", True, _
        cartKeys, cartVals, cartPags, cartRess, cartStas, nCart, cBDark, cBLight, cWhite)
    rC = RenderCart(wsMensal, rC, "CARTAO - PRI", "Total Cartao - Pri", "PRI_COMP", True, _
        cartKeys, cartVals, cartPags, cartRess, cartStas, nCart, cBDark, cBLight, cWhite)
    rC = RenderCart(wsMensal, rC, "PRI", "Total Pri", "PRI", True, _
        cartKeys, cartVals, cartPags, cartRess, cartStas, nCart, cBDark, cBLight, cWhite)

    Call AtualizarImoveis

    Application.Calculation = calcPrev
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    MsgBox "Dashboard gerado para " & m & "!" & ChrW(10) & _
           nRec & " receitas | " & nDesp & " despesas | " & nCart & " cartao", vbInformation
End Sub


' ---- decide se um item do cartao pertence a uma tabela ----
Private Function CartMatch(modo As String, pag As String, res As String) As Boolean
    Select Case modo
        Case "PAG_CARTAO": CartMatch = (pag = "Cartao" And (res = "Mario" Or res = "Compartilhado"))
        Case "PAG_NUBANK": CartMatch = (pag = "Nubank" And res = "Mario")
        Case "PAG_C6": CartMatch = (pag = "C6" And res = "Mario")
        Case "PRI_COMP": CartMatch = (pag = "C6" And res = "Pri") Or (pag = "Cartao" And res = "Compartilhado")
        Case "PRI": CartMatch = (pag = "Pri" And res = "Mario")
        Case Else: CartMatch = False
    End Select
End Function

' ---- renderiza uma tabela de cartao (cols I..N) e retorna a proxima linha livre ----
Private Function RenderCart(ws As Worksheet, rIni As Long, banner As String, totLabel As String, _
    modo As String, escreverCabecalho As Boolean, _
    cartKeys() As String, cartVals() As Double, cartPags() As String, _
    cartRess() As String, cartStas() As String, nCart As Long, _
    cBDark As Long, cBLight As Long, cWhite As Long) As Long

    Dim r As Long: r = rIni
    Dim i As Long, k As Long, tot As Double, bg As Long, parts() As String

    If escreverCabecalho Then
        ws.Range(ws.Cells(r, 9), ws.Cells(r, 14)).Merge
        ws.Cells(r, 9).Value = banner
        ws.Rows(r).RowHeight = 20
        With ws.Range(ws.Cells(r, 9), ws.Cells(r, 14))
            .Interior.Color = cBDark
            .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
            .HorizontalAlignment = xlCenter
            .VerticalAlignment = xlCenter
            With .Borders
                .LineStyle = xlContinuous
                .Weight = xlThin
                .Color = RGB(0, 0, 0)
            End With
        End With
        r = r + 1
        ws.Cells(r, 9).Value = "Categoria"
        ws.Cells(r, 10).Value = "Subcategoria"
        ws.Cells(r, 11).Value = "Valor"
        ws.Cells(r, 12).Value = "Pagamento"
        ws.Cells(r, 13).Value = "Responsavel"
        ws.Cells(r, 14).Value = "Status"
        ws.Rows(r).RowHeight = 20
        With ws.Range(ws.Cells(r, 9), ws.Cells(r, 14))
            .Interior.Color = cBDark
            .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
            .HorizontalAlignment = xlCenter
            .VerticalAlignment = xlCenter
            With .Borders
                .LineStyle = xlContinuous
                .Weight = xlThin
                .Color = RGB(0, 0, 0)
            End With
        End With
        r = r + 1
    End If

    k = 0
    For i = 0 To nCart - 1
        If CartMatch(modo, cartPags(i), cartRess(i)) Then
            bg = IIf(k Mod 2 = 0, cWhite, cBLight)
            parts = Split(cartKeys(i), "|")
            ws.Cells(r, 9).Value = parts(0)
            If UBound(parts) >= 1 Then ws.Cells(r, 10).Value = parts(1)
            ws.Cells(r, 11).Value = cartVals(i)
            ws.Cells(r, 12).Value = cartPags(i)
            ws.Cells(r, 13).Value = cartRess(i)
            ws.Cells(r, 14).Value = cartStas(i)
            ws.Rows(r).RowHeight = 20
            Call FmtRow(ws, r, 9, 14, bg, cBDark, 9, 11)
            tot = tot + cartVals(i)
            r = r + 1: k = k + 1
        End If
    Next i

    ws.Cells(r, 9).Value = totLabel
    ws.Cells(r, 11).Value = tot
    ws.Rows(r).RowHeight = 20
    With ws.Range(ws.Cells(r, 9), ws.Cells(r, 14))
        .Interior.Color = cBDark
        .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
    ws.Cells(r, 11).NumberFormat = "#,##0"

    RenderCart = r + 2
End Function

' ============================================================
' SINCRONIZAR COLUNA N - resincroniza a coluna auxiliar N da aba
' Recorrente com o tamanho atual da tabela.
'
' PROBLEMA QUE ISSO RESOLVE:
'   A coluna N (indice de mes/ano serial usado por Mensal!S2 e pela
'   tabela Prestacoes em Mensal!P:Q) fica FORA do ListObject
'   "Recorrente". Quando uma linha e excluida de dentro da tabela,
'   o Excel desloca as formulas de N para cima, mas a ULTIMA linha
'   de N fica orfa (aponta para a linha que foi excluida, virando
'   #REF!) e as demais ficam uma linha "atrasadas" (N(r) passa a
'   referenciar I(r-1)/J(r-1) em vez de I(r)/J(r)).
'
' O QUE A MACRO FAZ:
'   Reescreve a formula de N em TODA linha de dados da tabela mais
'   1 linha de buffer logo abaixo (a tabela Prestacoes soma ate esse
'   buffer), sempre auto-referenciada (N(r) usa I(r) e J(r) da mesma
'   linha). Tambem apaga sobras de linhas antigas abaixo do buffer.
'
' QUANDO RODAR:
'   Roda automaticamente no inicio de GerarDashboard. Pode tambem
'   ser rodada manualmente (botao na aba Recorrente) apos excluir ou
'   inserir linhas na tabela Recorrente, antes de conferir a Mensal.
' ============================================================
Sub SincronizarColunaN()
    Dim wsR As Worksheet, loR As ListObject
    Set wsR = ThisWorkbook.Sheets("Recorrente")
    Set loR = wsR.ListObjects("Recorrente")

    If loR.DataBodyRange Is Nothing Then Exit Sub

    Dim firstRow As Long, lastRow As Long, bufferRow As Long
    firstRow = loR.DataBodyRange.Row
    lastRow = loR.DataBodyRange.Row + loR.DataBodyRange.Rows.Count - 1
    bufferRow = lastRow + 1   ' 1 linha extra alem do fim da tabela

    ' apaga sobras de formulas antigas de N abaixo do buffer (heranca de
    ' quando a tabela era maior)
    Dim lastNRow As Long
    lastNRow = wsR.Cells(wsR.Rows.Count, 14).End(xlUp).Row   ' coluna N = 14
    If lastNRow > bufferRow Then
        wsR.Range(wsR.Cells(bufferRow + 1, 14), wsR.Cells(lastNRow, 14)).ClearContents
    End If

    ' reescreve a formula em cada linha, sempre auto-referenciada
    Dim r As Long
    For r = firstRow To bufferRow
        wsR.Cells(r, 14).FormulaR1C1 = _
            "=IF(AND(RC[-5]=""Parcela"",RC[-4]<>""""),(2000+VALUE(RIGHT(RC[-4],2)))*12+" & _
            "MATCH(LEFT(RC[-4],3),{""jan"";""fev"";""mar"";""abr"";""mai"";""jun"";""jul"";""ago"";""set"";""out"";""nov"";""dez""},0),"""")"
    Next r
End Sub

' ---- limpa os filtros da tabela da aba ativa (Dados ou Recorrente) ----
Sub LimparFiltros()
    ' limpa filtros e reexibe todas as linhas da aba ativa
    Dim ws As Worksheet: Set ws = ActiveSheet
    Dim lo As ListObject
    On Error Resume Next
    If ws.ListObjects.Count > 0 Then
        Set lo = ws.ListObjects(1)
    Else
        Set lo = ThisWorkbook.Sheets("Dados").ListObjects("ControleFinanceiro")
        Set ws = lo.Parent
    End If
    ' 1) limpar criterios do AutoFilter
    If Not lo Is Nothing Then
        If lo.AutoFilter Is Nothing Then
            ws.AutoFilterMode = False
        Else
            lo.AutoFilter.ShowAllData
        End If
    End If
    ' 2) reexibir todas as linhas (cobre linhas ocultadas manualmente)
    ws.Rows.Hidden = False
    On Error GoTo 0
End Sub

' ============================================================
' DASHBOARD ANUAL - blocos por ano empilhados em ordem decrescente
' A macro regenera APENAS o bloco do ano informado:
'  - se o bloco existe, e deletado e reconstruido no mesmo lugar
'  - se nao existe, e inserido na posicao correta (anos novos no topo)
' Blocos de outros anos permanecem intocados (historico fixo)
' ============================================================
Sub GerarDashboardAnual()
    Dim wsDados As Worksheet, wsAnual As Worksheet, wb As Workbook
    Set wb = ThisWorkbook
    On Error Resume Next
    Set wsDados = wb.Sheets("Dados")
    Set wsAnual = wb.Sheets("Anual")
    On Error GoTo 0
    If wsDados Is Nothing Then MsgBox "Aba Dados nao encontrada!", vbCritical: Exit Sub
    If wsAnual Is Nothing Then
        Set wsAnual = wb.Sheets.Add(After:=wb.Sheets("Mensal"))
        wsAnual.Name = "Anual"
    End If

    Dim ano As String
    ano = InputBox("Digite o ano (ex: 2026):", "Gerar Dashboard Anual", Format(Now(), "YYYY"))
    If ano = "" Then Exit Sub

    ' ---- agregacao: chave (cat|sub) + 12 meses ----
    Dim recKeys() As String, recVals() As Double, nRec As Long
    Dim despKeys() As String, despVals() As Double, nDesp As Long
    ReDim recKeys(0): ReDim recVals(1 To 12, 0)
    ReDim despKeys(0): ReDim despVals(1 To 12, 0)

    Dim lastRow As Long
    lastRow = wsDados.Cells(wsDados.Rows.Count, 1).End(xlUp).Row

    ' ---- leitura em bloco: A2:J(last) num array (1x acesso ao Excel) ----
    Dim d As Variant
    If lastRow >= 2 Then
        d = wsDados.Range(wsDados.Cells(2, 1), wsDados.Cells(lastRow, 10)).Value
    End If

    Dim i As Long, j As Long, idx As Long, mes As Integer
    Dim nMeses As Integer: nMeses = 0
    For i = 1 To lastRow - 1
        Dim anoMes As String
        anoMes = CStr(d(i, 1))
        If Left(anoMes, 4) <> ano Or Len(anoMes) < 7 Then GoTo NextRow
        mes = CInt(Mid(anoMes, 6, 2))
        If mes > nMeses Then nMeses = mes

        Dim tipo As String, cat As String, sub_ As String, valr As Double
        tipo = CStr(d(i, 3))
        cat = CStr(d(i, 4))
        sub_ = CStr(d(i, 5))
        valr = Val(d(i, 7) & "")
        ' despesas da Pri ficam fora do dashboard anual
        If tipo = "Despesas" And CStr(d(i, 9)) = "Pri" Then GoTo NextRow

        Dim key As String: key = cat & "|" & sub_
        If tipo = "Receitas" Then
            idx = FindKey(recKeys, nRec, key)
            If idx = -1 Then
                ReDim Preserve recKeys(nRec): ReDim Preserve recVals(1 To 12, nRec)
                recKeys(nRec) = key: idx = nRec: nRec = nRec + 1
            End If
            recVals(mes, idx) = recVals(mes, idx) + valr
        ElseIf tipo = "Despesas" Then
            idx = FindKey(despKeys, nDesp, key)
            If idx = -1 Then
                ReDim Preserve despKeys(nDesp): ReDim Preserve despVals(1 To 12, nDesp)
                despKeys(nDesp) = key: idx = nDesp: nDesp = nDesp + 1
            End If
            despVals(mes, idx) = despVals(mes, idx) + Abs(valr)
        End If
NextRow:
    Next i
    If nMeses = 0 Then
        MsgBox "Nenhum lancamento encontrado para " & ano & "!", vbExclamation
        Exit Sub
    End If

    ' ---- ordenar alfabeticamente ----
    Dim tmpS As String, tmpD As Double
    For i = 0 To nRec - 2
        For j = 0 To nRec - 2 - i
            If StrComp(recKeys(j), recKeys(j + 1), vbTextCompare) > 0 Then
                tmpS = recKeys(j): recKeys(j) = recKeys(j + 1): recKeys(j + 1) = tmpS
                For mes = 1 To 12
                    tmpD = recVals(mes, j): recVals(mes, j) = recVals(mes, j + 1): recVals(mes, j + 1) = tmpD
                Next mes
            End If
        Next j
    Next i
    For i = 0 To nDesp - 2
        For j = 0 To nDesp - 2 - i
            If StrComp(despKeys(j), despKeys(j + 1), vbTextCompare) > 0 Then
                tmpS = despKeys(j): despKeys(j) = despKeys(j + 1): despKeys(j + 1) = tmpS
                For mes = 1 To 12
                    tmpD = despVals(mes, j): despVals(mes, j) = despVals(mes, j + 1): despVals(mes, j + 1) = tmpD
                Next mes
            End If
        Next j
    Next i

    ' ---- totais por mes (Contrato fora) ----
    Dim totRec(1 To 12) As Double, totDesp(1 To 12) As Double
    Dim parts() As String
    For i = 0 To nRec - 1
        parts = Split(recKeys(i), "|")
        If parts(1) <> "Contrato" Then
            For mes = 1 To 12: totRec(mes) = totRec(mes) + recVals(mes, i): Next mes
        End If
    Next i
    For i = 0 To nDesp - 1
        For mes = 1 To 12: totDesp(mes) = totDesp(mes) + despVals(mes, i): Next mes
    Next i
    Dim somaRec As Double, somaDesp As Double
    For mes = 1 To 12
        somaRec = somaRec + totRec(mes)
        somaDesp = somaDesp + totDesp(mes)
    Next mes

    ' ---- localizar blocos existentes pelo titulo ----
    Dim lastUsed As Long: lastUsed = 0
    On Error Resume Next
    lastUsed = wsAnual.Cells.Find("*", SearchOrder:=xlByRows, SearchDirection:=xlPrevious).Row
    On Error GoTo 0

    Dim rStart As Long, rEnd As Long, firstOlder As Long
    rStart = 0: rEnd = 0: firstOlder = 0
    Dim rr As Long, t As String, anoBloco As String
    For rr = 1 To lastUsed
        t = CStr(wsAnual.Cells(rr, 1).Value)
        If Left(t, 17) = "Dashboard Anual -" Then
            anoBloco = Trim(Mid(t, 18))
            If anoBloco = ano Then
                rStart = rr
            ElseIf rStart > 0 And rEnd = 0 Then
                rEnd = rr - 1
            End If
            If firstOlder = 0 And rStart = 0 And CLng(anoBloco) < CLng(ano) Then firstOlder = rr
        End If
    Next rr
    If rStart > 0 And rEnd = 0 Then rEnd = lastUsed

    ' confirmacao ao regerar um ano que nao e o ano corrente
    If rStart > 0 And ano <> Format(Now(), "YYYY") Then
        If MsgBox("O bloco de " & ano & " ja existe. Regenerar?", vbYesNo + vbQuestion, "Dashboard Anual") <> vbYes Then Exit Sub
    End If

    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Dim calcPrev As XlCalculation: calcPrev = Application.Calculation
    Application.Calculation = xlCalculationManual

    ' ---- protecao: desbloquear aba e criar backup antes de qualquer alteracao ----
    wsAnual.Unprotect
    Application.DisplayAlerts = False
    On Error Resume Next
    wb.Sheets("Anual_bkp").Delete
    On Error GoTo 0
    Application.DisplayAlerts = True
    wsAnual.Copy After:=wsAnual
    ActiveSheet.Name = "Anual_bkp"
    ActiveSheet.Unprotect
    ActiveSheet.Visible = xlSheetHidden
    wsAnual.Activate

    Dim blockRows As Long: blockRows = nRec + nDesp + 15
    Dim base As Long

    If rStart > 0 Then
        wsAnual.Rows(rStart & ":" & rEnd).Delete
        base = rStart
    ElseIf firstOlder > 0 Then
        base = firstOlder           ' insere acima do primeiro bloco mais antigo
    ElseIf lastUsed > 0 Then
        base = lastUsed + 3         ' so ha blocos mais novos: anexa abaixo
    Else
        base = 1                    ' aba vazia
    End If
    wsAnual.Rows(base & ":" & base + blockRows - 1).Insert Shift:=xlDown
    wsAnual.Rows(base & ":" & base + blockRows - 1).Clear

    ' ---- cores ----
    Dim cGDark As Long, cGLight As Long, cRDark As Long, cRLight As Long
    Dim cBDark As Long, cBLight As Long, cNavy As Long, cWhite As Long, cBlack As Long
    cGDark = RGB(5, 150, 105): cGLight = RGB(236, 253, 245)
    cRDark = RGB(225, 29, 72): cRLight = RGB(255, 241, 242)
    cBDark = RGB(37, 99, 235): cBLight = RGB(239, 246, 255)
    cNavy = RGB(15, 23, 42): cWhite = RGB(255, 255, 255): cBlack = RGB(0, 0, 0)

    Dim fmtNum As String: fmtNum = "#,##0;-#,##0;""-"""
    Dim mNames As Variant
    mNames = Array("*JAN", "FEV", "MAR", "*ABR", "MAI", "JUN", "*JUL", "AGO", "SET", "*OUT", "NOV", "DEZ")

    ' ---- larguras (idempotente, vale para a pagina toda) ----
    wsAnual.Columns(1).ColumnWidth = 15
    wsAnual.Columns(2).ColumnWidth = 24
    Dim c As Long
    For c = 3 To 14: wsAnual.Columns(c).ColumnWidth = 8: Next c
    wsAnual.Columns(15).ColumnWidth = 10
    wsAnual.Columns(16).ColumnWidth = 11

    ' ---- titulo do bloco ----
    wsAnual.Range(wsAnual.Cells(base, 1), wsAnual.Cells(base, 16)).Merge
    wsAnual.Cells(base, 1).Value = "Dashboard Anual - " & ano
    wsAnual.Rows(base).RowHeight = 26
    With wsAnual.Range(wsAnual.Cells(base, 1), wsAnual.Cells(base, 16))
        .Interior.Color = cNavy
        .Font.Color = cWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 12
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
    End With

    ' ---- placar (C:E, G:I, K:M) ----
    Call PlacarAnual(wsAnual, base + 2, 3, 5, "RECEITA", somaRec, cGDark, cGLight, cWhite, cBlack)
    Call PlacarAnual(wsAnual, base + 2, 7, 9, "DESPESA", somaDesp, cRDark, cRLight, cWhite, cBlack)
    Call PlacarAnual(wsAnual, base + 2, 11, 13, "SALDO", somaRec - somaDesp, cBDark, cBLight, cWhite, cBlack)

    Dim r As Long: r = base + 5

    ' ================= BLOCO RECEITAS =================
    Call CabecalhoAnual(wsAnual, r, "Subcategoria", mNames, cGDark, cWhite, cBlack)
    r = r + 1
    Dim bg As Long, somaitem As Double
    For i = 0 To nRec - 1
        parts = Split(recKeys(i), "|")
        bg = IIf(i Mod 2 = 0, cWhite, cGLight)
        somaitem = 0
        For mes = 1 To 12
            wsAnual.Cells(r, 2 + mes).Value = recVals(mes, i)
            somaitem = somaitem + recVals(mes, i)
        Next mes
        wsAnual.Cells(r, 1).Value = parts(0)
        wsAnual.Cells(r, 2).Value = parts(1)
        wsAnual.Cells(r, 15).Value = somaitem / nMeses
        wsAnual.Cells(r, 16).Value = somaitem
        Call LinhaAnual(wsAnual, r, bg, cGDark, fmtNum, cBlack)
        wsAnual.Rows(r).RowHeight = 18
        r = r + 1
    Next i
    wsAnual.Cells(r, 2).Value = "Total de Receitas"
    For mes = 1 To 12: wsAnual.Cells(r, 2 + mes).Value = totRec(mes): Next mes
    wsAnual.Cells(r, 15).Value = somaRec / nMeses
    wsAnual.Cells(r, 16).Value = somaRec
    Call TotalAnual(wsAnual, r, cGDark, cWhite, fmtNum, cBlack)
    r = r + 2

    ' ================= BLOCO DESPESAS =================
    Call CabecalhoAnual(wsAnual, r, "Subcategoria", mNames, cRDark, cWhite, cBlack)
    r = r + 1
    For i = 0 To nDesp - 1
        parts = Split(despKeys(i), "|")
        bg = IIf(i Mod 2 = 0, cWhite, cRLight)
        somaitem = 0
        For mes = 1 To 12
            wsAnual.Cells(r, 2 + mes).Value = despVals(mes, i)
            somaitem = somaitem + despVals(mes, i)
        Next mes
        wsAnual.Cells(r, 1).Value = parts(0)
        wsAnual.Cells(r, 2).Value = parts(1)
        wsAnual.Cells(r, 15).Value = somaitem / nMeses
        wsAnual.Cells(r, 16).Value = somaitem
        Call LinhaAnual(wsAnual, r, bg, cRDark, fmtNum, cBlack)
        wsAnual.Rows(r).RowHeight = 18
        r = r + 1
    Next i
    wsAnual.Cells(r, 2).Value = "Total de Despesas"
    For mes = 1 To 12: wsAnual.Cells(r, 2 + mes).Value = totDesp(mes): Next mes
    wsAnual.Cells(r, 15).Value = somaDesp / nMeses
    wsAnual.Cells(r, 16).Value = somaDesp
    Call TotalAnual(wsAnual, r, cRDark, cWhite, fmtNum, cBlack)
    r = r + 2

    ' ================= SALDO DO MES =================
    wsAnual.Cells(r, 2).Value = "Saldo do Mes"
    For mes = 1 To 12
        wsAnual.Cells(r, 2 + mes).Value = totRec(mes) - totDesp(mes)
    Next mes
    wsAnual.Cells(r, 15).Value = (somaRec - somaDesp) / nMeses
    wsAnual.Cells(r, 16).Value = somaRec - somaDesp
    Call TotalAnual(wsAnual, r, cBDark, cWhite, fmtNum, cBlack)

    ' ================= SALDO ACUMULADO =================
    r = r + 1
    wsAnual.Cells(r, 2).Value = "Saldo Acumulado"
    Dim acum As Double: acum = 0
    For mes = 1 To 12
        acum = acum + totRec(mes) - totDesp(mes)
        If mes <= nMeses Then
            wsAnual.Cells(r, 2 + mes).Value = acum
        Else
            wsAnual.Cells(r, 2 + mes).Value = 0
        End If
    Next mes
    wsAnual.Cells(r, 15).Value = 0
    wsAnual.Cells(r, 16).Value = somaRec - somaDesp
    Call TotalAnual(wsAnual, r, cNavy, cWhite, fmtNum, cBlack)

    ' reproteger a aba (historico bloqueado contra edicao manual)
    ' garante o botao "Gerar Anual" fixo e visivel (corrige o sumico apos rodar):
    ' ancorado na coluna R (1 coluna apos a tabela, que vai ate P), linha 1,
    ' sempre acima dos blocos e fora da area de Insert/Delete de linhas.
    Call GarantirBotaoAnual(wsAnual)
    wsAnual.Protect

    Application.Calculation = calcPrev
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    MsgBox "Bloco de " & ano & " gerado! (media sobre " & nMeses & " meses)", vbInformation
End Sub

' ---- recria o botao Gerar Anual numa ancora fixa, free-floating ----
' Posicao: O3 -- ao lado do placar SALDO (K3:M3), pulando 1 coluna (N).
Private Sub GarantirBotaoAnual(ws As Worksheet)
    Dim b As Button, rg As Range
    Dim wasProt As Boolean: wasProt = ws.ProtectContents
    If wasProt Then ws.Unprotect
    ' remove botoes antigos para evitar duplicatas/sumico
    ws.Buttons.Delete
    Set rg = ws.Range("O3")          ' 1 coluna apos o placar SALDO (K:M)
    Set b = ws.Buttons.Add(rg.Left + 2, rg.Top + 2, 120, 26)
    b.Caption = "Gerar Anual"
    b.OnAction = "GerarDashboardAnual"
    b.Placement = xlFreeFloating     ' nao move nem some ao inserir/excluir linhas
    If wasProt Then ws.Protect
End Sub

' ---- placar do topo (label + valor) ----
Private Sub PlacarAnual(ws As Worksheet, rLabel As Long, c1 As Long, c2 As Long, _
    lbl As String, valor As Double, bgDark As Long, bgLight As Long, fWhite As Long, bClr As Long)
    ws.Range(ws.Cells(rLabel, c1), ws.Cells(rLabel, c2)).Merge
    ws.Range(ws.Cells(rLabel + 1, c1), ws.Cells(rLabel + 1, c2)).Merge
    ws.Cells(rLabel, c1).Value = lbl
    ws.Cells(rLabel + 1, c1).Value = valor
    ws.Rows(rLabel).RowHeight = 20
    ws.Rows(rLabel + 1).RowHeight = 20
    With ws.Range(ws.Cells(rLabel, c1), ws.Cells(rLabel, c2))
        .Interior.Color = bgDark
        .Font.Color = fWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = bClr
        End With
    End With
    With ws.Range(ws.Cells(rLabel + 1, c1), ws.Cells(rLabel + 1, c2))
        .Interior.Color = bgLight
        .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        .NumberFormat = "#,##0.00"
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = bClr
        End With
    End With
End Sub

' ---- cabecalho de bloco ----
Private Sub CabecalhoAnual(ws As Worksheet, r As Long, titulo As String, _
    mNames As Variant, bgClr As Long, fWhite As Long, bClr As Long)
    Dim c As Long
    ws.Cells(r, 1).Value = "Categoria"
    ws.Cells(r, 2).Value = titulo
    For c = 0 To 11
        ws.Cells(r, 3 + c).Value = mNames(c)
    Next c
    ws.Cells(r, 15).Value = "MENSAL"
    ws.Cells(r, 16).Value = "ANUAL"
    ws.Rows(r).RowHeight = 20
    With ws.Range(ws.Cells(r, 1), ws.Cells(r, 16))
        .Interior.Color = bgClr
        .Font.Color = fWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = bClr
        End With
    End With
End Sub

' ---- linha de item ----
Private Sub LinhaAnual(ws As Worksheet, r As Long, bgClr As Long, _
    secClr As Long, fmtNum As String, bClr As Long)
    With ws.Range(ws.Cells(r, 1), ws.Cells(r, 16))
        .Interior.Color = bgClr
        .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = bClr
        End With
    End With
    With ws.Cells(r, 1)
        .Font.Color = secClr: .Font.Bold = True
    End With
    ws.Range(ws.Cells(r, 3), ws.Cells(r, 16)).NumberFormat = fmtNum
End Sub

' ---- linha de total ----
Private Sub TotalAnual(ws As Worksheet, r As Long, bgClr As Long, _
    fWhite As Long, fmtNum As String, bClr As Long)
    ws.Rows(r).RowHeight = 20
    With ws.Range(ws.Cells(r, 1), ws.Cells(r, 16))
        .Interior.Color = bgClr
        .Font.Color = fWhite: .Font.Bold = True: .Font.Name = "Arial": .Font.Size = 11
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = bClr
        End With
    End With
    ws.Range(ws.Cells(r, 3), ws.Cells(r, 16)).NumberFormat = fmtNum
End Sub

' ============================================================
' LANCAR RECORRENTES - copia a tabela Recorrente para a Dados
' Pergunta o mes alvo (AAAA-MM); usa o DIA da data da recorrente.
' Pula itens com Valor vazio ou zero. Nao exporta a linha de total.
' Colunas Parcela e Termino sao apenas controle, nao sao exportadas.
' ============================================================
Sub LancarRecorrentes()
    Dim wsR As Worksheet, wsD As Worksheet
    Set wsR = ThisWorkbook.Sheets("Recorrente")
    Set wsD = ThisWorkbook.Sheets("Dados")
    Dim loR As ListObject, loD As ListObject
    Set loR = wsR.ListObjects("Recorrente")
    Set loD = wsD.ListObjects("ControleFinanceiro")
    If loR.DataBodyRange Is Nothing Then MsgBox "Tabela Recorrente vazia!", vbExclamation: Exit Sub

    Dim alvo As String
    alvo = InputBox("Lancar recorrentes em qual mes? (AAAA-MM)", "Lancar Recorrentes", Format(Date, "yyyy-mm"))
    If alvo = "" Then Exit Sub
    If Len(alvo) <> 7 Or Mid(alvo, 5, 1) <> "-" Or Not IsNumeric(Left(alvo, 4)) Or Not IsNumeric(Right(alvo, 2)) Then
        MsgBox "Formato invalido. Use AAAA-MM (ex: 2026-07).", vbExclamation: Exit Sub
    End If
    Dim anoA As Integer, mesA As Integer
    anoA = CInt(Left(alvo, 4)): mesA = CInt(Right(alvo, 2))
    If mesA < 1 Or mesA > 12 Then MsgBox "Mes invalido!", vbExclamation: Exit Sub

    If MsgBox("Lancar " & loR.ListRows.Count & " itens da Recorrente em " & alvo & "?", _
        vbYesNo + vbQuestion, "Lancar Recorrentes") <> vbYes Then Exit Sub

    Application.ScreenUpdating = False
    Application.EnableEvents = False

    Dim lastDay As Integer: lastDay = Day(DateSerial(anoA, mesA + 1, 0))
    Dim n As Long, i As Long, c As Long, dia As Integer
    Dim lr As ListRow, src As Range
    For i = 1 To loR.ListRows.Count
        Set src = loR.ListRows(i).Range
        Set lr = loD.ListRows.Add
        If IsDate(src.Cells(1, 2).Value) Then dia = Day(src.Cells(1, 2).Value) Else dia = 1
        If dia > lastDay Then dia = lastDay
        lr.Range.Cells(1, 1).Value = alvo
        lr.Range.Cells(1, 2).Value = DateSerial(anoA, mesA, dia)
        ' colunas 3-8 (Tipo..Pagamento) copiam direto; colunas I e J (Prestacao/Termino,
        ' 9 e 10) sao ignoradas de proposito - sao so controle na Recorrente, nao
        ' existem na Dados; Responsavel e Status vem das colunas 11 e 12 (K e L)
        For c = 3 To 8
            lr.Range.Cells(1, c).Value = src.Cells(1, c).Value
        Next c
        lr.Range.Cells(1, 9).Value = src.Cells(1, 11).Value
        lr.Range.Cells(1, 10).Value = src.Cells(1, 12).Value
        Call FormatarLinhaDados(wsD, lr.Range.Row)
        n = n + 1
    Next i

    Call OrdenarDados
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    MsgBox n & " lancamentos adicionados em " & alvo & "!", vbInformation
End Sub

' ---- formatacao padrao de uma linha da tabela Dados ----
Sub FormatarLinhaDados(ws As Worksheet, r As Long)
    With ws.Range(ws.Cells(r, 1), ws.Cells(r, 10))
        .Interior.Color = RGB(255, 255, 255)
        .Font.Name = "Arial": .Font.Size = 12: .Font.Bold = False
        .Font.Color = RGB(0, 0, 0)
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
    ws.Cells(r, 2).NumberFormat = "[$-416]d/mmm/yy;@"
    ws.Cells(r, 7).NumberFormat = "#,##0;[Red]#,##0"
End Sub

' ---- ordena a tabela Dados por Data (crescente) ----
Sub OrdenarDados()
    ' ordena por Data a tabela da aba ativa (Dados, Recorrente ou Plantues);
    ' se a aba ativa nao tiver tabela, ordena a ControleFinanceiro
    Dim lo As ListObject
    If ActiveSheet.ListObjects.Count > 0 Then
        Set lo = ActiveSheet.ListObjects(1)
    Else
        Set lo = ThisWorkbook.Sheets("Dados").ListObjects("ControleFinanceiro")
    End If
    If lo.DataBodyRange Is Nothing Then Exit Sub
    On Error Resume Next
    With lo.Sort
        .SortFields.Clear
        .SortFields.Add key:=lo.ListColumns("Data").DataBodyRange, SortOn:=xlSortOnValues, Order:=xlAscending
        .Header = xlYes
        .Apply
    End With
    On Error GoTo 0
End Sub

' ============================================================
' VALIDAR DADOS - varre a tabela e aponta inconsistencias:
' Ano/Mes x Data, ordem cronologica, Tipo, sinal do Valor,
' Categoria fora das listas Rec_Cat / Desp_Cat
' ============================================================
Sub ValidarDados()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets("Dados")
    Dim lastRow As Long: lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    Dim rngRC As Range, rngDC As Range
    Set rngRC = ThisWorkbook.Names("Rec_Cat").RefersToRange
    Set rngDC = ThisWorkbook.Names("Desp_Cat").RefersToRange

    Dim msg As String, nProb As Long, i As Long
    Dim am As String, tipo As String, cat As String, dt As Variant, v As Variant
    Dim prevD As Double: prevD = 0

    For i = 2 To lastRow
        am = CStr(ws.Cells(i, 1).Value)
        dt = ws.Cells(i, 2).Value
        tipo = CStr(ws.Cells(i, 3).Value)
        cat = CStr(ws.Cells(i, 4).Value)
        v = ws.Cells(i, 7).Value

        If Not IsDate(dt) Then
            msg = msg & vbCrLf & "Linha " & i & ": Data invalida ou vazia": nProb = nProb + 1
        Else
            If am <> Format(CDate(dt), "yyyy-mm") Then
                msg = msg & vbCrLf & "Linha " & i & ": Ano/Mes (" & am & ") difere da Data (" & Format(CDate(dt), "dd/mm/yyyy") & ")": nProb = nProb + 1
            End If
            If CDbl(CDate(dt)) < prevD Then
                msg = msg & vbCrLf & "Linha " & i & ": fora de ordem cronologica": nProb = nProb + 1
            End If
            prevD = CDbl(CDate(dt))
        End If

        If tipo <> "Receitas" And tipo <> "Despesas" Then
            msg = msg & vbCrLf & "Linha " & i & ": Tipo invalido (" & tipo & ")": nProb = nProb + 1
        Else
            If Not IsNumeric(v) Or IsEmpty(v) Then
                msg = msg & vbCrLf & "Linha " & i & ": Valor vazio ou invalido": nProb = nProb + 1
            ElseIf tipo = "Despesas" And v > 0 Then
                msg = msg & vbCrLf & "Linha " & i & ": Despesa com valor positivo": nProb = nProb + 1
            ElseIf tipo = "Receitas" And v < 0 Then
                msg = msg & vbCrLf & "Linha " & i & ": Receita com valor negativo": nProb = nProb + 1
            End If
            If tipo = "Receitas" Then
                If IsError(Application.Match(cat, rngRC, 0)) Then
                    msg = msg & vbCrLf & "Linha " & i & ": Categoria de receita fora da lista (" & cat & ")": nProb = nProb + 1
                End If
            Else
                If IsError(Application.Match(cat, rngDC, 0)) Then
                    msg = msg & vbCrLf & "Linha " & i & ": Categoria de despesa fora da lista (" & cat & ")": nProb = nProb + 1
                End If
            End If
        End If

        If nProb >= 25 Then
            msg = msg & vbCrLf & "... (parando no 25o problema)"
            Exit For
        End If
    Next i

    If nProb = 0 Then
        MsgBox "Nenhum problema encontrado! " & (lastRow - 1) & " lancamentos validados.", vbInformation, "Validar Dados"
    Else
        MsgBox "Encontrados " & nProb & " problema(s):" & vbCrLf & msg, vbExclamation, "Validar Dados"
    End If
End Sub

' ============================================================
' CRIAR BOTOES - cria os botoes de acao em todas as abas
' (rode uma unica vez; pode rodar de novo para recriar)
' ============================================================
' =====================================================================
' ATUALIZAR IMOVEIS - espelha os lancamentos da Dados na aba Imoveis
' Le a tabela de configuracao (linhas 5..13 da aba) e atualiza valores,
' status Pago/A pagar e totais de cada bloco. Roda junto do Gerar Mensal.
' =====================================================================
Sub AtualizarImoveis()
    Dim wsI As Worksheet, wsD As Worksheet
    Set wsI = ThisWorkbook.Sheets("Fluxo")
    Set wsD = ThisWorkbook.Sheets("Dados")
    Dim scrPrev As Boolean: scrPrev = Application.ScreenUpdating
    Application.ScreenUpdating = False
    Dim calcPrev As XlCalculation: calcPrev = Application.Calculation
    Application.Calculation = xlCalculationManual
    wsI.Unprotect

    Dim catImv As String: catImv = "Imoveis"

    ' ---- agregacao dos lancamentos (so Imoveis e Transporte) ----
    Dim lastD As Long: lastD = wsD.Cells(wsD.Rows.Count, 2).End(xlUp).Row
    Dim keysR() As String, valsR() As Double, pagoR() As Boolean
    Dim keysA() As String, valsA() As Double, pagoA() As Boolean
    Dim nR As Long, nA As Long
    ReDim keysR(1 To lastD): ReDim valsR(1 To lastD): ReDim pagoR(1 To lastD)
    ReDim keysA(1 To lastD): ReDim valsA(1 To lastD): ReDim pagoA(1 To lastD)

    ' ---- leitura em bloco + Collection para lookup rapido (Mac+Windows) ----
    ' Collection e nativa nas duas plataformas; Scripting.Dictionary so existe
    ' no Windows, por isso NAO e usado aqui. A chave da Collection guarda o
    ' indice (base-1) da posicao no array; ColIndex retorna 0 se nao existe.
    Dim dd As Variant
    If lastD >= 2 Then
        dd = wsD.Range(wsD.Cells(2, 1), wsD.Cells(lastD, 10)).Value
    End If
    Dim mapR As Collection, mapA As Collection
    Set mapR = New Collection
    Set mapA = New Collection

    Dim r As Long, cat As String, sub_ As String, resp As String, comp As String
    Dim v As Double, pago As Boolean, k As String, ix As Long
    For r = 1 To lastD - 1
        If CStr(dd(r, 3)) = "Despesas" Then
            cat = CStr(dd(r, 4))
            If cat = catImv Or cat = "Transporte" Then
                sub_ = CStr(dd(r, 5))
                comp = CStr(dd(r, 1))
                resp = CStr(dd(r, 9))
                v = Abs(Val(dd(r, 7) & ""))
                pago = (CStr(dd(r, 10)) = "Pago")
                k = cat & "|" & sub_ & "|" & resp & "|" & comp
                ix = ColIndex(mapR, k)
                If ix = 0 Then
                    nR = nR + 1: keysR(nR) = k: valsR(nR) = 0: pagoR(nR) = True: ix = nR
                    mapR.Add ix, k
                End If
                valsR(ix) = valsR(ix) + v
                pagoR(ix) = pagoR(ix) And pago
                k = cat & "|" & sub_ & "|" & comp
                ix = ColIndex(mapA, k)
                If ix = 0 Then
                    nA = nA + 1: keysA(nA) = k: valsA(nA) = 0: pagoA(nA) = True: ix = nA
                    mapA.Add ix, k
                End If
                valsA(ix) = valsA(ix) + v
                pagoA(ix) = pagoA(ix) And pago
            End If
        End If
    Next r

    ' ---- processa os blocos da tabela de configuracao ----
    Dim cfgR As Long
    Dim bcat As String, bsubs As String, bresps As String
    Dim btipo As String, bcol As Long, brow As Long, bcor As String
    Dim subsArr() As String
    ' config em BJ3:BQ12 (col 62, linhas 4-12) -- layout deslocado +5 col / +1 linha
    Dim cfgBase As Long: cfgBase = 62
    For cfgR = 4 To 12
        If CStr(wsI.Cells(cfgR, cfgBase).Value) <> "" And _
           CStr(wsI.Cells(cfgR, cfgBase + 2).Value) <> "" Then
            bcat = CStr(wsI.Cells(cfgR, cfgBase + 1).Value)
            bsubs = CStr(wsI.Cells(cfgR, cfgBase + 2).Value)
            bresps = CStr(wsI.Cells(cfgR, cfgBase + 3).Value)
            btipo = CStr(wsI.Cells(cfgR, cfgBase + 4).Value)
            bcol = CLng(wsI.Cells(cfgR, cfgBase + 5).Value)
            brow = CLng(wsI.Cells(cfgR, cfgBase + 6).Value)
            bcor = CStr(wsI.Cells(cfgR, cfgBase + 7).Value)
            subsArr = Split(bsubs, "|")
            Dim sIdx As Long
            For sIdx = 0 To UBound(subsArr)
                subsArr(sIdx) = Trim(subsArr(sIdx))
            Next sIdx
            ' para blocos ABERTA: usar subcategorias hardcoded via ChrW (100% confiavel)
            Dim sp1 As String, sp2 As String, bNome As String
            bNome = AsciiKey(CStr(wsI.Cells(cfgR, cfgBase).Value))
            If bNome = "ONIX" Then
                sp1 = "Onix - prestacao"
                sp2 = "Onix - prazo"
            ElseIf bNome = "LANGE" Then
                sp1 = "Lange - prestacao"
                sp2 = "Lange - prazo"
            Else
                sp1 = ""
                sp2 = ""
                If UBound(subsArr) >= 0 Then sp1 = subsArr(0)
                If UBound(subsArr) >= 1 Then sp2 = subsArr(1)
            End If
            If btipo = "FIXA" And bresps = "" Then
                Call AtuFixaSimples(wsI, bcol, brow, bcat, subsArr(0), keysA, valsA, pagoA, nA)
            ElseIf btipo = "FIXA" Then
                Call AtuFixaDupla(wsI, bcol, brow, bcat, subsArr(0), keysR, valsR, pagoR, nR)
            ElseIf UBound(subsArr) >= 1 Then
                Call AtuAberta(wsI, bcol, brow, bcat, sp1, sp2, keysR, valsR, pagoR, nR, bcor)
            End If
        End If
    Next cfgR

    ' ---- autofit apenas da Fluxo (unica aba com linhas regeneradas);
    '      Dados/Recorrente tem largura fixa e nao precisam de autofit ----
    wsI.UsedRange.Columns.AutoFit

    wsI.Protect
    Application.Calculation = calcPrev
    Application.ScreenUpdating = scrPrev
End Sub

' ---- bloco FIXA com um responsavel (208, Compass): atualiza valor real e status ----
Private Sub AtuFixaSimples(ws As Worksheet, col As Long, row0 As Long, cat As String, _
    sub_ As String, keys() As String, vals() As Double, pagos() As Boolean, n As Long)
    Dim r As Long: r = row0
    Dim comp As String, ix As Long
    Do While CStr(ws.Cells(r, col).Value) <> ""
        comp = CStr(ws.Cells(r, col + 1).Value)
        ix = FindKey1(keys, n, cat & "|" & sub_ & "|" & comp)
        If ix <> -1 Then
            ws.Cells(r, col + 2).Value = vals(ix)
            ws.Cells(r, col + 3).Value = IIf(pagos(ix), "Pago", "A pagar")
        Else
            ws.Cells(r, col + 3).Value = "A pagar"
        End If
        r = r + 1
    Loop
End Sub

' ---- bloco FIXA com Mario e Pri (consorcios) ----
Private Sub AtuFixaDupla(ws As Worksheet, col As Long, row0 As Long, cat As String, _
    sub_ As String, keys() As String, vals() As Double, pagos() As Boolean, n As Long)
    Dim r As Long: r = row0
    Dim comp As String, ixM As Long, ixP As Long, okTudo As Boolean
    Do While CStr(ws.Cells(r, col).Value) <> ""
        comp = CStr(ws.Cells(r, col + 1).Value)
        ixM = FindKey1(keys, n, cat & "|" & sub_ & "|Mario|" & comp)
        ixP = FindKey1(keys, n, cat & "|" & sub_ & "|Pri|" & comp)
        If ixM <> -1 Then ws.Cells(r, col + 2).Value = vals(ixM)
        If ixP <> -1 Then ws.Cells(r, col + 3).Value = vals(ixP)
        okTudo = (ixM <> -1 Or ixP <> -1)
        If ixM <> -1 Then okTudo = okTudo And pagos(ixM)
        If ixP <> -1 Then okTudo = okTudo And pagos(ixP)
        ws.Cells(r, col + 4).Value = IIf(okTudo, "Pago", "A pagar")
        r = r + 1
    Loop
End Sub

' ---- bloco ABERTA (Onix, Lange): regenera as linhas a partir da Dados ----
Private Sub AtuAberta(ws As Worksheet, col As Long, row0 As Long, cat As String, _
    subPrest As String, subPrazo As String, keys() As String, vals() As Double, _
    pagos() As Boolean, n As Long, corHex As String)

    ' competencias unicas das 4 series
    Dim comps() As String, nc As Long
    ReDim comps(1 To n + 1)
    Dim i As Long, j As Long, parts() As String, tmp As String
    For i = 1 To n
        parts = Split(keys(i), "|")
        Dim pi As Long: For pi = 0 To UBound(parts): parts(pi) = Trim(parts(pi)): Next pi
        If parts(0) = cat And (parts(1) = subPrest Or parts(1) = subPrazo) Then
            If FindKey1(comps, nc, parts(3)) = -1 Then
                nc = nc + 1: comps(nc) = parts(3)
            End If
        End If
    Next i
    For i = 1 To nc - 1
        For j = 1 To nc - i
            If comps(j) > comps(j + 1) Then
                tmp = comps(j): comps(j) = comps(j + 1): comps(j + 1) = tmp
            End If
        Next j
    Next i

    ' limpar regiao antiga (dados + totais), preservando banner e legendas
    Dim reg As Range
    Set reg = ws.Range(ws.Cells(row0, col), ws.Cells(row0 + 400, col + 6))
    reg.UnMerge
    reg.Clear

    Dim corL As Long
    corL = RGB(CLng("&H" & Mid(corHex, 1, 2)), CLng("&H" & Mid(corHex, 3, 2)), CLng("&H" & Mid(corHex, 5, 2)))

    Dim r As Long: r = row0
    Dim comp As String, ix As Long, allPago As Boolean, anyEx As Boolean, cIdx As Long
    Dim defSub(1 To 4) As String, defResp(1 To 4) As String
    defSub(1) = subPrest: defResp(1) = "Mario"
    defSub(2) = subPrazo: defResp(2) = "Mario"
    defSub(3) = subPrest: defResp(3) = "Pri"
    defSub(4) = subPrazo: defResp(4) = "Pri"
    For i = 1 To nc
        comp = comps(i)
        ws.Cells(r, col).Value = i
        ws.Cells(r, col + 1).Value = comp
        allPago = True: anyEx = False
        For cIdx = 1 To 4
            ix = FindKey1(keys, n, cat & "|" & defSub(cIdx) & "|" & defResp(cIdx) & "|" & comp)
            If ix <> -1 Then
                ws.Cells(r, col + 1 + cIdx).Value = vals(ix)
                anyEx = True
                allPago = allPago And pagos(ix)
            End If
        Next cIdx
        ws.Cells(r, col + 6).Value = IIf(anyEx And allPago, "Pago", "A pagar")
        Call FmtLinhaImv(ws, r, col, col + 6)
        ' forca cor do Status: verde+negrito se Pago, vermelho+negrito se A pagar
        With ws.Cells(r, col + 6).Font
            .Bold = True
            If ws.Cells(r, col + 6).Value = "Pago" Then
                .Color = RGB(5, 150, 105)
            Else
                .Color = RGB(225, 29, 72)
            End If
        End With
        r = r + 1
    Next i

    Dim fim As Long: fim = r - 1
    ' linha TOTAL
    ws.Cells(r, col + 1).Value = "TOTAL"
    For cIdx = 2 To 5
        ws.Cells(r, col + cIdx).FormulaR1C1 = "=SUM(R" & row0 & "C" & (col + cIdx) & ":R" & fim & "C" & (col + cIdx) & ")"
        ws.Cells(r, col + cIdx).NumberFormat = "#,##0.00"
    Next cIdx
    Call FmtTotImv(ws, r, col, col + 6, corL)
    ' linha Saldo Pri - Mario
    r = r + 1
    ws.Cells(r, col).Value = "Saldo Pri - Mario"
    ws.Cells(r, col + 5).FormulaR1C1 = "=(R" & (fim + 1) & "C" & (col + 4) & "+R" & (fim + 1) & "C" & (col + 5) & ")-(R" & (fim + 1) & "C" & (col + 2) & "+R" & (fim + 1) & "C" & (col + 3) & ")"
    ws.Cells(r, col + 5).NumberFormat = "#,##0.00"
    Call FmtTotImv(ws, r, col, col + 6, corL)
End Sub

' ---- formatacao de linha de dados da aba Imoveis ----
Private Sub FmtLinhaImv(ws As Worksheet, r As Long, c1 As Long, c2 As Long)
    With ws.Range(ws.Cells(r, c1), ws.Cells(r, c2))
        .Interior.Color = RGB(255, 255, 255)
        .Font.Name = "Arial": .Font.Size = 11: .Font.Bold = False
        .Font.Color = RGB(0, 0, 0)
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
    ws.Range(ws.Cells(r, c1 + 2), ws.Cells(r, c1 + 5)).NumberFormat = "#,##0.00"
End Sub

' ---- formatacao de linha de total da aba Imoveis ----
Private Sub FmtTotImv(ws As Worksheet, r As Long, c1 As Long, c2 As Long, corL As Long)
    With ws.Range(ws.Cells(r, c1), ws.Cells(r, c2))
        .Interior.Color = corL
        .Font.Name = "Arial": .Font.Size = 11: .Font.Bold = True
        .Font.Color = RGB(255, 255, 255)
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        With .Borders
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With
End Sub

Sub CriarBotoes()
    Dim ws As Worksheet
    Dim lastR As Long, loR As ListObject

    ' ------- DADOS: botoes na coluna L, a partir da ultima linha da tabela -------
    Set ws = ThisWorkbook.Sheets("Dados")
    ws.Buttons.Delete
    lastR = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    Call AddBtnAt(ws, lastR, 12, "Limpar Filtros", "LimparFiltros")
    Call AddBtnAt(ws, lastR + 2, 12, "Ordenar Dados", "OrdenarDados")
    Call AddBtnAt(ws, lastR + 4, 12, "Validar Dados", "ValidarDados")

    ' ------- RECORRENTE: botoes na coluna M, a partir da ultima linha da tabela -------
    Set ws = ThisWorkbook.Sheets("Recorrente")
    ws.Buttons.Delete
    Set loR = ws.ListObjects("Recorrente")
    lastR = loR.Range.Row + loR.Range.Rows.Count - 1
    Call AddBtnAt(ws, lastR, 13, "Lancar no Mes", "LancarRecorrentes")
    Call AddBtnAt(ws, lastR + 2, 13, "Limpar Filtros", "LimparFiltros")
    Call AddBtnAt(ws, lastR + 4, 13, "Ordenar Dados", "OrdenarDados")
    Call AddBtnAt(ws, lastR + 6, 13, "Validar Dados", "ValidarDados")
    Call AddBtnAt(ws, lastR + 8, 13, "Sincronizar Coluna N", "SincronizarColunaN")

    ' ------- PLANTOES: botoes na coluna G, a partir da ultima linha da tabela -------
    Set ws = ThisWorkbook.Sheets("Plantoes")
    ws.Buttons.Delete
    Set loR = ws.ListObjects("Plantoes")
    lastR = loR.Range.Row + loR.Range.Rows.Count - 1
    Call AddBtnAt(ws, lastR, 7, "Limpar Filtros", "LimparFiltros")
    Call AddBtnAt(ws, lastR + 2, 7, "Ordenar Dados", "OrdenarDados")
    Call AddBtnAt(ws, lastR + 4, 7, "Validar Dados", "ValidarDados")

    ' ------- MENSAL -------
    Set ws = ThisWorkbook.Sheets("Mensal")
    ws.Buttons.Delete
    Call AddBtn(ws, "M3", "Gerar Mensal", "GerarDashboard")

    ' ------- ANUAL -------
    Set ws = ThisWorkbook.Sheets("Anual")
    Call GarantirBotaoAnual(ws)

    MsgBox "Botoes criados nas abas Dados, Recorrente, Plantoes, Mensal e Anual!", vbInformation
End Sub



' ---- botao ancorado em linha+coluna ----
Private Sub AddBtnAt(ws As Worksheet, r As Long, col As Long, cap As String, macroName As String)
    Dim b As Button
    Set b = ws.Buttons.Add(ws.Cells(r, col).Left + 2, ws.Cells(r, col).Top + 2, 130, 22)
    b.Caption = cap
    b.OnAction = macroName
End Sub

Private Sub AddBtn(ws As Worksheet, anchor As String, cap As String, macroName As String)
    Dim b As Button, rg As Range
    Set rg = ws.Range(anchor)
    Set b = ws.Buttons.Add(rg.Left + 2, rg.Top + 2, 120, 26)
    b.Caption = cap
    b.OnAction = macroName
End Sub

' ---- reativa eventos do Excel (use se o duplo clique parar de responder) ----
Sub ReativarEventos()
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    MsgBox "Eventos reativados!", vbInformation
End Sub
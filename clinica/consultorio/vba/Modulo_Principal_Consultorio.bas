Option Explicit

' ================================================================
' MODULO PRINCIPAL - CONSULTORIO.xlsm
' Abas: Plantoes, Pacientes, Consultas, Convenios, Exames, Listas (oculta)
'
' Este e um modulo ENXUTO, so com o que faz sentido no arquivo do
' consultorio. As macros financeiras (GerarDashboard, LancarRecorrentes,
' AtualizarImoveis, dashboards Mensal/Anual, etc.) ficaram no
' orcamento_6_6.xlsm e NAO existem aqui.
'
' COMO INSTALAR (Mac, colar direto no VBE):
'   1) Alt+F11 (ou Ferramentas > Macro > Editor do Visual Basic)
'   2) Menu Inserir > Modulo
'   3) Cole TODO este bloco no painel de codigo do modulo novo. Ctrl+S.
' ================================================================

' ---- limpa os filtros e reexibe todas as linhas da aba ativa ----
Sub LimparFiltros()
    Dim ws As Worksheet: Set ws = ActiveSheet
    Dim lo As ListObject
    On Error Resume Next
    If ws.ListObjects.Count > 0 Then Set lo = ws.ListObjects(1)
    If Not lo Is Nothing Then
        If lo.AutoFilter Is Nothing Then
            ws.AutoFilterMode = False
        Else
            lo.AutoFilter.ShowAllData
        End If
    End If
    ws.Rows.Hidden = False
    On Error GoTo 0
End Sub

' ---- ordena a tabela da aba ativa por Data (crescente) ----
'      (Plantoes tem coluna "Data"; nas demais abas o botao nao existe) ----
Sub OrdenarDados()
    Dim lo As ListObject
    If ActiveSheet.ListObjects.Count = 0 Then Exit Sub
    Set lo = ActiveSheet.ListObjects(1)
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
' VALIDAR DADOS - versao Plantoes: confere Competencia x Data,
' ordem cronologica e dia da semana coerente com a Data.
' (O botao "Validar Dados" fica na aba Plantoes. Roda sempre
' sobre a aba Plantoes, mesmo se o botao estiver em outra aba.)
' ============================================================
Sub ValidarDados()
    Dim ws As Worksheet: Set ws = ThisWorkbook.Sheets("Plantoes")
    Dim lastRow As Long: lastRow = ws.Cells(ws.Rows.Count, 2).End(xlUp).Row
    Dim msg As String, nProb As Long, i As Long
    Dim comp As String, dt As Variant, diaTxt As String
    Dim prevD As Double: prevD = 0
    Dim dias As Variant
    dias = Array("Domingo", "Segunda", "Terca", "Quarta", "Quinta", "Sexta", "Sabado")

    For i = 2 To lastRow
        comp = CStr(ws.Cells(i, 1).Value)
        dt = ws.Cells(i, 2).Value
        diaTxt = CStr(ws.Cells(i, 3).Value)

        If Not IsDate(dt) Then
            msg = msg & vbCrLf & "Linha " & i & ": Data invalida ou vazia": nProb = nProb + 1
        Else
            If comp <> "" And comp <> Format(CDate(dt), "yyyy-mm") Then
                msg = msg & vbCrLf & "Linha " & i & ": Competencia (" & comp & ") difere da Data (" & Format(CDate(dt), "dd/mm/yyyy") & ")": nProb = nProb + 1
            End If
            If CDbl(CDate(dt)) < prevD Then
                msg = msg & vbCrLf & "Linha " & i & ": fora de ordem cronologica": nProb = nProb + 1
            End If
            prevD = CDbl(CDate(dt))
            If diaTxt <> "" Then
                If diaTxt <> dias(Weekday(CDate(dt)) - 1) Then
                    msg = msg & vbCrLf & "Linha " & i & ": Dia da Semana (" & diaTxt & ") nao bate com a Data": nProb = nProb + 1
                End If
            End If
        End If

        If nProb >= 25 Then
            msg = msg & vbCrLf & "... (parando no 25o problema)"
            Exit For
        End If
    Next i

    If nProb = 0 Then
        MsgBox "Nenhum problema encontrado! " & (lastRow - 1) & " plantoes validados.", vbInformation, "Validar Dados"
    Else
        MsgBox "Encontrados " & nProb & " problema(s):" & vbCrLf & msg, vbExclamation, "Validar Dados"
    End If
End Sub

' ============================================================
' CRIAR BOTOES - recria os 3 botoes na aba Plantoes
' (rode uma unica vez apos importar os modulos; pode rodar de novo)
' ============================================================
Sub CriarBotoes()
    Dim ws As Worksheet, loR As ListObject, lastR As Long
    Set ws = ThisWorkbook.Sheets("Plantoes")
    ws.Buttons.Delete
    Set loR = ws.ListObjects("Plantoes")
    lastR = loR.Range.Row + loR.Range.Rows.Count - 1
    Call AddBtnAt(ws, lastR, 7, "Limpar Filtros", "LimparFiltros")
    Call AddBtnAt(ws, lastR + 2, 7, "Ordenar Dados", "OrdenarDados")
    Call AddBtnAt(ws, lastR + 4, 7, "Validar Dados", "ValidarDados")
    MsgBox "Botoes criados na aba Plantoes!", vbInformation
End Sub

' ============================================================
' CRIAR BOTOES PACIENTES - recria os 3 botoes na aba Pacientes,
' logo abaixo da tabela TB_Pacientes (mesmo padrao de CriarBotoes).
' (rode uma unica vez; pode rodar de novo para reposicionar)
'
' Atencao ao reaproveitar os mesmos 3 botoes nesta aba:
'   - "Limpar Filtros" funciona normalmente aqui (usa a aba ativa).
'   - "Ordenar Dados" nao faz nada em Pacientes: a tabela TB_Pacientes
'     nao tem coluna chamada "Data" (tem NASC), entao a macro sai sem
'     ordenar nada.
'   - "Validar Dados" sempre valida a aba Plantoes, nao Pacientes,
'     porque a macro esta fixa em ThisWorkbook.Sheets("Plantoes").
' ============================================================
Sub CriarBotoesPacientes()
    Dim ws As Worksheet, loP As ListObject, lastR As Long
    Set ws = ThisWorkbook.Sheets("Pacientes")
    ws.Buttons.Delete
    Set loP = ws.ListObjects("TB_Pacientes")
    lastR = loP.Range.Row + loP.Range.Rows.Count - 1
    Call AddBtnAt(ws, lastR, 8, "Limpar Filtros", "LimparFiltros")
    Call AddBtnAt(ws, lastR + 2, 8, "Ordenar Dados", "OrdenarDados")
    Call AddBtnAt(ws, lastR + 4, 8, "Validar Dados", "ValidarDados")
    MsgBox "Botoes criados na aba Pacientes!", vbInformation
End Sub

Private Sub AddBtnAt(ws As Worksheet, r As Long, col As Long, cap As String, macroName As String)
    Dim b As Button
    Set b = ws.Buttons.Add(ws.Cells(r, col).Left + 2, ws.Cells(r, col).Top + 2, 130, 22)
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

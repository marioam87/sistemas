' ================================================================
' DUPLO CLIQUE NA DATA + FORMATACAO AUTOMATICA - CONSULTORIO.xlsm
' Cole em "EstaPasta_de_trabalho" (ThisWorkbook), NAO num modulo comum.
'
' Contem dois eventos de planilha:
'
' 1) Workbook_SheetBeforeDoubleClick
'    Age na aba Plantoes, coluna B (Data), fora do cabecalho:
'      - preenche a Competencia (coluna A) no formato yyyy-mm
'      - preenche o Dia da Semana (coluna C) automaticamente
'      - formata a linha inteira (A:E)
'
' 2) Workbook_SheetChange
'    Age na aba Pacientes, tabela TB_Pacientes: sempre que uma celula
'    de uma linha da tabela e editada (nova ficha ou correcao), a
'    linha inteira e reformatada (fonte Arial 12 preta, sem negrito,
'    fundo branco, bordas finas, centralizado). Isso evita o problema
'    de linhas no fim da tabela "perdendo" a formatacao (por exemplo
'    ficando com fonte azul e caixa de borda diferente) quando dados
'    sao colados ou preenchidos via Tab.
'
' Usa o parametro "Sh" (nunca "Me"), por isso funciona colado no
' ThisWorkbook. Testado: nao depende de Dados/Recorrente nem de
' nenhuma aba que ficou no orcamento.
'
' COMO INSTALAR (Mac):
'   1) Alt+F11
'   2) No Project Explorer, duplo clique em "EstaPasta_de_trabalho"
'   3) Cole TODO este bloco. Ctrl+S.
' ================================================================

Private Sub Workbook_SheetBeforeDoubleClick(ByVal Sh As Object, ByVal Target As Range, Cancel As Boolean)

    If Sh.Name <> "Plantoes" Then Exit Sub
    If Target.Column <> 2 Or Target.Row <= 1 Then Exit Sub

    Cancel = True
    Dim s As String
    s = InputBox("Data (dd/mm/aaaa):", "Data", Format(Date, "dd/mm/yyyy"))
    If s = "" Or Not IsDate(s) Then Exit Sub

    Application.EnableEvents = False

    Dim d As Date: d = CDate(s)
    Target.Value = d
    Target.Offset(0, -1).Value = Format(d, "yyyy-mm")   ' coluna A = Competencia

    ' dia da semana automatico na coluna C (sem acentos)
    Dim dias As Variant
    dias = Array("Domingo", "Segunda", "Terca", "Quarta", "Quinta", "Sexta", "Sabado")
    Sh.Cells(Target.Row, 3).Value = dias(Weekday(d) - 1)

    ' formata a linha inteira (A:E)
    With Sh.Range(Sh.Cells(Target.Row, 1), Sh.Cells(Target.Row, 5))
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

    Target.NumberFormat = "[$-416]d/mmm/yy;@"

    Application.EnableEvents = True
End Sub

' ============================================================
' FORMATACAO AUTOMATICA - aba Pacientes / tabela TB_Pacientes
'
' Sempre que uma celula dentro do corpo de dados da TB_Pacientes e
' alterada (nova linha digitada, Tab no fim da tabela, colar dados,
' correcao de um campo existente etc.), reaplica a formatacao padrao
' na linha inteira daquela tabela: fonte Arial 12 preta sem negrito,
' fundo branco, bordas finas e centralizado.
'
' Isso resolve o efeito de "perder a formatacao" ao chegar no fim da
' tabela: nao importa a causa (colar de outra fonte, autocompletar,
' etc.), a linha sempre volta a ficar igual as demais.
' ============================================================
Private Sub Workbook_SheetChange(ByVal Sh As Object, ByVal Target As Range)

    If Sh.Name <> "Pacientes" Then Exit Sub

    Dim lo As ListObject
    On Error Resume Next
    Set lo = Sh.ListObjects("TB_Pacientes")
    On Error GoTo 0
    If lo Is Nothing Then Exit Sub
    If lo.DataBodyRange Is Nothing Then Exit Sub

    Dim inter As Range
    Set inter = Application.Intersect(Target, lo.DataBodyRange)
    If inter Is Nothing Then Exit Sub

    Application.EnableEvents = False

    Dim primeiraCol As Long, ultimaCol As Long
    primeiraCol = lo.Range.Column
    ultimaCol = lo.Range.Column + lo.ListColumns.Count - 1

    Dim r As Range
    For Each r In inter.Rows
        With Sh.Range(Sh.Cells(r.Row, primeiraCol), Sh.Cells(r.Row, ultimaCol))
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
    Next r

    Application.EnableEvents = True
End Sub

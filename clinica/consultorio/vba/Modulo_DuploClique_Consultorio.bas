' ================================================================
' DUPLO CLIQUE NA DATA - CONSULTORIO.xlsm
' Cole em "EstaPasta_de_trabalho" (ThisWorkbook), NAO num modulo comum.
'
' Age na aba Plantoes, coluna B (Data), fora do cabecalho:
'   - preenche a Competencia (coluna A) no formato yyyy-mm
'   - preenche o Dia da Semana (coluna C) automaticamente
'   - formata a linha inteira (A:E)
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

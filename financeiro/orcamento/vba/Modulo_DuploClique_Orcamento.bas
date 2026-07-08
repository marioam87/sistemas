' ================================================================
' DUPLO CLIQUE NA DATA - ORCAMENTO_6_6.xlsm
' Cole em "EstaPasta_de_trabalho" (ThisWorkbook), NAO num modulo comum.
'
' Age nas abas Dados e Recorrente, coluna B (Data), fora do cabecalho.
' (A aba Plantoes foi movida para o consultorio.xlsm, entao nao consta
'  mais aqui.)
'
' COMO INSTALAR (Mac):
'   1) Alt+F11
'   2) No Project Explorer, duplo clique em "EstaPasta_de_trabalho"
'   3) Cole TODO este bloco. Ctrl+S.
' ================================================================

Private Sub Workbook_SheetBeforeDoubleClick(ByVal Sh As Object, ByVal Target As Range, Cancel As Boolean)

    Select Case Sh.Name
        Case "Dados", "Recorrente"
        Case Else: Exit Sub
    End Select
    If Target.Column <> 2 Or Target.Row <= 1 Then Exit Sub

    Cancel = True
    Dim s As String
    s = InputBox("Data (dd/mm/aaaa):", "Data", Format(Date, "dd/mm/yyyy"))
    If s = "" Or Not IsDate(s) Then Exit Sub

    Application.EnableEvents = False

    Dim d As Date: d = CDate(s)
    Target.Value = d
    Target.Offset(0, -1).Value = Format(d, "yyyy-mm")   ' coluna A = Ano/Mes

    Dim lastCol As Long
    Select Case Sh.Name
        Case "Dados":      lastCol = 10
        Case "Recorrente": lastCol = 11
    End Select

    With Sh.Range(Sh.Cells(Target.Row, 1), Sh.Cells(Target.Row, lastCol))
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
    Sh.Cells(Target.Row, 7).NumberFormat = "#,##0;[Red]#,##0"  ' coluna G = Valor

    Application.EnableEvents = True
End Sub

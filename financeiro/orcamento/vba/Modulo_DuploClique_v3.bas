Attribute VB_Name = "Modulo_DuploClique_v3"
' ================================================================
' DUPLO CLIQUE NA DATA - VERSAO 3 (bloco unico, a prova de falhas)
'
' POR QUE A V2 DAVA "Membro de dados ou metodo nao encontrado":
'   O codigo da v2 usava "Me.Cells / Me.Range". Isso so e valido
'   dentro do modulo de UMA planilha. Quando o bloco e colado em
'   "EstaPasta_de_trabalho" (ThisWorkbook), "Me" passa a ser a
'   PASTA DE TRABALHO, que nao possui .Cells nem .Range -> erro de
'   compilacao marcando justamente o "Cells".
'
' ESTA VERSAO usa o parametro "Sh" (a planilha do duplo clique) em
' vez de "Me", entao funciona colada em "EstaPasta_de_trabalho" e
' atende as 3 abas (Dados, Plantoes, Recorrente) com um unico bloco.
'
' COMO INSTALAR:
'   1) Alt+F11 para abrir o editor de VBA.
'   2) No "Project Explorer" (canto esquerdo), em "Microsoft Excel
'      Objetos", de DUPLO CLIQUE em "EstaPasta_de_trabalho"
'      (codinome EstaPastaDeTrabalho3).
'   3) IMPORTANTE: se voce ja colou os blocos antigos (A, B, C) em
'      qualquer lugar, APAGUE-OS para nao duplicar o evento.
'   4) Cole TODO o conteudo abaixo nessa janela.  Ctrl+S.
'
' OBS: o nome do procedimento ja indica a Pasta de Trabalho. Nao
'      cole isto no modulo de uma planilha nem num "Modulo" comum.
' ================================================================

Private Sub Workbook_SheetBeforeDoubleClick(ByVal Sh As Object, ByVal Target As Range, Cancel As Boolean)

    ' so age nas tres abas de lancamento, coluna B (Data), fora do cabecalho
    Select Case Sh.Name
        Case "Dados", "Plantoes", "Recorrente"
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

    ' ultima coluna formatada por aba
    Dim lastCol As Long
    Select Case Sh.Name
        Case "Dados":      lastCol = 10
        Case "Recorrente": lastCol = 11
        Case "Plantoes":   lastCol = 5
    End Select

    ' dia da semana automatico na aba Plantoes (coluna C) - sem acentos
    If Sh.Name = "Plantoes" Then
        Dim dias As Variant
        dias = Array("Domingo", "Segunda", "Terca", "Quarta", "Quinta", "Sexta", "Sabado")
        Sh.Cells(Target.Row, 3).Value = dias(Weekday(d) - 1)
    End If

    ' formata a linha inteira no padrao da tabela
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
    If Sh.Name = "Dados" Or Sh.Name = "Recorrente" Then
        Sh.Cells(Target.Row, 7).NumberFormat = "#,##0;[Red]#,##0"  ' coluna G = Valor
    End If

    Application.EnableEvents = True
End Sub

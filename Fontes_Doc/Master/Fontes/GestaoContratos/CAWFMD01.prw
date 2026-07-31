#include "totvs.ch"

/*/{Protheus.doc} CAWFMD01
Monta e dispara o e-mail de workflow de aprovacao de inclusao de Medicao
de Contrato (rotina CNTA121), para o nivel de alcada pendente na tabela
SCR (CR_TIPO = "MD"). Espera a tabela CND posicionada no registro da
medicao a ser enviada para aprovacao.
@type function
@author Delson Junior Antunes
@since 06/07/2026
/*/
User Function CAWFMD01()

	Local aArea       := GetArea()
	Local aAreaCND    := CND->(GetArea())
	Local aAreaCNE    := CNE->(GetArea())
	Local aAreaCN9    := CN9->(GetArea())
	Local aAreaSA1    := SA1->(GetArea())
	Local aAreaSCR    := SCR->(GetArea())
	Local cTo         := ""
	Local cNumMed     := ""
	Local cChave      := ""
	Local cAprov      := ""
	Local cObs        := ""
	Local cStatus     := ""
	Local cAssunto    := ""
	Local cMailId     := ""
	Local cBody       := ""
	Local cFooter     := ""
	Local cHtmlModelo := ""
	Local cURLWF      := GetNewPar("ZZ_URLWF", "https://caoachery188151.protheus.cloudtotvs.com.br:11121/workflow")
	Local cEmpWF      := GetNewPar("ZZ_EMPWF", "emp01")
	Local nVlrTotal   := 0
	Local oProcess
	Local oHTML

	CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	CN9->(dbSeek(CND->CND_FILIAL + CND->CND_CONTRA + CND->CND_REVISA))

	oProcess := TWFProcess():New("WFMEDICAO", "Workflow de Aprovacao de Medicao de Contrato")
	oProcess:NewTask("000006", "\WORKFLOW\WFAPROVACAO.HTM")
	oProcess:cSubject := "Workflow de Aprovacao de Medicao de Contrato " + CND->CND_NUMMED
	oProcess:bReturn := "U_CAWFMD02()"
	oProcess:fDesc := "Medicao N. " + CND->CND_NUMMED + " - Contrato " + CND->CND_CONTRA

	SA1->(dbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(dbSeek(xFilial("SA1") + CN9->CN9_CLIENT + CN9->CN9_LOJACL))

	oHTML := oProcess:oHTML
	oHTML:ValByName('TP_ITEM'    , "Itens da Medicao de Contrato")
	oHTML:ValByName('TIPO'       , "MEDICAO DE CONTRATO")
	oHTML:ValByName('CODIGO'     , SA1->A1_COD)
	oHTML:ValByName('TP_NOME'    , "Cliente/Contratado")
	oHTML:ValByName('NOME'       , SA1->A1_NOME)
	oHTML:ValByName('NUM_PED'    , CND->CND_NUMMED)
	oHTML:ValByName('EMISSAO'    , Date())
	oHTML:ValByName('COND'       , CN9->CN9_CONDPG)
	oHTML:ValByName('E4_DESCRI'  , Posicione("SE4", 1, xFilial("SE4") + CN9->CN9_CONDPG, "E4_DESCRI"))
	oHTML:ValByName('CGC'        , Transform(SA1->A1_CGC, PesqPict("SA1", "A1_CGC")))
	oHTML:ValByName('SOLICIT'    , UsrFullName(CN9->CN9_GESTC))
	oHTML:ValByName('REVISAO'    , CND->CND_REVISA)
	oHTML:ValByName('COMPETENCIA', CND->CND_COMPET)

	oHTML:ValByName('C7_FILIAL'  , CND->CND_FILIAL)
	oHTML:ValByName('C7_NUM'     , CND->CND_NUMMED)

	cAssunto := "MEDICAO DE CONTRATO N. " + CND->CND_NUMMED
	cNumMed  := CND->CND_NUMMED
	cChave   := AllTrim(CND->CND_FILIAL) + AllTrim(CND->CND_CONTRA) + CND->CND_REVISA + AllTrim(CND->CND_NUMMED)

	CNE->(dbSetOrder(1)) //CNE_FILIAL+CNE_CONTRA+CNE_REVISA+CNE_NUMERO+CNE_NUMMED+CNE_ITEM
	CNE->(dbSeek(xFilial("CNE") + CND->(CND_CONTRA + CND_REVISA)))
	While !CNE->(EoF()) .And. AllTrim(CNE->CNE_FILIAL) + AllTrim(CNE->CNE_CONTRA) + CNE->CNE_REVISA + AllTrim(CNE->CNE_NUMMED) == cChave

		AAdd((oHtml:ValByName('item.ITEM'))    , CNE->CNE_ITEM)
		AAdd((oHtml:ValByName('item.PROD'))    , AllTrim(CNE->CNE_PRODUT))
		AAdd((oHtml:ValByName('item.DESCRI'))  , EncodeUTF8(CNE->CNE_DESCRI))
		AAdd((oHtml:ValByName('item.QUANT'))   , Transform(CNE->CNE_QUANT, PesqPict("CNE", "CNE_QUANT")))
		AAdd((oHtml:ValByName('item.SALDO'))   , Transform(CNE->CNE_QTAMED, PesqPict("CNE", "CNE_QTAMED")))
		AAdd((oHtml:ValByName('item.UM'))      , "")
		AAdd((oHtml:ValByName('item.CONTA'))   , AllTrim(CNE->CNE_CONTA))
		AAdd((oHtml:ValByName('item.CC'))      , AllTrim(CNE->CNE_CC))
		AAdd((oHtml:ValByName('item.ITEMCTA')) , AllTrim(CNE->CNE_ITEMCT))
		AAdd((oHtml:ValByName('item.PRECO'))   , Transform(CNE->CNE_VLUNIT, PesqPict("CNE", "CNE_VLUNIT")))
		AAdd((oHtml:ValByName('item.TOTAL'))   , Transform(CNE->CNE_VLTOT, PesqPict("CNE", "CNE_VLTOT")))

		nVlrTotal += CNE->CNE_VLTOT
		CNE->(dbSkip())
	EndDo

	oHtml:ValByName("VLRTOT"     , Transform(nVlrTotal, PesqPict("CNE", "CNE_VLTOT")))
	oHtml:ValByName("OBSERVACAO" , cObs)

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	If SCR->(dbSeek(xFilial("SCR") + "MD" + cNumMed))
		While !SCR->(Eof()) .And. SCR->(CR_FILIAL + CR_TIPO + CR_NUM) == xFilial("SCR") + "MD" + cNumMed
			If AllTrim(SCR->CR_STATUS) == "02"
				cAprov := AllTrim(SCR->CR_USER)
				cTo    := UsrRetMail(SCR->CR_USER)
				oHTML:ValByName('RECNO' , SCR->(Recno()))
				oHTML:ValByName('GRUPO' , SCR->CR_GRUPO + " - " + GetAdvFVal("SAL", "AL_DESC", xFilial("SAL") + SCR->CR_GRUPO, 1, ""))
			EndIf

			AAdd((oHtml:ValByName('apv.NIVEL')) , SCR->CR_NIVEL)
			AAdd((oHtml:ValByName('apv.APROV')) , UsrFullName(SCR->CR_USER))

			If SCR->CR_STATUS == "01"
				cStatus := "Aguardando nivel anterior"
			ElseIf SCR->CR_STATUS == "02"
				cStatus := "Em Aprovacao"
			ElseIf SCR->CR_STATUS == "03"
				cStatus := "Aprovado"
			EndIf
			AAdd((oHtml:ValByName('apv.STATUS')) , cStatus)
			AAdd((oHtml:ValByName('apv.COMENT')) , SCR->CR_OBS)

			SCR->(dbSkip())
		EndDo
	EndIf

	oHTML:ValByName('USER'      , cAprov)
	oHTML:ValByName('APROVADOR', UsrFullName(cAprov))

	oProcess:cTo := "WFAPROVACAO"
	oProcess:UserSiga := __cUserID
	cMailId := oProcess:Start()

	cBody := "<b>Sr(a). " + AllTrim(UsrFullName(cAprov)) + "</b><br><br>"
	cBody += "Preparamos esse documento para sua aprovacao.<br>"
	cBody += "Clique no botao abaixo para abrir o documento.<br>"

	cFooter := "Atenciosamente, " + "<br>"
	cFooter += "Workflow Protheus | Servico de Mensagens" + "<br>"

	cHtmlModelo := "\workflow\modelos_workflow\wflink.htm"
	oProcess:NewTask(cAssunto, cHtmlModelo)
	oProcess:cSubject := cAssunto
	oProcess:cTo := AllTrim(cTo)

	oProcess:oHtml:ValByName("BODY"  , cBody)
	oProcess:oHtml:ValByName("FOOTER", cFooter)
	oProcess:oHtml:ValByName("WLink" , AllTrim(cURLWF) + "/messenger/" + AllTrim(cEmpWF) + "/wfaprovacao/" + cMailId + ".htm")
	oProcess:Start()

	SCR->(RestArea(aAreaSCR))
	SA1->(RestArea(aAreaSA1))
	CN9->(RestArea(aAreaCN9))
	CNE->(RestArea(aAreaCNE))
	CND->(RestArea(aAreaCND))
	RestArea(aArea)

Return

#include "totvs.ch"
#INCLUDE "TBICONN.CH"


/*/{Protheus.doc} CAWFCT01
Monta e dispara o e-mail de workflow de aprovacao de inclusao de Contrato
(rotina CNTA300), para o nivel de alcada pendente na tabela SCR
(CR_TIPO = "CT"). Espera a tabela CN9 posicionada no registro do contrato
a ser enviado para aprovacao.
@type function
@author Delson Junior Antunes
@since 06/07/2026
/*/
User Function CAWFCT01()

	Local aArea       := GetArea()
	//Local aAreaCN9    := CN9->(GetArea())
	//Local aAreaCNB    := CNB->(GetArea())
	//Local aAreaSA2    := SA2->(GetArea())
	//Local aAreaSCR    := SCR->(GetArea())
	Local cTo         := ""
	Local cNumCtr     := ""
	Local cChave      := ""
	Local cAprov      := ""
	Local cObs        := ""
	Local cStatus     := ""
	Local cAssunto    := ""
	Local cMailId     := ""
	Local cBody       := ""
	Local cFooter     := ""
	Local cHtmlModelo := ""
	Local cURLWF      := ''
	Local cEmpWF      := ''
	Local nVlrTotal   := 0
	Local oProcess
	Local oHTML

	if Select('SM0') == 0
		PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" USER 'admin' PASSWORD '1'
		dbselectarea('CN9')
		CN9->(dbSetOrder(1)) //CN9_FILIAL+CN9_NUMERO
		CN9->(dbSeek(xFilial("CN9") + '000000000000004'))

	endif


	cURLWF      := GetNewPar("ZZ_URLWF", "https://caoachery188151.protheus.cloudtotvs.com.br:11121")
	cEmpWF      := GetNewPar("ZZ_EMPWF", "emp01")
	//cURLWF      := GetNewPar("ZZ_URLWF", "http://localhost:81/wf")
	//cEmpWF      := GetNewPar("ZZ_EMPWF", "emp99")

	dbselectarea('CNA')
	dbselectarea('CNB')
	dbselectarea('SA2')
	dbselectarea('SCR')



	CNA->(dbSeek(xFilial("CNA") + CN9->CN9_NUMERO))


	oProcess := TWFProcess():New("WFCONTRATO", "Workflow de Aprovacao de Contrato")
	oProcess:NewTask("000005", "\WORKFLOW\WFCOMPRAS\WFAPROVACAO.HTM")
	oProcess:cSubject := "Workflow de Aprovacao de Contrato " + CN9->CN9_NUMERO
	oProcess:bReturn := "U_CAWFCT02()"
	oProcess:fDesc := "Contrato N. " + CN9->CN9_NUMERO

	SA2->(dbSetOrder(1)) //A2_FILIAL+A2_COD+A2_LOJA
	SA2->(dbSeek(xFilial("SA2") + CNA->CNA_FORNEC + CNA->CNA_LJFORN))

	oHTML := oProcess:oHTML
	oHTML:ValByName('TP_ITEM'    , "Itens da Planilha do Contrato")
	oHTML:ValByName('TIPO'       , "CONTRATO")
	oHTML:ValByName('CODIGO'     , SA2->A2_COD)
	oHTML:ValByName('TP_NOME'    , "Fornecedor/Contratado")
	oHTML:ValByName('NOME'       , SA2->A2_NOME)
	oHTML:ValByName('NUM_PED'    , CN9->CN9_NUMERO)
	oHTML:ValByName('EMISSAO'    , CN9->CN9_DTINIC)
	oHTML:ValByName('COND'       , CN9->CN9_CONDPG)
	oHTML:ValByName('E4_DESCRI'  , Posicione("SE4", 1, xFilial("SE4") + CN9->CN9_CONDPG, "E4_DESCRI"))
	oHTML:ValByName('CGC'        , Transform(SA2->A2_CGC, PesqPict("SA2", "A2_CGC")))
	oHTML:ValByName('SOLICIT'    , UsrFullName(CN9->CN9_GESTC))
	oHTML:ValByName('REVISAO'    , CN9->CN9_REVISA)
	oHTML:ValByName('COMPETENCIA', "")

	oHTML:ValByName('C7_FILIAL'  , CN9->CN9_FILIAL)
	oHTML:ValByName('C7_NUM'     , CN9->CN9_NUMERO)

	cAssunto := "CONTRATO N. " + CN9->CN9_NUMERO
	cNumCtr  := CN9->CN9_NUMERO
	cChave   := AllTrim(CN9->CN9_FILIAL) + AllTrim(CN9->CN9_NUMERO) + CN9->CN9_REVISA

	CNB->(dbSetOrder(1)) //CNB_FILIAL+CNB_CONTRA+CNB_REVISA+CNB_NUMERO+CNB_ITEM
	CNB->(dbSeek(xFilial("CNB") + CN9->(CN9_NUMERO + CN9_REVISA)))
	While !CNB->(EoF()) .And. AllTrim(CNB->CNB_FILIAL) + AllTrim(CNB->CNB_CONTRA) + CNB->CNB_REVISA == cChave

		AAdd((oHtml:ValByName('item.ITEM'))    , CNB->CNB_ITEM)
		AAdd((oHtml:ValByName('item.PROD'))    , AllTrim(CNB->CNB_PRODUT))
		AAdd((oHtml:ValByName('item.DESCRI'))  , EncodeUTF8(CNB->CNB_DESCRI))
		AAdd((oHtml:ValByName('item.QUANT'))   , Transform(CNB->CNB_QUANT, PesqPict("CNB", "CNB_QUANT")))
		AAdd((oHtml:ValByName('item.SALDO'))   , Transform(CNB->CNB_SLDMED, PesqPict("CNB", "CNB_SLDMED")))
		AAdd((oHtml:ValByName('item.UM'))      , CNB->CNB_UM)
		AAdd((oHtml:ValByName('item.CONTA'))   , "")
		AAdd((oHtml:ValByName('item.CC'))      , "")
		AAdd((oHtml:ValByName('item.ITEMCTA')) , "")
		AAdd((oHtml:ValByName('item.PRECO'))   , Transform(CNB->CNB_VLUNIT, PesqPict("CNB", "CNB_VLUNIT")))
		AAdd((oHtml:ValByName('item.TOTAL'))   , Transform(CNB->CNB_VLTOT, PesqPict("CNB", "CNB_VLTOT")))

		nVlrTotal += CNB->CNB_VLTOT
		CNB->(dbSkip())
	EndDo

	oHtml:ValByName("VLRTOT"     , Transform(nVlrTotal, PesqPict("CNB", "CNB_VLTOT")))
	oHtml:ValByName("OBSERVACAO" , cObs)

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	If SCR->(dbSeek(xFilial("SCR") + "CT" + cNumCtr))
		While !SCR->(Eof()) .And. alltrim(SCR->(CR_FILIAL + CR_TIPO + CR_NUM)) == alltrim(xFilial("SCR") + "CT" + cNumCtr)
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

	cHtmlModelo := "\WORKFLOW\WFCOMPRAS\wflink.htm"
	oProcess:NewTask(cAssunto, cHtmlModelo)
	oProcess:cSubject := cAssunto
	//oProcess:cTo := AllTrim(cTo)
	oProcess:cTo := 'delsonjrantunes@hotmail.com'

	oProcess:oHtml:ValByName("BODY"  , cBody)
	oProcess:oHtml:ValByName("FOOTER", cFooter)
	oProcess:oHtml:ValByName("WLink" , AllTrim(cURLWF) + "/messenger/" + AllTrim(cEmpWF) + "/wfaprovacao/" + cMailId + ".htm")
	oProcess:Start()

	//SCR->(RestArea(aAreaSCR))
	//SA2->(RestArea(aAreaSA2))
	//CNB->(RestArea(aAreaCNB))
	//CN9->(RestArea(aAreaCN9))
	//RestArea(aArea)

Return

#include "protheus.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDWFPC03  ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina de envio de workflow de aprovação de compras 		  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE  		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

user function EDWFPC03()

    Local aArea     := getArea()
    Local aAreaSC1  := SC1->(getArea())
    Local aAreaSA2  := SA2->(getArea())
    Local cTo       := ""
	Local cNumPed   := ""
	Local cAprov	:= ""
	//Local cMailApr  := ""
	Local cObs		:= ""
	Local cURLWF	:= getNewPar("ZZ_URLWF", "localhost:81/WF") //"200.232.119.74:9595/WF"
	Local cEmpWF	:= getNewPar("ZZ_EMPWF", "emp01") 
	Default cNivel 	:= "01"

	//cURLWF	:= "172.50.0.6:8010/WF"

	/*
    if SC1->C1_APROV <> "B"
        return
    endif
	*/

	//Função que da o Start no Workflow
	oProcess := TWFProcess():New("WFPEDCOM", "Workflow de Aprovação de Solicitacao de Compras")
	// //Função que busca o Modelo do HTML
	oProcess:NewTask("000003", "\WORKFLOW\modelos_workflow\WFAPROVACAO.HTM")
	// //Subject do Email
	oProcess:cSubject := "Workflow de Aprovação de Solicitacao de Compras " + SC1->C1_NUM

	oProcess:bReturn := "U_EDWFPC04()"

	oProcess:fDesc := "Solicitacao de Compra Nº " + SC1->C1_NUM

	SA2->(dbSetOrder(1)) //A2_FILIAL + A2_COD + A2_LOJA
	SA2->(dbSeek(xFilial("SA2") + SC1->C1_FORNECE + SC1->C1_LOJA))

	cSolicit := usrFullName(SC1->C1_USER)

	oHTML := oProcess:oHTML
	oHTML:ValByName('TP_ITEM'	, "Itens da Solicitacao de Compras")
	oHTML:ValByName('TIPO'		, "Solicitacao de Compras")
	oHTML:ValByName('CODIGO'	, SA2->A2_COD)
	oHTML:ValByName('TP_NOME'	, "Fornecedor")
	oHTML:ValByName('NOME'		, SA2->A2_NOME)
	oHTML:ValByName('NUM_PED'	, SC1->C1_NUM)
	oHTML:ValByName('EMISSAO'	, SC1->C1_EMISSAO)
	oHTML:ValByName('COND'		, SC1->C1_CONDPAG)
	oHTML:ValByName('E4_DESCRI'	, posicione("SE4", 1, xFilial("SE4") + SC1->C1_CONDPAG, "E4_DESCRI"))
	oHTML:ValByName('CGC'		, transform(SA2->A2_CGC, pesqPict("SA2", "A2_CGC")))


    oHTML:ValByName('C7_FILIAL'	, SC1->C1_FILIAL)
	oHTML:ValByName('C7_NUM'	, SC1->C1_NUM)
	oHTML:ValByName('SOLICIT'	, cSolicit)

	cAssunto := "Solicitacao de Compras Nº " + SC1->C1_NUM

	nVlrTotal	:= 0
	cNumPed		:= SC1->C1_NUM
	cChave		:= alltrim(SC1->C1_FILIAL) + alltrim(SC1->C1_NUM)
	
	SC1->(dbSetOrder(1))
	SC1->(dbSeek(cChave))
	while !SC1->(EoF()) .And. alltrim(SC1->C1_FILIAL) + alltrim(SC1->C1_NUM) == cChave
		cProduto	:= 	SC1->C1_PRODUTO

		aadd((oHtml:ValByName('item.ITEM'))	    , SC1->C1_ITEM)
		aadd((oHtml:ValByName('item.PROD'))	    , alltrim(SC1->C1_PRODUTO))
		aadd((oHtml:ValByName('item.DESCRI'))   , encodeUTF8(SC1->C1_DESCRI))
		aadd((oHtml:ValByName('item.QUANT'))	, transform(SC1->C1_QUANT, pesqPict("SC1", "C1_QUANT")))
		aadd((oHtml:ValByName('item.SALDO'))	, transform(SC1->(C1_QUANT-C1_QUJE), pesqPict("SC1", "C1_QUANT")))
		aadd((oHtml:ValByName('item.UM'))	    , SC1->C1_UM)
		aadd((oHtml:ValByName('item.CONTA'))		, alltrim(SC1->C1_CONTA) + " - " + alltrim(getAdvFVal("CT1", "CT1_DESC01", xFilial("CT1")+SC1->C1_CONTA, 1, "")))
		aadd((oHtml:ValByName('item.CC'))	    	, alltrim(getAdvFVal("CTT", "CTT_DESC01", xFilial("CTT")+SC1->C1_CC, 1, "")))
		aadd((oHtml:ValByName('item.ITEMCTA'))	, alltrim(getAdvFVal("CTD", "CTD_DESC01", xFilial("CT1")+SC1->C1_ITEMCTA, 1, "")))
		aadd((oHtml:ValByName('item.PRECO'))	, transform(SC1->C1_PRECO, PesqPict("SC1","C1_PRECO")))
		aadd((oHtml:ValByName('item.TOTAL'))	, transform(SC1->C1_TOTAL, PesqPict("SC1", "C1_TOTAL")))

		// Tratamento para o campo de observação
		if len(alltrim(SC1->C1_OBS)) > 0
			cObs += alltrim(SC1->C1_OBS) + "<br>"
		endif

		nVlrTotal += SC1->C1_TOTAL
		SC1->(dbSkip())
	end

	oHtml:ValByName("VLRTOT"	, transform(nVlrTotal, pesqPict("SC1", "C1_TOTAL")))
	oHtml:ValByName("OBSERVACAO", cObs)

	cTipo := AVKEY("SC","CR_TIPO")

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	if SCR->(dbSeek(xFilial("SCR") + cTipo + cNumPed))
		while !SCR->(eof()) .and. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == xFilial("SCR") + AVKEY(cTipo,"CR_TIPO") + AVKEY(cNumPed,"CR_NUM")//alltrim(SCR->CR_FILIAL) + alltrim(SCR->CR_NUM) == cChave
			if alltrim(SCR->CR_STATUS) == "02"
				cAprov := alltrim(SCR->CR_USER)
				cTo := usrRetMail(SCR->CR_USER)
				oHTML:ValByName('RECNO'	, SCR->(recno()))
				oHTML:ValByName('GRUPO'		, SCR->CR_GRUPO + " - " + getAdvFVal("SAL", "AL_DESC", xFilial("SAL")+SCR->CR_GRUPO, 1, ""))
			endif
			aadd((oHtml:ValByName('apv.NIVEL'))		, SCR->CR_NIVEL)
			aadd((oHtml:ValByName('apv.APROV'))		, usrFullName(SCR->CR_USER))
			if SCR->CR_STATUS == "01"
				cStatus := "Aguardando nivel anterior"
			elseif SCR->CR_STATUS=="02"
				cStatus := "Em Aprovacao"
			elseif SCR->CR_STATUS=="03"
				cStatus := "Aprovado"
			endif
			aadd((oHtml:ValByName('apv.STATUS'))	, cStatus)
			aadd((oHtml:ValByName('apv.COMENT'))	, SCR->CR_OBS)

			SCR->(dbSkip())
		end
	endif

	/*
	SC1->(dbSetOrder(1))
	SC1->(dbSeek(cChave))
	
	ZZU->(dbSetOrder(1)) 
	if ZZU->(dbSeek(xFilial("ZZU") + SC1->C1_USER))
		cAprov := alltrim(ZZU->ZZU_APROVA)
		cMailApr  := usrRetMail(ZZU->ZZU_APROVA)
		aadd((oHtml:ValByName('apv.NIVEL'))		, '01')
		aadd((oHtml:ValByName('apv.APROV'))		, usrFullName(ZZU->ZZU_APROVA))
		cStatus := "Em Aprovação"
		aadd((oHtml:ValByName('apv.STATUS'))	, cStatus)		
	endif
	*/

	oHTML:ValByName('USER'		, cAprov)
	oHTML:ValByName('APROVADOR'	, usrFullName(cAprov))
	//aadd((oHtml:ValByName('apv.COMENT'))	, '')
	
	oProcess:cTo := "WFAPROVACAO"
	// //Identifica ID do usuario
	oProcess:UserSiga := __cUserID
	cMailId := oProcess:Start()
	
	cBody := "<b>Sr(a). " + alltrim(usrFullName(cAprov)) + "</b><br><br>"
	cBody += "Preparamos esse documento para sua aprovação.<br>"
	cBody += "Clique no botão abaixo para abrir o documento.<br>"

	cFooter := "Atenciosamente, " + "<br>"
	cFooter += "Workflow Protheus | Servico de Mensagens" + "<br>"

	cHtmlModelo := "\workflow\modelos_workflow\wflink.htm"
	//cTo := "vleonardo@deltadecisao.com.br"
	oProcess:NewTask(cAssunto, cHtmlModelo)
	oProcess:cSubject := cAssunto
	oProcess:cTo := Alltrim(cTo)
	
	oProcess:oHtml:ValByName("BODY"	    , cBody)
	oProcess:oHtml:ValByName("FOOTER"	, cFooter)
	oProcess:oHtml:ValByName("WLink"	, "http://" + alltrim(cURLWF) + "/messenger/" + alltrim(cEMPWF) + "/wfaprovacao/" + cMailID + ".htm")
	oProcess:Start()

    restArea(aAreaSA2)
    restArea(aAreaSC1)
    restArea(aArea)

    conout("Fim EDWFPC03")

return
